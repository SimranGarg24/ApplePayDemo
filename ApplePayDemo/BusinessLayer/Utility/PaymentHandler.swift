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
    
    /// determine whether the user will be able to make payments using a network that you support
    func applePayStatus() -> (canMakePayments: Bool, canSetupCards: Bool) {
        
        // PKPaymentAuthorizationController - An object that presents a sheet that prompts the user to authorize a payment request.
        
        // canMakePayments() - Returns whether the user can make payments using Apple Pay. If canMakePayments returns NO, the device does not support Apple Pay.
        
        // canMakePayments(usingNetworks:) - Returns whether the user can make payments through the specified network. (checks for available payment cards). If canMakePayments returns YES but canMakePaymentsUsingNetworks: returns NO, the device supports Apple Pay, but the user has not added a card for any of the requested networks.
        return (PKPaymentAuthorizationController.canMakePayments(), PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks))
    }
    
    func addCoupons(_ coupons: [Coupon]) {
        self.coupons = coupons
    }
    
    // To initiate a payment, create a payment request and pass this request to a payment authorization view controller to display payment sheet.
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
            merchantCapabilities: merchantCapabilities, // 3-D Secure protocol, a secure way of processing debit and credit cards.
            countryCode: countryCode,
            shippingType: shippingType,
            shippingMethods: shippingMethods,
            supportsCoupon: supportsCoupon)
        
        selectedCountry = countryCode
        
        // Pass payment request to a payment authorization view controller, which displays the request to the user and prompts for any needed information, such as a shipping or billing address.The payment sheet handles all user interactions, including payment confirmation. Your delegate is called to update the request as the user interacts with the view controller.
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
    
    /// Payment requests are instances of the PKPaymentRequest class. A payment request consists of a list of summary items that describe to the user what is being paid for, a list of available shipping methods, a description of what shipping information the user needs to provide, and information about the merchant and the payment processor. It also ncludes the subtotal for the services and goods purchased, as well as any additional charges for tax, shipping, or discounts
    func setupPaymentRequest(paymentSummaryItems: [SummaryItem],
                             merchantID: String,
                             merchantCapabilities: PKMerchantCapability,
                             countryCode: Country,
                             shippingType: PKShippingType,
                             shippingMethods: [ShippingDetails]?,
                             supportsCoupon: Bool) -> PKPaymentRequest {
        
        let paymentRequest = PKPaymentRequest()
        
        // country code indicates the country where the purchase took place or where the purchase will be processed.
        paymentRequest.countryCode = countryCode.rawValue
        // All of the summary amounts in a payment request use the same currency, which is specified using the currencyCode.
        paymentRequest.currencyCode = countryCode.currencyCode
        paymentRequest.merchantIdentifier = merchantID
        paymentRequest.merchantCapabilities = merchantCapabilities
        paymentRequest.supportedNetworks = supportedNetworks
        
        paymentRequest.paymentSummaryItems = setSummaryItems(paymentSummaryItems)
        
//        paymentRequest.shippingType = shippingType
//        paymentRequest.shippingMethods = setShippingMethods(shippingMethods)
//        paymentRequest.requiredShippingContactFields = [.name, .postalAddress]
//        paymentRequest.supportsCouponCode = supportsCoupon
        
        return paymentRequest
    }
    
    // creates an array of PKPaymentSummaryItem to display the charges on the payment sheet.
    /// Payment summary items, represented by the PKPaymentSummaryItem class, describe the different parts of the payment request to the user.
    /// Use a small number of summary items—typically the subtotal, any discount, the shipping, the tax, and the grand total. If you do not have any additional fees (for example, shipping or tax), just use the purchase’s total.
    /// The last payment summary item in the list is the grand total. Calculate the grand total amount by adding the amounts of all the other summary items.
    func setSummaryItems(_ summaryItmes: [SummaryItem]) -> [PKPaymentSummaryItem] {
        
        paymentSummaryItems = []
        
        for item in summaryItmes {
            let itm = PKPaymentSummaryItem(label: item.label, amount: NSDecimalNumber(value: item.amount), type: .final)
            paymentSummaryItems.append(itm)
        }
        
        return paymentSummaryItems
    }
    
    // Create an instance of PKShippingMethod for each available shipping method.
    func setShippingMethods(_ shippingMethods: [ShippingDetails]?) -> [PKShippingMethod]? {
        
        guard let shippingMethods else {
            return nil
        }
        
        self.shippingMethods = []
        
        for method in shippingMethods {
            
            let shippingDelivery = PKShippingMethod(label: method.label, amount: NSDecimalNumber(value: method.amount))
            
            shippingDelivery.detail = method.detail
            shippingDelivery.identifier = method.identifier // To distinguish shipping methods in your delegate methods, use the identifier property.
            
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
    
}

// MARK: - Extension

/// The delegate methods are called when the user interacts with the view controller so that your app can update the information shown—for example, to update the shipping price when a shipping address is selected.
/// The delegate is also called after the user authorizes the payment request.
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
            // When the user authorizes a payment request, the framework creates a payment token by coordinating with Apple’s server and the Secure Element. Apple's server requires Payment Processing Certificate to encrypt the token.
            // Send the payment token to your server or payment provider to process here.
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
                    // For a discount or a coupon, set the amount to a negative number.
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
