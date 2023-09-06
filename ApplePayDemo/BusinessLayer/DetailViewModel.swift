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
        
        paymentHandler.addCoupons([Coupon(code: "FESTIVAL", amount: 50)])
        
        paymentHandler.startPayment(
            paymentSummaryItems: summaryItems,
            merchantID: "merchant.com.chicmic.test",
            countryCode: .IN,
            shippingMethods: shippingMethodCalculator(),
            supportsCoupon: true) { (_, token) in
            if let token {
                print(token)
            }
        }
    }
    
    func calculateTax() -> Double {
        return (5 * price)/100
    }
    
    /// The app defines two shipping methods: delivery with estimated shipping dates and on-site collection.
    /// The payment sheet displays the delivery information for the chosen shipping method, including estimated delivery dates
    /// - Returns: shipping methods of type [PKShippingMethod
    func shippingMethodCalculator() -> [PKShippingMethod] {
        
        // Calculate pickup date.
        
        let today = Date()
        let calendar = Calendar.current
        
        let shippingStart = calendar.date(byAdding: .day, value: 3, to: today)!
        let shippingEnd = calendar.date(byAdding: .day, value: 5, to: today)!
        
        let startComponents = calendar.dateComponents([.calendar, .year, .month, .day], from: shippingStart)
        let endComponents = calendar.dateComponents([.calendar, .year, .month, .day], from: shippingEnd)
        
        let shippingDelivery = PKShippingMethod(label: "Delivery", amount: NSDecimalNumber(string: "1.00"))
        shippingDelivery.dateComponentsRange = PKDateComponentsRange(start: startComponents, end: endComponents)
        shippingDelivery.detail = "Shoes sent to you address"
        shippingDelivery.identifier = "DELIVERY"
        
        //        let shippingCollection = PKShippingMethod(label: "Collection", amount: NSDecimalNumber(string: "0.00"))
        //        shippingCollection.detail = "Collect shoes at festival"
        //        shippingCollection.identifier = "COLLECTION"
        
        //        return [shippingDelivery, shippingCollection]
        
        return [shippingDelivery]
    }
}
