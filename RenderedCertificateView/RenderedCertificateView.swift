//
//  RenderedCertificateView.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/23/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit

class RenderedCertificateView: UIView {
    
    @IBOutlet weak var certificateView: UIView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    
    var certificate : Certificate? {
        didSet {
            if let certificate = certificate {
                title.text = certificate.title
                subtitle.text = certificate.subtitle
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        certificateView.layer.shadowOffset = CGSize(width: 0, height: 5)
        certificateView.layer.shadowColor = UIColor.black.cgColor
        certificateView.layer.shadowRadius = 5.0
        certificateView.layer.shadowOpacity = 0.5
    }
}
