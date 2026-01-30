//
//  CalendarViewModel.swift
//  GameFinder
//
//  Created by Suji Jang on 1/27/26.
//

import Foundation
import RxSwift
import RxCocoa

final class CalendarViewModel: RxViewModelProtocol {
    struct Input {
        let dateSelected: PublishRelay<Date>
    }

    struct Output {
        let games: BehaviorRelay<[Game]>
        let errorAlertMessage: PublishSubject<String>
        let isLoading: BehaviorRelay<Bool>
    }

    private let disposeBag = DisposeBag()

    func transform(input: Input) -> Output {
        let games = BehaviorRelay<[Game]>(value: [])
        let errorAlertMessage = PublishSubject<String>()
        let isLoading = BehaviorRelay<Bool>(value: false)

        // 날짜 선택 시 해당 날짜의 게임 로드
        input.dateSelected
            .do(onNext: { _ in
                isLoading.accept(true)
            })
            .flatMap { selectedDate -> Observable<Result<GameListDTO, NetworkError>> in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: selectedDate)

                // 해당 날짜에 출시되는 게임만 조회 (start == end)
                return NetworkObservable.request(
                    router: RawgRouter.upcoming(
                        start: dateString,
                        end: dateString,
                        page: 1,
                        pageSize: 20
                    ),
                    as: GameListDTO.self
                ).asObservable()
            }
            .subscribe(with: self) { owner, result in
                isLoading.accept(false)

                switch result {
                case .success(let gameListDTO):
                    let gamesList = gameListDTO.results.map { Game(from: $0) }
                    games.accept(gamesList)

                case .failure(let networkError):
                    errorAlertMessage.onNext(networkError.errorDescription ?? "게임 로드 실패")
                    games.accept([]) // 에러 시 빈 배열
                }
            }
            .disposed(by: disposeBag)

        return Output(
            games: games,
            errorAlertMessage: errorAlertMessage,
            isLoading: isLoading
        )
    }
}
