//
//  ShoeStoreViewController.swift
//  ApplePayDemo
//
//  Created by Saheem Hussain on 05/09/23.
//

import UIKit

class ShoeStoreViewController: UIViewController {

    @IBOutlet weak var shoeCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}

extension ShoeStoreViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ShoeModel.shoeData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? ShoeCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        cell.configure(data: ShoeModel.shoeData[indexPath.row])
        cell.backgroundColor = .lightGray
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as? DetailViewController {
            vc.viewModel.name = ShoeModel.shoeData[indexPath.row].name
            vc.viewModel.price = ShoeModel.shoeData[indexPath.row].price
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
