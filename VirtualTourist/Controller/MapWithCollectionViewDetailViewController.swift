//
//  MapWithCollectionViewDetailViewController.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 4/30/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import UIKit
import MapKit

class MapWithCollectionViewDetailViewController: UIViewController {

   @IBOutlet weak var mapView: MKMapView!
   @IBOutlet weak var collectionView: UICollectionView!
   @IBOutlet weak var newCollectionButton: UIBarButtonItem!
   
   var photoLocations: [PhotoResponse]!
   var photos = [UIImage]()
   var location: MKPointAnnotation!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      getPhotos(at: location.coordinate)
      
      mapView.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: CLLocationDistance(exactly: 2000)!, longitudinalMeters: CLLocationDistance(exactly: 2000)!)
      mapView.addAnnotation(location)
      mapView.delegate = self
      
      collectionView.dataSource = self
      collectionView.delegate = self
   }
   
   @IBAction func newCollectionTapped(_ sender: UIBarButtonItem) {
      getPhotos(at: location.coordinate)
   }
   
   fileprivate func getPhotos(at location: CLLocationCoordinate2D) {
      setLoadingNewCollection(true)
      FlickrAPI.searchForPhotos(at: (lat: location.latitude, long: location.longitude)) { (photoLocations, error) in
         guard error == nil else { print(error!); return }
         self.photoLocations = photoLocations
         photoLocations.forEach {
            FlickrAPI.downloadPhoto($0, completionHandler: self.handlePhotoDownload(data:error:))
         }
      }
   }
   
   fileprivate func handlePhotoDownload(data: Data?, error: Error?) {
      guard let data = data else { print(error!); return }
      if let image = UIImage(data: data) {
         photos.append(image)
//         collectionView.reloadItems(at: [IndexPath(item: photos.endIndex, section: 0)])
         collectionView.reloadData()
      }
      setLoadingNewCollection(false)
   }
   
   fileprivate func setLoadingNewCollection(_ loading: Bool) {
      newCollectionButton.isEnabled = !loading
   }
}

// MARK: - UICollectionViewDataSource

extension MapWithCollectionViewDetailViewController: UICollectionViewDataSource {
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return 30
   }
   
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
      cell.imageView.image = image(at: indexPath)
      return cell
   }
   
   func image(at indexPath: IndexPath) -> UIImage {
      if indexPath.item < photos.count {
         return photos[indexPath.item]
      } else {
         return UIImage(systemName: "photo.fill")!
      }
   }
   
}

// MARK: - UICollectionViewDelegate

extension MapWithCollectionViewDetailViewController: UICollectionViewDelegate {
   func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      photos.remove(at: indexPath.item)
      collectionView.scrollsToTop = false
      collectionView.performBatchUpdates({
         collectionView.deleteItems(at: [indexPath])
         collectionView.insertItems(at: [IndexPath(item: 29, section: 0)])
      }, completion: nil)

      // TODO: fix random photo mostly selecting same photo
      FlickrAPI.searchForRandomPhoto(at: (lat: location.coordinate.latitude, long: location.coordinate.longitude)) { (photolocation, error) in
         guard let photolocation = photolocation else {print(error!); return }
         FlickrAPI.downloadPhoto(photolocation, completionHandler: self.handlePhotoDownload(data:error:))
      }
   }
}

// MARK: - UICollectionViewDelegate

extension MapWithCollectionViewDetailViewController: MKMapViewDelegate {
   func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      let reuseIdentifier = "pin"
      var pinView: MKAnnotationView!
      if let pin = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) {
         pinView = pin
      } else {
         let newPin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
         newPin.canShowCallout = false
         pinView = newPin
      }
      return pinView
   }
}
