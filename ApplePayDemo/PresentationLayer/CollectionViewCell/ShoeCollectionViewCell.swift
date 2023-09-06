//
//  ShoeCollectionViewCell.swift
//  ApplePayDemo
//
//  Created by Saheem Hussain on 05/09/23.
//

import UIKit

class ShoeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var price: UILabel!
    
    func configure(data: ShoeModel) {
        name.text = data.name
        price.text = "Price: Rs. \(String(format: "%.02f", data.price))"
    }
}
