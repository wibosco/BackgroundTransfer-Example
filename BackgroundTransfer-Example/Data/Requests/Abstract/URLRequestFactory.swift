//
//  URLRequestFactory.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 28/04/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

enum APIError: Error {
    case unknown
    case missingData
    case serialization
    case invalidData
}

class URLRequestFactory {
    
    let config: RequestConfig
    
    // MARK: - Init
    
    init(config: RequestConfig = RequestConfig.shared) {
        self.config = config
    }
    
    // MARK: - Factory
    
    func baseRequest(endPoint: String) -> URLRequest {
        let stringURL = "\(config.APIHost)/\(endPoint)"
        let encodedStringURL = stringURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: encodedStringURL!)!
    
        var request = URLRequest(url: url)
        request.addValue("Client-ID \(config.clientID)", forHTTPHeaderField: "Authorization")

        return request
    }
    
    func jsonRequest(endPoint: String) -> URLRequest {
        var request = baseRequest(endPoint: endPoint)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return request
    }
}
