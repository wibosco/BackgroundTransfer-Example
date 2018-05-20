//
//  GalleryURLRequestFactory.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 28/04/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

class GalleryURLRequestFactory: URLRequestFactory {
    
    // MARK: - Retrieval
    
    func requestToRetrieveGallerySearchResults(for searchTerms: String) -> URLRequest {
        var request = jsonRequest(endPoint: "gallery/search/?q_all=\(searchTerms)&q_type=jpg")
        request.httpMethod = HTTPRequestMethod.get.rawValue
        
        return request
    }
}
