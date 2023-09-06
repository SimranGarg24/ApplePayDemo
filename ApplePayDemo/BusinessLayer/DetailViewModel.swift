//
//  DetailViewModel.swift
//  ApplePayDemo
//
//  Created by Saheem Hussain on 05/09/23.
//

import Foundation
import PassKit

class DetailViewModel {
    
    var name = String()
    var price = Double()
    let paymentHandler = PaymentHandler.shared
    
    func applePayStatus() -> (canMakePayments: Bool, canSetupCards: Bool) {
        return paymentHandler.applePayStatus()
    }
    
    func startPayment() {
        
        let taxValue = calculateTax()
        let summaryItems = [
            SummaryItem(label: name, amount: price),
            SummaryItem(label: "Tax", amount: taxValue.rounded()),
            SummaryItem(label: "Total", amount: (price + taxValue).rounded())
        ]
        
        let shippingMethods = [
            ShippingDetails(label: "Delivery", amount: 1.00, detail: "Shoes sent to you address", identifier: "DELIVERY", startAfterDays: 3, endAfterDays: 5)
        ]
        
        paymentHandler.addCoupons([Coupon(code: "FESTIVAL", amount: 50)])
        
        paymentHandler.startPayment(
            paymentSummaryItems: summaryItems,
            merchantID: "merchant.com.chicmic.test",
            countryCode: .IN,
            shippingMethods: shippingMethods,
            supportsCoupon: true) { (_, token) in
            if let token {
                print(token)
            }
        }
    }
    
    func calculateTax() -> Double {
        return (5 * price)/100
    }
}
