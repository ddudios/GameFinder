//
//  DiscountDeal.swift
//  GameFinder
//
//  Created by Codex on 2/28/26.
//

import Foundation

struct DiscountDeal: Hashable {
    let dealID: String
    let storeID: String
    let title: String
    let salePrice: Double
    let normalPrice: Double
    let savingsPercent: Double
    let thumbURL: String?

    var redirectURL: URL? {
        URL(string: "https://www.cheapshark.com/redirect?dealID=\(dealID)")
    }

    var hasValidPrice: Bool {
        salePrice > 0 || normalPrice > 0
    }

    init?(from dto: CheapSharkDealDTO) {
        guard !dto.dealID.isEmpty, !dto.title.isEmpty else {
            return nil
        }

        self.dealID = dto.dealID
        self.storeID = dto.storeID
        self.title = dto.title
        self.salePrice = Double(dto.salePrice) ?? 0
        self.normalPrice = Double(dto.normalPrice) ?? 0
        self.savingsPercent = Double(dto.savings) ?? 0
        self.thumbURL = dto.thumb
    }
}
