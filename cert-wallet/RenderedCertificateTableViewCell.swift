//
//  RenderedCertificateTableViewCell.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/24/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit

class RenderedCertificateTableViewCell: UITableViewCell {
    
    weak var renderedView: RenderedCertificateView?
    
    // MARK: Pass-through properties to the rendered view.
    var titleText : String? {
        get {
            return renderedView?.titleLabel.text
        }
        set {
            renderedView?.titleLabel.text = newValue
        }
    }
    var subtitleText : String? {
        get {
            return renderedView?.subtitleLabel.text
        }
        set {
            renderedView?.subtitleLabel.text = newValue
        }
    }
    var issuerIcon: UIImage? {
        get {
            return renderedView?.issuerIcon.image
        }
        set {
            renderedView?.issuerIcon.image = newValue
        }
    }
    var leftSignature: UIImage? {
        get {
            return renderedView?.leftSignature.image
        }
        set {
            renderedView?.leftSignature.image = newValue
        }
    }
    var sealIcon: UIImage? {
        get {
            return renderedView?.sealIcon.image
        }
        set {
            renderedView?.sealIcon.image = newValue
        }
    }
    var rightSignature: UIImage? {
        get {
            return renderedView?.rightSignature.image
        }
        set {
            renderedView?.rightSignature.image = newValue
        }
    }
    
    // MARK: Initialization of the Rendered certificate view.
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    private func commonInit() {
        let renderedView = RenderedCertificateView(frame: contentView.bounds)
        contentView.addSubview(renderedView)
        self.renderedView = renderedView
    }
}
