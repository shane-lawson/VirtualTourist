//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 5/7/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

   @IBOutlet weak var mapView: MKMapView!
   
   var locations = [MKPointAnnotation]()
   var selectedLocation: MKPointAnnotation!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(dropPin(_:))))

      // check if is not initialised value, load map region from UserDefaults
      if VTUserDefaults.latitudeDelta != 0.0 {
         mapView.region = VTUserDefaults.region
      }

      mapView.delegate = self
   }

   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      navigationController?.navigationBar.isHidden = true
   }
   
   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      navigationController?.navigationBar.isHidden = false
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier {
      case "showCollection":
         let destinationVC = segue.destination as! MapWithCollectionViewDetailViewController
         destinationVC.location = selectedLocation
      default:
         print("prepare(for:) not implemented for segue \(segue.identifier!)")
         break
      }
   }
   

   @objc func dropPin(_ sender: UILongPressGestureRecognizer) {
      switch sender.state {
      case .began:
         let pinCoord = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
         let pin = MKPointAnnotation()
         pin.coordinate = pinCoord
         locations.append(pin)
         mapView.addAnnotation(pin)
      default:
         break
      }
   }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
   
   func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
      VTUserDefaults.region = mapView.region
   }
   
   func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
      selectedLocation = view.annotation as? MKPointAnnotation
      performSegue(withIdentifier: "showCollection", sender: self)
   }
   
   func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      let reuseIdentifier = "pin"
      var pinView: MKAnnotationView!
      if let pin = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) {
         pinView = pin
      } else {
         let newPin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
         newPin.canShowCallout = false
         newPin.animatesDrop = true
         pinView = newPin
      }
      return pinView
   }
}
