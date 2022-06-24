//
//  Display.swift
//  Blockcerts
//
//  Created by Matthieu Collé on 23/06/2022.
//  Copyright © 2022 Digital Certificates Project. All rights reserved.
//

import Foundation

public struct Display {
    /// The content media type of the display
    var contentMediaType : String { get }

    /// The display content
    var content : String { get }
    
    public init(contentMediaType: String, content: String) {
        self.contentMediaType = contentMediaType
        self.content = content
    }
}
