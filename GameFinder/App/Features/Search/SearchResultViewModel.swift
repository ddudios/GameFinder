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
        case steam
        case mobile
        case nintendo
        case playStation
        case pc

        var title: String {
            switch self {
            case .all:
                return "전체"
            case .steam:
                return "Steam"
            case .mobile:
                return "Mobile"
            case .nintendo:
                return "Nintendo"
            case .playStation:
                return "PlayStation"
            case .pc:
                return "PC"
            }
        }

        var platformIds: String? {
            switch self {
            case .all:
                return nil
            case .steam, .pc:
                return "4"
            case .mobile:
                return "21,3"
            case .nintendo:
                return "7,8,9"
            case .playStation:
                return "187,18,16"
            }
        }
    }

    struct Input {
        let viewWillAppear: PublishRelay<Void>
        let loadNextPage: PublishRelay<Void>
        let filterChanged: PublishRelay<PlatformFilter>
    }

    struct Output {
        let games: BehaviorRelay<[Game]>
        let errorAlertMessage: PublishSubject<String>
    }

    private let disposeBag = DisposeBag()
    let query: String
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
            input.filterChanged.asObservable()
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
