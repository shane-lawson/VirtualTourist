//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 5/7/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

   @IBOutlet weak var mapView: MKMapView!
   
   var pins: [Pin]!
   var selectedLocation: Pin!
   
   var dataController: DataController!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      mapView.delegate = self
      mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(dropPin(_:))))
      
      // check if is not initialised value, load map region from UserDefaults
      if VTUserDefaults.latitudeDelta != 0.0 {
         mapView.region = VTUserDefaults.region
      }
      
      performFetch()
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
         destinationVC.pin = selectedLocation
         destinationVC.dataController = dataController
      default:
         print("prepare(for:) not implemented for segue \(segue.identifier!)")
         break
      }
   }
   

   @objc func dropPin(_ sender: UILongPressGestureRecognizer) {
      guard sender.state == .began else { return }
      let coordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
      mapView.addAnnotation(createPointAnnotation(coordinate: coordinate))
      savePin(coordinate: coordinate)
   }
   
   fileprivate func createPointAnnotation(coordinate: CLLocationCoordinate2D) -> MKPointAnnotation {
      let annotation = MKPointAnnotation()
      annotation.coordinate = coordinate
      return annotation
   }
   
   fileprivate func savePin(coordinate: CLLocationCoordinate2D) {
      let pin = Pin(context: dataController.viewContext)
      pin.coordinate = coordinate
      pins.append(pin)
      try? dataController.viewContext.save()
   }
   
   fileprivate func performFetch() {
      let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
      if let result = try? dataController.viewContext.fetch(fetchRequest) {
         pins = result
         let annotations = result.map { createPointAnnotation(coordinate: $0.coordinate) }
         mapView.removeAnnotations(mapView.annotations)
         mapView.addAnnotations(annotations)
      }
   }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
   
   func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
      VTUserDefaults.region = mapView.region
   }
   
   func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
      selectedLocation = pins.filter({ $0.coordinate.latitude == view.annotation?.coordinate.latitude && $0.coordinate.longitude == view.annotation?.coordinate.longitude }).first
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
