//
//  Parser.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 28/04/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

class Parser<T> {
    
    // MARK: - Parse
    
    func parseResponse(_ response: [String: Any]) -> T {
        fatalError("Subclass needs to override this method")
    }
}
