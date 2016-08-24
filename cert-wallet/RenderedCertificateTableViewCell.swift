//
//  RenderedCertificateTableViewCell.swift
//  cert-wallet
//
//  Created by Chris Downie on 8/24/16.
//  Copyright © 2016 Digital Certificates Project. All rights reserved.
//

import UIKit

class RenderedCertificateTableViewCell: UITableViewCell {
    weak var titleLabel: UILabel!
    weak var subtitleLabel: UILabel!
    weak var issuerIcon: UIImageView!
    weak var leftSignature: UIImageView!
    weak var sealIcon: UIImageView!
    weak var rightSignature: UIImageView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    private func commonInit() {
        let rect = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: 200)
        let renderedView = RenderedCertificateView(frame: rect)
        contentView.addSubview(renderedView)
    }
}
