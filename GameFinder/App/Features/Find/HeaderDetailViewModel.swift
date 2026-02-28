//
//  HeaderDetailViewModel.swift
//  GameFinder
//
//  Created by Suji Jang on 10/4/25.
//

import Foundation
import RxSwift
import RxCocoa

final class HeaderDetailViewModel: RxViewModelProtocol {
    struct Input {
        let viewWillAppear: PublishRelay<Void>
        let loadNextPage: PublishRelay<Void>
    }

    struct Output {
        let games: BehaviorRelay<[Game]>
        let errorAlertMessage: PublishSubject<String>
    }

    private let disposeBag = DisposeBag()
    let sectionType: FinderViewController.Section
    private var currentPage = 1
    private var isLoading = false

    var sectionTitle: String {
        return sectionType.headerTitle
    }

    init(sectionType: FinderViewController.Section) {
        self.sectionType = sectionType
    }

    func transform(input: Input) -> Output {
        let games = BehaviorRelay<[Game]>(value: [])
        let errorAlertMessage = PublishSubject<String>()

        // 초기 로드
        input.viewWillAppear
            .do(onNext: { [weak self] in
                self?.currentPage = 1
                self?.isLoading = true
            })
            .flatMap { [weak self] _ -> Observable<Result<GameListDTO, NetworkError>> in
                guard let self = self else {
                    return Observable.just(.failure(.noData))
                }
                return self.fetchGames(page: self.currentPage)
            }
            .subscribe(with: self) { owner, result in
                owner.isLoading = false
                switch result {
                case .success(let gameListDTO):
                    let gameList = gameListDTO.results.map { Game(from: $0) }
                    games.accept(gameList)
                case .failure(let networkError):
                    errorAlertMessage.onNext(networkError.errorDescription ?? "게임 로드 실패")
                }
            }
            .disposed(by: disposeBag)

        // 페이지네이션
        input.loadNextPage
            .filter { [weak self] in
                guard let self = self else { return false }
                return !self.isLoading
            }
            .do(onNext: { [weak self] in
                self?.currentPage += 1
                self?.isLoading = true
            })
            .flatMap { [weak self] _ -> Observable<Result<GameListDTO, NetworkError>> in
                guard let self = self else {
                    return Observable.just(.failure(.noData))
                }
                return self.fetchGames(page: self.currentPage)
            }
            .subscribe(with: self) { owner, result in
                owner.isLoading = false
                switch result {
                case .success(let gameListDTO):
                    let newGames = gameListDTO.results.map { Game(from: $0) }
                    let currentGames = games.value
                    games.accept(currentGames + newGames)
                case .failure(let networkError):
                    errorAlertMessage.onNext(networkError.errorDescription ?? "게임 로드 실패")
                }
            }
            .disposed(by: disposeBag)

        return Output(
            games: games,
            errorAlertMessage: errorAlertMessage
        )
    }

    private func fetchGames(page: Int) -> Observable<Result<GameListDTO, NetworkError>> {
        switch sectionType {
        case .popularGames:
            return NetworkObservable.request(
                router: RawgRouter.popular(page: page, pageSize: 20),
                as: GameListDTO.self
            ).asObservable()
        case .freeGames:
            return NetworkObservable.request(
                router: RawgRouter.freeToPlay(page: page, pageSize: 20),
                as: GameListDTO.self
            ).asObservable()
        case .upcomingGames:
            let today = Date()
            let futureDate = Calendar.current.date(byAdding: .month, value: 3, to: today)!
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            return NetworkObservable.request(
                router: RawgRouter.upcoming(
                    start: dateFormatter.string(from: today),
                    end: dateFormatter.string(from: futureDate),
                    page: page,
                    pageSize: 20
                ),
                as: GameListDTO.self
            ).asObservable()
        case .discountDeals:
            return Observable.just(.failure(.noData))
        }
    }
}
