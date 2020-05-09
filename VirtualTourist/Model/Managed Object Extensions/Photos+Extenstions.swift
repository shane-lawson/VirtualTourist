//
//  Photos+Extenstions.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 5/7/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension Photos {
   static var currentId: Int64 = 0
   
   class func getUniqueId() -> Int64 {
      currentId += 1
      return currentId
   }
   
   public override func awakeFromInsert() {
      self.id = Photos.getUniqueId()
      self.imageData = UIImage(systemName: "photo.fill")?.jpegData(compressionQuality: 1.0)
   }
   
   var image: UIImage {
      get {
         return UIImage(data: self.imageData!)!
      }
      set(newImage) {
         self.imageData = newImage.jpegData(compressionQuality: 1.0)
         self.isPlaceholderImage = false
      }
   }
}
