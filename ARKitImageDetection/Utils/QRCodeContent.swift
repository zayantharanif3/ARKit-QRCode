//
//  QRCodeContent.swift
//  ARKitImageDetection
//
//  Created by Zayan Tharani on 8/18/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import Foundation

enum QRCodeType: String {
    case base = "Base"
    case movable = "Movable"
}

struct QRCodeContent {
    var type: Int = 0
    var width: Float?
}
