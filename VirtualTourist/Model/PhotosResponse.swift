//
//  PhotosResponse.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 5/4/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import Foundation

struct PhotosResponse: Codable {
   let page: Int
   let pages: Int
   let perPage: Int
   let total: String
   let photo: [PhotoResponse]
   
   enum CodingKeys: String, CodingKey {
      case page, pages, total, photo
      case perPage = "perpage"
   }
}
