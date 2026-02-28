//
//  CheapSharkDealDTO.swift
//  GameFinder
//
//  Created by Codex on 2/28/26.
//

import Foundation

struct CheapSharkDealDTO: Decodable {
    let dealID: String
    let storeID: String
    let title: String
    let salePrice: String
    let normalPrice: String
    let savings: String
    let thumb: String?
}
