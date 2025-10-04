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
        let errorAlertMessage: PublishSubject<String>
    }
    
    private let disposeBag = DisposeBag()
    
    func transform(input: Input) -> Output {
        
        // Hashable - 더이상 인덱스로 데이터를 판단하지 않고 모델 기반으로 데이터를 판단하기 때문에, 어느 한 부분이라도 데이터가 달라야 한다
            // diffable로 사용한다는 것은 인덱스 기준으로 데이터를 조회하지 않는 것을 의미한다
            // 그래서 만약에 diffable로 작성 중에 itemIdentifier 등을 사용하는 위치에서 list[indexPath.row] 등으로 접근한다면 애플이 만들어 놓은 기술의 대전제가 틀리는 것이라서 코드의 의도 여부를 떠나서 잘 모르고 사용하고 있구나

        let popularGames = BehaviorRelay<[Game]>(value: [])
        let freeGames = BehaviorRelay<[Game]>(value: [])
        let upcomingGames = BehaviorRelay<[Game]>(value: [])
        let errorAlertMessage = PublishSubject<String>()
        
        // MARK: - 인기 게임 로드
        input.viewWillAppear
            .flatMap { _ in
                NetworkObservable.request(
                    router: RawgRouter.popular(page: 1, pageSize: 10),
                    as: GameListDTO.self
                )
            }
            .subscribe(with: self) { owner, popularResult in
                
                switch popularResult {
                    
                case .success(let gameListDTO):
                    // DTO → Domain 변환
                    let games = gameListDTO.results.map { Game(from: $0) }
                    popularGames.accept(games)
                case .failure(let networkError):
                    errorAlertMessage.onNext(networkError.errorDescription ?? "인기 게임 로드 실패")
                }
            }
            .disposed(by: disposeBag)
        
        // MARK: - 무료 게임 로드
        input.viewWillAppear
            .flatMap { _ in
                NetworkObservable.request(
                    router: RawgRouter.freeToPlay(page: 1, pageSize: 15),
                    as: GameListDTO.self
                )
            }
            .subscribe(with: self) { owner, freeResult in
                
                switch freeResult {
                    
                case .success(let gameListDTO):
                    let games = gameListDTO.results.map { Game(from: $0) }
                    freeGames.accept(games)
                    
                case .failure(let networkError):
                    errorAlertMessage.onNext(networkError.errorDescription ?? "무료 게임 로드 실패")
                }
            }
            .disposed(by: disposeBag)
        
        // MARK: - 출시 예정 게임 로드
        input.viewWillAppear
            .flatMap { _ in
                let today = Date()
                let futureDate = Calendar.current.date(byAdding: .month, value: 3, to: today)!
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                return NetworkObservable.request(
                    router: RawgRouter.upcoming(
                        start: dateFormatter.string(from: today),
                        end: dateFormatter.string(from: futureDate),
                        page: 1,
                        pageSize: 10
                    ),
                    as: GameListDTO.self
                )
            }
            .subscribe(with: self) { owner, upcomingResult in
                
                switch upcomingResult {
                    
                case .success(let gameListDTO):
                    let games = gameListDTO.results.map { Game(from: $0) }
                    upcomingGames.accept(games)
                    
                case .failure(let networkError):
                    errorAlertMessage.onNext(networkError.errorDescription ?? "출시 예정 게임 로드 실패")
                    print("출시 예정 게임 로드 실패: \(networkError)")
                }
            }
            .disposed(by: disposeBag)
        
        return Output(
            popularGames: popularGames,
            freeGames: freeGames,
            upcomingGames: upcomingGames,
            errorAlertMessage: errorAlertMessage
        )
    }
}
