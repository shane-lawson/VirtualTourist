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
   var coordinate: CLLocationCoordinate2D {
      get {
         return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
      }
      set(newCoordinate) {
         self.latitude = newCoordinate.latitude
         self.longitude = newCoordinate.longitude
      }
   }
}
