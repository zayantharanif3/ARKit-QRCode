//
//  HomeViewController.swift
//  ARKitImageDetection
//
//  Created by Zayan Tharani on 8/18/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func recordMapButtonTapped(_ sender: UIButton) {
        if let destinationVC = storyboard?.instantiateViewController(withIdentifier: "RecordViewController") as? RecordViewController {
            navigationController?.pushViewController(destinationVC, animated: true)
        }
    }
}
