//
//  NetworkService.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 21/02/2025.
//  Copyright © 2025 William Boles. All rights reserved.
//

import Foundation
import os

struct Cat: Decodable, Equatable {
    let id: String
    let url: URL
}

enum NetworkServiceError: Error {
    case networkError
    case unexpectedStatusCode
    case decodingErrror
}

class NetworkService {
    // MARK: - Cats
    
    func retrieveCats(completionHandler: @escaping ((Result<[Cat], Error>) -> ()))  {
        let APIKey = "live_yzNvM2rsrxvWpSwtsAWzbSiGoGW175yNLmnO1u5Fh5GMFxbZ9l4C01t9BcP2v6WQ"
        
        assert(APIKey.isEmpty, "Replace this empty string with your API key from: https://thecatapi.com/")
        
        let limitQueryItem = URLQueryItem(name: "limit", value: "50")
        let sizeQueryItem = URLQueryItem(name: "size", value: "thumb")
        
        let queryItems = [limitQueryItem, sizeQueryItem]
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.thecatapi.com"
        components.path = "/v1/images/search"
        components.queryItems = queryItems
        
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue(APIKey, forHTTPHeaderField: "x-api-key")
        
        os_log(.error, "Retrieving cats...")
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data, let response = response else {
                completionHandler(.failure(NetworkServiceError.networkError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completionHandler(.failure(NetworkServiceError.unexpectedStatusCode))
                return
            }
            
            guard let cats = try? JSONDecoder().decode([Cat].self, from: data) else {
                completionHandler(.failure(NetworkServiceError.decodingErrror))
                return
            }
            
            os_log(.error, "Cats successfully retrieved!")
            completionHandler(.success(cats))
        }
        task.resume()
    }
}
