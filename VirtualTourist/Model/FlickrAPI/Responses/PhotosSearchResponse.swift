//
//  PhotosSearchResponse.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 5/4/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import Foundation

struct PhotosSearchResponse: Codable {
   let photos: PhotosResponse
   let status: String
   
   enum CodingKeys: String, CodingKey {
      case photos
      case status = "stat"
   }
}
