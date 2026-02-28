//
//  DiscountDealsViewModel.swift
//  GameFinder
//
//  Created by Codex on 2/28/26.
//

import Foundation
import RxSwift
import RxCocoa

final class DiscountDealsViewModel: RxViewModelProtocol {
    struct Input {
        let viewWillAppear: PublishRelay<Void>
        let loadNextPage: PublishRelay<Void>
    }

    struct Output {
        let deals: BehaviorRelay<[DiscountDeal]>
        let errorAlertMessage: PublishSubject<String>
    }

    private let disposeBag = DisposeBag()
    private var currentPage = -1
    private var isLoading = false
    private var hasReachedEnd = false

    private let pageSize: Int

    init(pageSize: Int = 30) {
        self.pageSize = pageSize
    }

    func transform(input: Input) -> Output {
        let deals = BehaviorRelay<[DiscountDeal]>(value: [])
        let errorAlertMessage = PublishSubject<String>()

        input.viewWillAppear
            .subscribe(with: self) { owner, _ in
                owner.currentPage = -1
                owner.hasReachedEnd = false
                owner.fetchNextPage(into: deals, errorAlertMessage: errorAlertMessage)
            }
            .disposed(by: disposeBag)

        input.loadNextPage
            .subscribe(with: self) { owner, _ in
                owner.fetchNextPage(into: deals, errorAlertMessage: errorAlertMessage)
            }
            .disposed(by: disposeBag)

        return Output(
            deals: deals,
            errorAlertMessage: errorAlertMessage
        )
    }

    private func fetchNextPage(
        into relay: BehaviorRelay<[DiscountDeal]>,
        errorAlertMessage: PublishSubject<String>
    ) {
        guard !isLoading, !hasReachedEnd else { return }

        isLoading = true
        let requestPage = currentPage + 1

        NetworkObservable.request(
            router: CheapSharkRouter.deals(pageNumber: requestPage, pageSize: pageSize),
            as: [CheapSharkDealDTO].self
        )
        .subscribe(with: self) { owner, result in
            owner.isLoading = false

            switch result {
            case .success(let dealDTOs):
                let newDeals = dealDTOs.compactMap(DiscountDeal.init(from:))

                if newDeals.isEmpty {
                    if requestPage == 0 {
                        relay.accept([])
                    }
                    owner.hasReachedEnd = true
                    return
                }

                owner.currentPage = requestPage

                let mergedDeals = owner.mergeWithoutDuplicates(current: relay.value, incoming: newDeals)
                relay.accept(mergedDeals)

            case .failure(let networkError):
                errorAlertMessage.onNext(networkError.errorDescription ?? "할인 게임팩 로드 실패")
            }
        }
        .disposed(by: disposeBag)
    }

    private func mergeWithoutDuplicates(current: [DiscountDeal], incoming: [DiscountDeal]) -> [DiscountDeal] {
        var seen = Set(current.map(\.dealID))
        var merged = current

        for deal in incoming where !seen.contains(deal.dealID) {
            merged.append(deal)
            seen.insert(deal.dealID)
        }

        return merged
    }
}
