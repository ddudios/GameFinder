//
//  SearchResultViewModel.swift
//  GameFinder
//
//  Created by Suji Jang on 10/9/25.
//

import Foundation
import RxSwift
import RxCocoa

final class SearchResultViewModel: RxViewModelProtocol {
    enum PlatformFilter: CaseIterable {
        case all
        case windows
        case macOS
        case linux
        case xbox
        case playStation
        case nintendo
        case iOS
        case android

        var title: String {
            switch self {
            case .all:
                return L10n.Search.filterAll
            case .windows:
                return L10n.Search.filterWindows
            case .macOS:
                return L10n.Search.filterMacOS
            case .linux:
                return L10n.Search.filterLinux
            case .xbox:
                return L10n.Search.filterXbox
            case .playStation:
                return L10n.Search.filterPlayStation
            case .nintendo:
                return L10n.Search.filterNintendo
            case .iOS:
                return L10n.Search.filterIOS
            case .android:
                return L10n.Search.filterAndroid
            }
        }

        var platformIds: String? {
            switch self {
            case .all:
                return nil
            case .windows:
                return "4"
            case .macOS:
                return "5"
            case .linux:
                return "6"
            case .xbox:
                return "186,1,14"
            case .playStation:
                return "187,18,16,15,27,19,17"
            case .nintendo:
                return "7,8,9,10,11,13"
            case .iOS:
                return "3"
            case .android:
                return "21"
            }
        }
    }

    struct Input {
        let viewWillAppear: PublishRelay<Void>
        let loadNextPage: PublishRelay<Void>
        let filterChanged: PublishRelay<PlatformFilter>
        let queryChanged: PublishRelay<String>
    }

    struct Output {
        let games: BehaviorRelay<[Game]>
        let errorAlertMessage: PublishSubject<String>
    }

    private let disposeBag = DisposeBag()
    private(set) var query: String
    private var currentPage = 1
    private var isLoading = false
    private var currentFilter: PlatformFilter = .all

    init(query: String) {
        self.query = query
    }

    func transform(input: Input) -> Output {
        let games = BehaviorRelay<[Game]>(value: [])
        let errorAlertMessage = PublishSubject<String>()

        let reloadTrigger = Observable.merge(
            input.viewWillAppear.map { [weak self] _ in self?.currentFilter ?? .all },
            input.filterChanged.asObservable(),
            input.queryChanged.map { [weak self] query in
                self?.query = query
                return self?.currentFilter ?? .all
            }
        )

        reloadTrigger
            .do(onNext: { [weak self] filter in
                self?.currentFilter = filter
                self?.currentPage = 1
                self?.isLoading = true
            })
            .flatMapLatest { [weak self] _ -> Observable<Result<GameListDTO, NetworkError>> in
                guard let self = self else {
                    return Observable.just(.failure(.noData))
                }
                return NetworkObservable.request(
                    router: RawgRouter.search(
                        query: self.query,
                        page: self.currentPage,
                        platformIds: self.currentFilter.platformIds
                    ),
                    as: GameListDTO.self
                ).asObservable()
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
                return NetworkObservable.request(
                    router: RawgRouter.search(
                        query: self.query,
                        page: self.currentPage,
                        platformIds: self.currentFilter.platformIds
                    ),
                    as: GameListDTO.self
                ).asObservable()
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
}
