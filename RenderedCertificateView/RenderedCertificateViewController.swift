//
//  RenderedCertificateViewController.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/23/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit

class RenderedCertificateViewController: UIViewController {

    var certificate : Certificate? {
        didSet {
            updateDisplay()
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        updateDisplay()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateDisplay() {
        guard view != nil else { return }
        
        titleLabel.text = certificate?.title
        subtitleLabel.text = certificate?.subtitle
    }
}
