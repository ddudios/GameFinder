//
//  GameDetailViewModel.swift
//  GameFinder
//
//  Created by Suji Jang on 10/5/25.
//

import Foundation
import RxSwift
import RxCocoa

final class GameDetailViewModel: RxViewModelProtocol {

    struct Input {
        let viewWillAppear: PublishRelay<Void>
    }

    struct Output {
        let gameDetail: BehaviorRelay<GameDetail?>
        let screenshots: BehaviorRelay<[Screenshot]>
        let errorAlertMessage: PublishSubject<String>
    }

    private let gameId: Int
    private let disposeBag = DisposeBag()

    init(gameId: Int) {
        self.gameId = gameId
    }

    func transform(input: Input) -> Output {
        let gameDetail = BehaviorRelay<GameDetail?>(value: nil)
        let screenshots = BehaviorRelay<[Screenshot]>(value: [])
        let errorAlertMessage = PublishSubject<String>()

        input.viewWillAppear
            .flatMap { [weak self] _ -> Observable<Result<GameDetailDTO, NetworkError>> in
                guard let self = self else { return Observable.just(.failure(.noData)) }
                return NetworkObservable.request(
                    router: RawgRouter.game(id: String(self.gameId)),
                    as: GameDetailDTO.self
                ).asObservable()
            }
            .subscribe { result in
                switch result {
                case .success(let dto):
                    let detail = GameDetail(from: dto)
                    gameDetail.accept(detail)

                    // 게임 조회 로깅 및 Analytics
                    LogManager.logGameView(gameId: dto.id, gameName: dto.name)

                case .failure(let error):
                    LogManager.error.error("Failed to load game detail: \(self.gameId) - \(error.errorDescription ?? "unknown")")
                    errorAlertMessage.onNext(error.errorDescription ?? "알 수 없는 오류가 발생했습니다")
                }
            } onError: { error in
                LogManager.error.error("Game detail API error: \(error.localizedDescription)")
                errorAlertMessage.onNext(error.localizedDescription)
            }
            .disposed(by: disposeBag)

        // 스크린샷 API 호출
        input.viewWillAppear
            .flatMap { [weak self] _ -> Observable<Result<ScreenshotsDTO, NetworkError>> in
                guard let self = self else { return Observable.just(.failure(.noData)) }
                return NetworkObservable.request(
                    router: RawgRouter.screenshots(id: String(self.gameId)),
                    as: ScreenshotsDTO.self
                ).asObservable()
            }
            .subscribe { result in
                switch result {
                case .success(let dto):
                    screenshots.accept(dto.results)
                    LogManager.network.debug("Loaded \(dto.results.count) screenshots for game: \(self.gameId)")
                case .failure:
                    break // 스크린샷은 선택사항이므로 에러 무시
                }
            }
            .disposed(by: disposeBag)

        return Output(
            gameDetail: gameDetail,
            screenshots: screenshots,
            errorAlertMessage: errorAlertMessage
        )
    }
}
