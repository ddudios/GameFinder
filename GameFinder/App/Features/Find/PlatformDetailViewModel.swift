//
//  PlatformDetailViewModel.swift
//  GameFinder
//
//  Created by Claude on 10/9/25.
//

import Foundation
import RxSwift
import RxCocoa

final class PlatformDetailViewModel: RxViewModelProtocol {
    struct Input {
        let viewWillAppear: PublishRelay<Void>
        let loadNextPage: PublishRelay<Void>
    }

    struct Output {
        let games: BehaviorRelay<[Game]>
        let errorAlertMessage: PublishSubject<String>
    }

    private let disposeBag = DisposeBag()
    let platformName: String
    private var currentPage = 1
    private var isLoading = false

    init(platformName: String) {
        self.platformName = platformName
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
                return NetworkObservable.request(
                    router: RawgRouter.platform(platformName: self.platformName, page: self.currentPage, pageSize: 20),
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
                    router: RawgRouter.platform(platformName: self.platformName, page: self.currentPage, pageSize: 20),
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
