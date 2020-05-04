//
//  PhotoResponse.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 5/4/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import Foundation

struct PhotoResponse: Codable {
   let id: String
   let owner: String
   let secret: String
   let server: String
   let farm: Int
   let title: String
   let isPublic: Int
   let isFriend: Int
   let isFamily: Int
   
   enum CodingKeys: String, CodingKey {
      case id, owner, secret, server, farm, title
      case isPublic = "ispublic"
      case isFriend = "isfriend"
      case isFamily = "isfamily"
   }
}
