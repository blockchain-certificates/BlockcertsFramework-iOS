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
    var nameText : String? {
        get {
            return renderedView?.nameLabel.text
        }
        set {
            renderedView?.nameLabel.text = newValue
        }
    }
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
    var certificateIcon : UIImage? {
        get {
            return renderedView?.certificateIcon.image
        }
        set {
            renderedView?.certificateIcon.image = newValue
        }
    }
//    var issuerIcon: UIImage? {
//        get {
//            return renderedView?.issuerIcon.image
//        }
//        set {
//            renderedView?.issuerIcon.image = newValue
//        }
//    }
//    var leftSignature: UIImage? {
//        get {
//            return renderedView?.leftSignature.image
//        }
//        set {
//            renderedView?.leftSignature.image = newValue
//        }
//    }
//    var sealIcon: UIImage? {
//        get {
//            return renderedView?.sealIcon.image
//        }
//        set {
//            renderedView?.sealIcon.image = newValue
//        }
//    }
//    var rightSignature: UIImage? {
//        get {
//            return renderedView?.rightSignature.image
//        }
//        set {
//            renderedView?.rightSignature.image = newValue
//        }
//    }
    
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
        renderedView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addConstraint(NSLayoutConstraint(item: renderedView, attribute: .top, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0))
        contentView.addConstraint(NSLayoutConstraint(item: renderedView, attribute: .bottom, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0))
        contentView.addConstraint(NSLayoutConstraint(item: renderedView, attribute: .left, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: .left, multiplier: 1, constant: 0))
        contentView.addConstraint(NSLayoutConstraint(item: renderedView, attribute: .right, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: .right, multiplier: 1, constant: 0))
        
        self.renderedView = renderedView
    }
}
