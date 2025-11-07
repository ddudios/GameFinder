//
//  DeviceModel.swift
//  GameFinder
//
//  Created by Suji Jang on 11/7/25.
//

import UIKit

// MARK: - Device Model Enum
enum DeviceModel: String {
    case simulator = "Simulator"

    // iPhone
    case iPhoneSE1 = "iPhone SE (1st generation)"
    case iPhoneSE2 = "iPhone SE (2nd generation)"
    case iPhoneSE3 = "iPhone SE (3rd generation)"

    case iPhone6 = "iPhone 6"
    case iPhone6Plus = "iPhone 6 Plus"
    case iPhone6S = "iPhone 6S"
    case iPhone6SPlus = "iPhone 6S Plus"
    case iPhone7 = "iPhone 7"
    case iPhone7Plus = "iPhone 7 Plus"
    case iPhone8 = "iPhone 8"
    case iPhone8Plus = "iPhone 8 Plus"
    case iPhoneX = "iPhone X"
    case iPhoneXR = "iPhone XR"
    case iPhoneXS = "iPhone XS"
    case iPhoneXSMax = "iPhone XS Max"
    case iPhone11 = "iPhone 11"
    case iPhone11Pro = "iPhone 11 Pro"
    case iPhone11ProMax = "iPhone 11 Pro Max"
    case iPhone12Mini = "iPhone 12 Mini"
    case iPhone12 = "iPhone 12"
    case iPhone12Pro = "iPhone 12 Pro"
    case iPhone12ProMax = "iPhone 12 Pro Max"
    case iPhone13Mini = "iPhone 13 Mini"
    case iPhone13 = "iPhone 13"
    case iPhone13Pro = "iPhone 13 Pro"
    case iPhone13ProMax = "iPhone 13 Pro Max"
    case iPhone14 = "iPhone 14"
    case iPhone14Plus = "iPhone 14 Plus"
    case iPhone14Pro = "iPhone 14 Pro"
    case iPhone14ProMax = "iPhone 14 Pro Max"
    case iPhone15 = "iPhone 15"
    case iPhone15Plus = "iPhone 15 Plus"
    case iPhone15Pro = "iPhone 15 Pro"
    case iPhone15ProMax = "iPhone 15 Pro Max"
    case iPhone16 = "iPhone 16"
    case iPhone16Plus = "iPhone 16 Plus"
    case iPhone16Pro = "iPhone 16 Pro"
    case iPhone16ProMax = "iPhone 16 Pro Max"

    // iPad (대표적인 최신 위주)
    case iPad = "iPad"
    case iPadAir = "iPad Air"
    case iPadPro11 = "iPad Pro 11-inch"
    case iPadPro12_9 = "iPad Pro 12.9-inch"

    // Apple Silicon Mac (iOS 앱 실행 시)
    case mac = "Mac (Apple Silicon)"

    // Fallback
    case unknown = "Unknown Device"
}


// MARK: - Identifier Mapping Dictionary
let deviceIdentifierMap: [String: DeviceModel] = [

    // SIMULATOR
    "i386": .simulator,
    "x86_64": .simulator,
    "arm64": .simulator,     // Apple Silicon Simulator

    // iPhone 6~8 + X
    "iPhone7,2": .iPhone6,
    "iPhone7,1": .iPhone6Plus,
    "iPhone8,1": .iPhone6S,
    "iPhone8,2": .iPhone6SPlus,
    "iPhone9,1": .iPhone7,
    "iPhone9,2": .iPhone7Plus,
    "iPhone10,1": .iPhone8,
    "iPhone10,2": .iPhone8Plus,
    "iPhone10,3": .iPhoneX,
    "iPhone11,8": .iPhoneXR,
    "iPhone11,2": .iPhoneXS,
    "iPhone11,6": .iPhoneXSMax,

    // iPhone 11
    "iPhone12,1": .iPhone11,
    "iPhone12,3": .iPhone11Pro,
    "iPhone12,5": .iPhone11ProMax,

    // iPhone 12
    "iPhone13,1": .iPhone12Mini,
    "iPhone13,2": .iPhone12,
    "iPhone13,3": .iPhone12Pro,
    "iPhone13,4": .iPhone12ProMax,

    // iPhone 13
    "iPhone14,4": .iPhone13Mini,
    "iPhone14,5": .iPhone13,
    "iPhone14,2": .iPhone13Pro,
    "iPhone14,3": .iPhone13ProMax,

    // iPhone 14
    "iPhone14,7": .iPhone14,
    "iPhone14,8": .iPhone14Plus,
    "iPhone15,2": .iPhone14Pro,
    "iPhone15,3": .iPhone14ProMax,

    // iPhone 15
    "iPhone15,4": .iPhone15,
    "iPhone15,5": .iPhone15Plus,
    "iPhone16,1": .iPhone15Pro,
    "iPhone16,2": .iPhone15ProMax,

    // iPhone 16 (2024)
    "iPhone17,1": .iPhone16,
    "iPhone17,2": .iPhone16Plus,
    "iPhone17,3": .iPhone16Pro,
    "iPhone17,4": .iPhone16ProMax,

    // iPad (대표)
    "iPad7,11": .iPad,
    "iPad11,3": .iPadAir,
    "iPad8,1": .iPadPro11,
    "iPad8,5": .iPadPro12_9,

    // Mac (Apple Silicon)
    "MacBookAir10,1": .mac,
    "MacBookPro17,1": .mac
]



// MARK: - Device Model Resolver
func getDeviceModelName() -> String {

    var systemInfo = utsname()
    uname(&systemInfo)
    let mirror = Mirror(reflecting: systemInfo.machine)

    let identifier = mirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }

    // Simulator -> 실제 실행 기종 찾기 (optional)
    if identifier == "i386" || identifier == "x86_64" || identifier == "arm64" {
        if let simModel = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return deviceIdentifierMap[simModel]?.rawValue ?? "Simulator (\(simModel))"
        }
        return DeviceModel.simulator.rawValue
    }

    // 실제 기종 매핑
    return deviceIdentifierMap[identifier]?.rawValue ?? "Unknown Device (\(identifier))"
}
