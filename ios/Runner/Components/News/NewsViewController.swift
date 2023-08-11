//
//  NewsViewController.swift
//  Runner
//
//  Created by Eizar Paing on 4/21/21.
//

import UIKit

class NewsViewController: UIViewController {
    var coordinatorDelegate: NewsCoordinatorDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func goToFlutter(_ sender: Any) {
        coordinatorDelegate?.navigateToFlutter()
    }

}

