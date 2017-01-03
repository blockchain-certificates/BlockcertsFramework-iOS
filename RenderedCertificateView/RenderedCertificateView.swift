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
    
    @IBOutlet weak var paperView: UIView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var certificateIcon: UIImageView!
    
    @IBOutlet weak var signatureStack: UIStackView!
    
    @IBOutlet weak var sealIcon: UIImageView!

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("RenderedCertificateView", owner: self, options: nil)
        styleize()
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        addConstraint(NSLayoutConstraint(item: view, attribute: .top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: view, attribute: .left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: .left, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: view, attribute: .right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: .right, multiplier: 1, constant: 0))
        
    }
    
    private func styleize() {
//        paperView.layer.shadowColor = UIColor.black.cgColor
//        paperView.layer.shadowOffset = CGSize(width: 0, height: 5)
//        paperView.layer.shadowRadius = 3.0
//        paperView.layer.shadowOpacity = 0.2
//        paperView.layer.borderColor = UIColor.black.cgColor
//        paperView.layer.borderWidth = 0.5
    }
    
    func clearSignatures() {
        signatureStack.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
    }
    
    func addSignature(image: UIImage, title: String?) {
        if title == nil {
            let subview = UIImageView(image: image)
            signatureStack.addArrangedSubview(subview)
        } else {
            let subview = createTitledSignature(signature: image, title: title!)
            signatureStack.addArrangedSubview(subview)
        }
        updateConstraints()
    }
    
    func createTitledSignature(signature: UIImage, title titleString: String) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.red
        
        // Configure all the subviews
        let signature = UIImageView(image: signature)
        signature.translatesAutoresizingMaskIntoConstraints = false
        signature.backgroundColor = UIColor.green
        
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = UIColor.gray

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = UIFont.systemFont(ofSize: 11)
        title.text = titleString
        
        view.addSubview(signature)
        view.addSubview(divider)
        view.addSubview(title)

        
        // Now do all the auto-layout.
        let namedViews = [
            "signature": signature,
            "divider": divider,
            "title": title
        ]
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[signature][divider]-[title]|", options: .alignAllCenterX, metrics: nil, views: namedViews)
        let dividerConstraints = [
            NSLayoutConstraint(item: divider, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 1),
            NSLayoutConstraint(item: divider, attribute: .width, relatedBy: .equal, toItem: title, attribute: .width, multiplier: 1, constant: 0)
        ]
        let centerConstraints = [
            NSLayoutConstraint(item: signature, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        ]
        
        NSLayoutConstraint.activate(verticalConstraints)
        NSLayoutConstraint.activate(dividerConstraints)
        NSLayoutConstraint.activate(centerConstraints)
        
        return view
    }
}
