//
//  FinderViewModel.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import Foundation
import RxSwift
import RxCocoa

final class FinderViewModel: RxViewModelProtocol {
    struct Input {
        let viewWillAppear: PublishRelay<Void>
    }
    
    struct Output {
        let popularGames: BehaviorRelay<[Game]>
        let freeGames: BehaviorRelay<[Game]>
        let upcomingGames: BehaviorRelay<[Game]>
        let discountDeals: BehaviorRelay<[DiscountDeal]>
        let errorAlertMessage: PublishSubject<String>
    }

    private let disposeBag = DisposeBag()
    private let cacheRepository: FinderCacheRepository
    private let calendar: Calendar
    private let dateFormatter: DateFormatter
    private let discountPageSize: Int
    private var storeNamesByID: [String: String] = [:]
    private var hasFetchedStoreNames = false
    private var isLoadingStoreNames = false

    init(
        cacheRepository: FinderCacheRepository = RealmFinderCacheRepository(),
        calendar: Calendar = .current,
        discountPageSize: Int = 12
    ) {
        self.cacheRepository = cacheRepository
        self.calendar = calendar
        self.discountPageSize = discountPageSize

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateFormatter = formatter
    }

    func transform(input: Input) -> Output {

        let popularGames = BehaviorRelay<[Game]>(value: [])
        let freeGames = BehaviorRelay<[Game]>(value: [])
        let upcomingGames = BehaviorRelay<[Game]>(value: [])
        let discountDeals = BehaviorRelay<[DiscountDeal]>(value: [])
        let errorAlertMessage = PublishSubject<String>()

        input.viewWillAppear
            .subscribe(with: self) { owner, _ in
                owner.loadPopularGames(into: popularGames, errorAlertMessage: errorAlertMessage)
                owner.loadFreeGames(into: freeGames, errorAlertMessage: errorAlertMessage)
                owner.loadUpcomingGames(into: upcomingGames, errorAlertMessage: errorAlertMessage)
                owner.loadDiscountDeals(into: discountDeals, errorAlertMessage: errorAlertMessage)
            }
            .disposed(by: disposeBag)

        return Output(
            popularGames: popularGames,
            freeGames: freeGames,
            upcomingGames: upcomingGames,
            discountDeals: discountDeals,
            errorAlertMessage: errorAlertMessage
        )
    }

    private func loadPopularGames(
        into relay: BehaviorRelay<[Game]>,
        errorAlertMessage: PublishSubject<String>
    ) {
        loadSection(
            section: .popularGames,
            failureMessage: "인기 게임 로드 실패",
            relay: relay,
            errorAlertMessage: errorAlertMessage,
            router: { RawgRouter.popular(page: 1, pageSize: FinderCacheSection.popularGames.maxItemCount) }
        )
    }

    private func loadFreeGames(
        into relay: BehaviorRelay<[Game]>,
        errorAlertMessage: PublishSubject<String>
    ) {
        loadSection(
            section: .freeGames,
            failureMessage: "무료 게임 로드 실패",
            relay: relay,
            errorAlertMessage: errorAlertMessage,
            router: { RawgRouter.freeToPlay(page: 1, pageSize: FinderCacheSection.freeGames.maxItemCount) }
        )
    }

    private func loadUpcomingGames(
        into relay: BehaviorRelay<[Game]>,
        errorAlertMessage: PublishSubject<String>
    ) {
        loadSection(
            section: .upcomingGames,
            failureMessage: "출시 예정 게임 로드 실패",
            relay: relay,
            errorAlertMessage: errorAlertMessage,
            shouldForceRefresh: shouldForceRefreshUpcoming(cachedGames:),
            router: makeUpcomingRouter
        )
    }

    private func loadDiscountDeals(
        into relay: BehaviorRelay<[DiscountDeal]>,
        errorAlertMessage: PublishSubject<String>
    ) {
        if !hasFetchedStoreNames {
            fetchStoreNamesIfNeeded(into: relay, errorAlertMessage: errorAlertMessage)
            return
        }

        NetworkObservable.request(
            router: CheapSharkRouter.deals(
                pageNumber: 0,
                pageSize: discountPageSize,
                descending: false,
                onSaleOnly: true
            ),
            as: [CheapSharkDealDTO].self
        )
        .subscribe(with: self) { owner, result in
            switch result {
            case .success(let dealDTOs):
                let deals = dealDTOs
                    .compactMap { DiscountDeal(from: $0, storeName: owner.storeNamesByID[$0.storeID]) }
                    .filter(\.isDiscounted)
                    .sorted { $0.effectiveSavingsPercent > $1.effectiveSavingsPercent }
                relay.accept(deals)
            case .failure(let networkError):
                errorAlertMessage.onNext(networkError.errorDescription ?? "할인 게임팩 로드 실패")
            }
        }
        .disposed(by: disposeBag)
    }

    private func fetchStoreNamesIfNeeded(
        into relay: BehaviorRelay<[DiscountDeal]>,
        errorAlertMessage: PublishSubject<String>
    ) {
        guard !isLoadingStoreNames else { return }
        isLoadingStoreNames = true

        NetworkObservable.request(
            router: CheapSharkRouter.stores,
            as: [CheapSharkStoreDTO].self
        )
        .subscribe(with: self) { owner, result in
            owner.isLoadingStoreNames = false
            owner.hasFetchedStoreNames = true

            switch result {
            case .success(let storeDTOs):
                owner.storeNamesByID = storeDTOs.reduce(into: [String: String]()) { partialResult, store in
                    guard !store.storeID.isEmpty else { return }
                    partialResult[store.storeID] = store.storeName
                }
            case .failure:
                owner.storeNamesByID = [:]
            }

            owner.loadDiscountDeals(into: relay, errorAlertMessage: errorAlertMessage)
        }
        .disposed(by: disposeBag)
    }

    private func loadSection(
        section: FinderCacheSection,
        failureMessage: String,
        relay: BehaviorRelay<[Game]>,
        errorAlertMessage: PublishSubject<String>,
        shouldForceRefresh: (([Game]) -> Bool)? = nil,
        router: @escaping () -> RawgRouter
    ) {
        let now = Date()
        let cachedGames = cacheRepository.load(section: section)
        let hasCachedGames = !cachedGames.isEmpty

        if hasCachedGames {
            relay.accept(cachedGames)
        }

        let isFresh = hasCachedGames && cacheRepository.isFresh(section: section, now: now)
        let forceRefresh = hasCachedGames && (shouldForceRefresh?(cachedGames) ?? false)
        let shouldFetch = !hasCachedGames || !isFresh || forceRefresh

        guard shouldFetch else { return }

        NetworkObservable.request(
            router: router(),
            as: GameListDTO.self
        )
        .subscribe(with: self) { owner, result in
            switch result {
            case .success(let gameListDTO):
                let games = Array(gameListDTO.results.map { Game(from: $0) }.prefix(section.maxItemCount))
                owner.cacheRepository.save(section: section, games: games, fetchedAt: Date())
                relay.accept(games)
            case .failure(let networkError):
                if !hasCachedGames {
                    errorAlertMessage.onNext(networkError.errorDescription ?? failureMessage)
                } else {
                    LogManager.network.warning("Using cached finder data for \(section.rawValue). Fetch error: \(networkError.localizedDescription)")
                }
            }
        }
        .disposed(by: disposeBag)
    }

    private func makeUpcomingRouter() -> RawgRouter {
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let futureDate = calendar.date(byAdding: .month, value: 3, to: today) ?? today

        return RawgRouter.upcoming(
            start: dateFormatter.string(from: tomorrow),
            end: dateFormatter.string(from: futureDate),
            page: 1,
            pageSize: FinderCacheSection.upcomingGames.maxItemCount
        )
    }

    private func shouldForceRefreshUpcoming(cachedGames: [Game]) -> Bool {
        guard let firstReleased = cachedGames.first?.released else {
            return false
        }

        guard let releaseDate = dateFormatter.date(from: firstReleased) else {
            // 출시일 파싱 실패 시 안전하게 재호출
            return true
        }

        let todayStart = calendar.startOfDay(for: Date())
        let releaseDayStart = calendar.startOfDay(for: releaseDate)
        return releaseDayStart <= todayStart
    }
}
