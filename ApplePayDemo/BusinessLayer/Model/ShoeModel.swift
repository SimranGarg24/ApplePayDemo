//
//  ShoeModel.swift
//  ApplePayDemo
//
//  Created by Saheem Hussain on 05/09/23.
//

import Foundation

struct ShoeModel {
    var name: String
    var price: Double
}

extension ShoeModel {
    
    static let shoeData = [
        ShoeModel(name: "Nike Air Force 1 High LV8", price: 110.00),
        ShoeModel(name: "adidas Ultra Boost Clima", price: 139.99),
        ShoeModel(name: "Jordan Retro 10", price: 190.00),
        ShoeModel(name: "adidas Originals Prophere", price: 49.99),
        ShoeModel(name: "New Balance 574 Classic", price: 90.00)
    ]
}
