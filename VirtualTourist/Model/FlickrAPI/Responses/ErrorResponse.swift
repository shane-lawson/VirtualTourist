//
//  ErrorResponse.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 5/4/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import Foundation

struct ErrorResponse: LocalizedError, Codable {
   let status: String
   let code: Int
   let message: String

   enum CodingKeys: String, CodingKey {
      case status = "stat"
      case code, message
   }
   
   var errorDescription: String? {
      return "\(code): \(message)"
   }
}
