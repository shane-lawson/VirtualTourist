//
//  Pin+Extensions.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 5/7/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import Foundation
import CoreData
import MapKit

extension Pin {
   // construct a coordinate from lat and long on get and save coordinate components to lat and long on set
   var coordinate: CLLocationCoordinate2D {
      get {
         return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
      }
      set(newCoordinate) {
         self.latitude = newCoordinate.latitude
         self.longitude = newCoordinate.longitude
      }
   }
   
   public override func awakeFromInsert() {
      // create 30 photos for the collection and add to pin
      for _ in 0..<30 {
         self.addToPhotos(Photo(context: self.managedObjectContext!))
      }
   }
}
