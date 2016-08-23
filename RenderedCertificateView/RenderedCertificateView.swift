//
//  RCView.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/23/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit

class RenderedCertificateView: UIView {

    @IBOutlet var view: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var issuerIcon: UIImageView!
    @IBOutlet weak var leftSignature: UIImageView!
    @IBOutlet weak var sealIcon: UIImageView!
    @IBOutlet weak var rightSignature: UIImageView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Bundle.main.loadNibNamed("RenderedCertificateView", owner: self, options: nil)
        addSubview(view)
    }

}
