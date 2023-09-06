//
//  PaymentHandler.swift
//  ApplePayDemo
//
//  Created by Saheem Hussain on 05/09/23.
//

import Foundation
import PassKit

struct SummaryItem {
    var label: String
    var amount: Double
}

struct Coupon {
    var code: String
    var amount: Double
}

enum Country: String {
    case US
    case IN
    
    var currencyCode: String {
        switch self {
        case .US:
            return "USD"
        case .IN:
            return "INR"
        }
    }
    
    var countryName: String {
        switch self {
        case .US:
            return "United States"
        case .IN:
            return "India"
        }
    }
}

struct ShippingDetails {
    var label: String
    var amount: Double
    var detail: String?
    var identifier: String?
    var startAfterDays: Int?
    var endAfterDays: Int?
}

typealias PaymentCompletionHandler = (Bool, PKPaymentToken?) -> Void

class PaymentHandler: NSObject {
    
    // MARK: - Properties
    private var paymentController: PKPaymentAuthorizationController?
    private var paymentSummaryItems = [PKPaymentSummaryItem]()
    private var shippingMethods = [PKShippingMethod]()
    private var paymentStatus = PKPaymentAuthorizationStatus.failure
    private var completionHandler: PaymentCompletionHandler!
    private var coupons: [Coupon]?
    private var selectedCountry: Country = .US
    
    let supportedNetworks: [PKPaymentNetwork] = [
        .amex,
        .discover,
        .masterCard,
        .visa
    ]
    
    static let shared = PaymentHandler()
    private override init() {}
    
    // MARK: - Methods
    func applePayStatus() -> (canMakePayments: Bool, canSetupCards: Bool) {
        
        // PKPaymentAuthorizationController - An object that presents a sheet that prompts the user to authorize a payment request.
        
        // canMakePayments() - Returns whether the user can make payments.
        
        // canMakePayments(usingNetworks:) - Returns whether the user can make payments through the specified network. (checks for available payment cards)
        return (PKPaymentAuthorizationController.canMakePayments(), PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks))
    }
    
    // creates an array of PKPaymentSummaryItem to display the charges on the payment sheet.
    func setSummaryItems(_ summaryItmes: [SummaryItem]) -> [PKPaymentSummaryItem] {
        
        paymentSummaryItems = []
        
        for item in summaryItmes {
            let itm = PKPaymentSummaryItem(label: item.label, amount: NSDecimalNumber(value: item.amount), type: .final)
            paymentSummaryItems.append(itm)
        }
        
        return paymentSummaryItems
    }
    
    func setShippingMethods(_ shippingMethods: [ShippingDetails]?) -> [PKShippingMethod]? {
        
        guard let shippingMethods else {
            return nil
        }
        
        self.shippingMethods = []
        
        for method in shippingMethods {
            
            let shippingDelivery = PKShippingMethod(label: method.label, amount: NSDecimalNumber(value: method.amount))
            
            shippingDelivery.detail = method.detail
            shippingDelivery.identifier = method.identifier
            
            if let start = method.startAfterDays, let end = method.endAfterDays {
                // Calculate pickup date.
                let today = Date()
                let calendar = Calendar.current
                
                let shippingStart = calendar.date(byAdding: .day, value: start, to: today)!
                let shippingEnd = calendar.date(byAdding: .day, value: end, to: today)!
                
                let startComponents = calendar.dateComponents([.calendar, .year, .month, .day], from: shippingStart)
                let endComponents = calendar.dateComponents([.calendar, .year, .month, .day], from: shippingEnd)
                
                shippingDelivery.dateComponentsRange = PKDateComponentsRange(start: startComponents, end: endComponents)
            }
            
            self.shippingMethods.append(shippingDelivery)
        }
        
        return self.shippingMethods
    }
    
    func startPayment(paymentSummaryItems: [SummaryItem],
                      merchantID: String,
                      merchantCapabilities: PKMerchantCapability = .capability3DS,
                      countryCode: Country,
                      shippingType: PKShippingType = .delivery,
                      shippingMethods: [ShippingDetails]?,
                      supportsCoupon: Bool = false,
                      completion: @escaping PaymentCompletionHandler) {
        
        completionHandler = completion
        
        // Create a payment request.
        let paymentRequest = setupPaymentRequest(
            paymentSummaryItems: paymentSummaryItems,
            merchantID: merchantID,
            merchantCapabilities: merchantCapabilities,
            countryCode: countryCode,
            shippingType: shippingType,
            shippingMethods: shippingMethods,
            supportsCoupon: supportsCoupon)
        
        selectedCountry = countryCode
        
        // Display the payment sheet.
        // The payment sheet handles all user interactions, including payment confirmation. It requests updates using the completion handlers stored by the startPayment method when a user updates the sheet.
        paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController?.delegate = self
        paymentController?.present(completion: { (presented: Bool) in
            if presented {
                debugPrint("Presented payment controller")
            } else {
                debugPrint("Failed to present payment controller")
                self.completionHandler(false, nil)
            }
        })
    }
    
    func setupPaymentRequest(paymentSummaryItems: [SummaryItem],
                             merchantID: String,
                             merchantCapabilities: PKMerchantCapability,
                             countryCode: Country,
                             shippingType: PKShippingType,
                             shippingMethods: [ShippingDetails]?,
                             supportsCoupon: Bool) -> PKPaymentRequest {
        
        let paymentRequest = PKPaymentRequest()
        paymentRequest.paymentSummaryItems = setSummaryItems(paymentSummaryItems)
        paymentRequest.merchantIdentifier = merchantID
        // 3-D Secure protocol, a secure way of processing debit and credit cards.
        paymentRequest.merchantCapabilities = merchantCapabilities
        paymentRequest.countryCode = countryCode.rawValue
        paymentRequest.currencyCode = countryCode.currencyCode
        paymentRequest.supportedNetworks = supportedNetworks
        paymentRequest.shippingType = shippingType
        paymentRequest.shippingMethods = setShippingMethods(shippingMethods)
        paymentRequest.requiredShippingContactFields = [.name, .postalAddress]
        paymentRequest.supportsCouponCode = supportsCoupon
        
        return paymentRequest
    }
    
    func addCoupons(_ coupons: [Coupon]) {
        self.coupons = coupons
    }
    
}

// MARK: - Extension
extension PaymentHandler: PKPaymentAuthorizationControllerDelegate {
    
    // Tells the delegate that the user authorized the payment request, and asks for a result
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        
        // Your handler confirms that the shipping address meets the criteria needed, and then calls the completion handler to report success or failure of the payment.
        var errors = [Error]()
        var status = PKPaymentAuthorizationStatus.success
        if payment.shippingContact?.postalAddress?.isoCountryCode != selectedCountry.rawValue {
            let pickupError = PKPaymentRequest.paymentShippingAddressUnserviceableError(withLocalizedDescription: "Sample App only available in the \(selectedCountry.countryName)")
            let countryError = PKPaymentRequest.paymentShippingAddressInvalidError(withKey: CNPostalAddressCountryKey, localizedDescription: "Invalid country")
            errors.append(pickupError)
            errors.append(countryError)
            status = .failure
        } else {
            // Send the payment token to your server or payment provider to process here.
            // Once processed, return an appropriate status in the completion handler (success, failure, and so on).
            self.completionHandler!(true, payment.token)
            status = .success
        }
        
        self.paymentStatus = status
        completion(PKPaymentAuthorizationResult(status: self.paymentStatus, errors: errors))
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        // The payment sheet doesn't automatically dismiss once it has finished. Dismiss the payment sheet.
        controller.dismiss {}
    }
    
#if !os(watchOS)
    
    // The `didChangeCouponCode` delegate method allows you to make changes when the user enters or updates a coupon code.
    
    /// After the user enters an accepted coupon code, the method adds a new PKPaymentSummaryItem displaying the discount, and adjusts the PKPaymentSummaryItem with the discounted total.
    
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didChangeCouponCode couponCode: String,
                                        handler completion: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void) {
        
        if couponCode.isEmpty {
            // If the user doesn't enter a code, return the current payment summary items.
            completion(PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: paymentSummaryItems))
            return
        }
        
        guard let coupons = coupons else {
            completion(PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: paymentSummaryItems))
            return
        }
        
        for coupon in coupons {
            if couponCode.uppercased() == coupon.code.uppercased() {
                
                func applyDiscount(items: [PKPaymentSummaryItem]) -> [PKPaymentSummaryItem] {
                    
                    let tickets = items.first!
                    
                    let couponDiscountItem = PKPaymentSummaryItem(label: "Coupon Code Applied", amount: NSDecimalNumber(string: "-\(coupon.amount)"))
                    
                    let updatedPrice = Double(truncating: tickets.amount) - coupon.amount
                    
                    for item in items where item.label == "Tax" {
                        let tax = (5 * updatedPrice)/100
                        let updatedTax = PKPaymentSummaryItem(label: "Tax", amount: NSDecimalNumber(string: "\(tax)"), type: .final)
                        
                        let updatedTotalPrice = updatedPrice + tax
                        let updatedTotal = PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(string: "\(updatedTotalPrice)"), type: .final)
                        let discountedItems = [tickets, couponDiscountItem, updatedTax, updatedTotal]
                        return discountedItems
                    }
                    
                    let updatedTotalPrice = updatedPrice
                    let updatedTotal = PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(string: "\(updatedTotalPrice)"), type: .final)
                    let discountedItems = [tickets, couponDiscountItem, updatedTotal]
                    return discountedItems
                }
                
                // If the coupon code is valid, update the summary items.
                let couponCodeSummaryItems = applyDiscount(items: paymentSummaryItems)
                completion(PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: applyDiscount(items: couponCodeSummaryItems)))
                return
                
            } else {
                // If the user enters a code, but it's not valid, we can display an error.
                let couponError = PKPaymentRequest.paymentCouponCodeInvalidError(localizedDescription: "Coupon code is not valid.")
                completion(PKPaymentRequestCouponCodeUpdate(errors: [couponError], paymentSummaryItems: paymentSummaryItems, shippingMethods: shippingMethods))
                return
            }
        }
    }
    
#endif
}
