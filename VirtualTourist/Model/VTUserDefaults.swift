//
//  VTUserDefaults.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 5/7/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import Foundation
import MapKit

class VTUserDefaults {
   // enum so that mistyped string keys aren't an issue
   enum Keys: String {
      case latitude, longitude, latitudeDelta, longitudeDelta, hasLaunchedBefore
   }
   
   // check for first launch (for use in AppDelegate) and initialise default values
   class func checkIfFirstLaunch() {
      if UserDefaults.standard.bool(forKey: Keys.hasLaunchedBefore.rawValue) {
      } else {
         UserDefaults.standard.set(true, forKey: Keys.hasLaunchedBefore.rawValue)
         UserDefaults.standard.set(0.0, forKey: Keys.latitude.rawValue)
         UserDefaults.standard.set(0.0, forKey: Keys.longitude.rawValue)
         UserDefaults.standard.set(0.0, forKey: Keys.latitudeDelta.rawValue)
         UserDefaults.standard.set(0.0, forKey: Keys.longitudeDelta.rawValue)
         UserDefaults.standard.synchronize()
      }
   }
   
   // main computed property to store/retrieve map region from UserDefaults
   static var region: MKCoordinateRegion {
      get {
         return MKCoordinateRegion(center: self.center, span: self.span)
      }
      set (newRegion) {
         self.center = newRegion.center
         self.span = newRegion.span
      }
   }
   
   // secondary helper properties for storing/retrieving values from UserDefaults
   static var center: CLLocationCoordinate2D {
      get {
         return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
      }
      set (newCenter)  {
         self.latitude = newCenter.latitude
         self.longitude = newCenter.longitude
      }
   }
   
   static var span: MKCoordinateSpan {
      get{
         return MKCoordinateSpan(latitudeDelta: self.latitudeDelta, longitudeDelta: self.longitudeDelta)
      }
      set (newSpan) {
         self.latitudeDelta = newSpan.latitudeDelta
         self.longitudeDelta = newSpan.longitudeDelta
      }
   }
   
   // primary helper properties for storing/retrieving values from UserDefaults
   static var latitude: Double {
      get {
         return UserDefaults.standard.double(forKey: Keys.latitude.rawValue)
      }
      set(newValue) {
         UserDefaults.standard.set(newValue, forKey: Keys.latitude.rawValue)
      }
   }
   
   static var longitude: Double {
      get {
         return UserDefaults.standard.double(forKey: Keys.longitude.rawValue)
      }
      set(newValue) {
         UserDefaults.standard.set(newValue, forKey: Keys.longitude.rawValue)
      }
   }
   
   static var latitudeDelta: Double {
      get {
         return UserDefaults.standard.double(forKey: Keys.latitudeDelta.rawValue)
      }
      set(newValue) {
         UserDefaults.standard.set(newValue, forKey: Keys.latitudeDelta.rawValue)
      }
   }
   
   static var longitudeDelta: Double {
      get {
         return UserDefaults.standard.double(forKey: Keys.longitudeDelta.rawValue)
      }
      set(newValue) {
         UserDefaults.standard.set(newValue, forKey: Keys.longitudeDelta.rawValue)
      }
   }
}
