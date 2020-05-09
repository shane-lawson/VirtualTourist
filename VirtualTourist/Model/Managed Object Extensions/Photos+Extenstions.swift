//
//  Photo+Extenstions.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 5/7/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension Photo {
   // create a unique id for each photo so a sort descriptor can be used for an NSFetchedResponseController
   static var currentId: Int64 = 0
   
   class func getUniqueId() -> Int64 {
      currentId += 1
      return currentId
   }
   
   public override func awakeFromInsert() {
      self.id = Photo.getUniqueId()
      // put placeholder image into photo
      self.imageData = UIImage(systemName: "photo.fill")?.jpegData(compressionQuality: 1.0)
   }
   
   // construct a UIImage from the stored imageData on get, store UIImage as imageData and track that it's no longer a placeholder image on set
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
