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
    let storeName: String?
    let title: String
    let salePrice: Double
    let normalPrice: Double
    let savingsPercent: Double
    let thumbURL: String?

    private static let discountEpsilon: Double = 0.0001

    var redirectURL: URL? {
        URL(string: "https://www.cheapshark.com/redirect?dealID=\(dealID)")
    }

    var displayStoreName: String {
        storeName ?? "Store \(storeID)"
    }

    var hasValidPrice: Bool {
        normalPrice > 0 && salePrice >= 0
    }

    var calculatedSavingsPercent: Double {
        guard hasValidPrice else { return 0 }
        let percent = ((normalPrice - salePrice) / normalPrice) * 100
        return max(0, percent)
    }

    var effectiveSavingsPercent: Double {
        max(calculatedSavingsPercent, savingsPercent)
    }

    var isDiscounted: Bool {
        hasValidPrice && (normalPrice - salePrice) > Self.discountEpsilon
    }

    var displaySavingsPercent: Int {
        guard isDiscounted else { return 0 }
        return max(1, Int(effectiveSavingsPercent.rounded()))
    }

    init?(from dto: CheapSharkDealDTO, storeName: String? = nil) {
        guard !dto.dealID.isEmpty, !dto.title.isEmpty else {
            return nil
        }

        self.dealID = dto.dealID
        self.storeID = dto.storeID
        self.storeName = storeName
        self.title = dto.title
        self.salePrice = Double(dto.salePrice) ?? 0
        self.normalPrice = Double(dto.normalPrice) ?? 0
        self.savingsPercent = max(0, Double(dto.savings) ?? 0)
        self.thumbURL = dto.thumb
    }
}
