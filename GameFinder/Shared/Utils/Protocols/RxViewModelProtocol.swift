//
//  RxViewModelProtocol.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import Foundation

protocol RxViewModelProtocol {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}
