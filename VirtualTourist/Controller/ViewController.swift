//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 4/30/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {

   @IBOutlet weak var mapView: MKMapView!
   @IBOutlet weak var collectionView: UICollectionView!
   
   var photoLocations: [PhotoResponse]!
   var photos = [UIImage]()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      // Do any additional setup after loading the view.
      
      mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(dropPin(_:))))

      collectionView.dataSource = self
      collectionView.isHidden = true
   }
   
   func getPhotos(at location: CLLocationCoordinate2D) {
      FlickrAPI.searchForPhotos(at: (lat: location.latitude, long: location.longitude)) { (photoLocations, error) in
         guard error == nil else { print(error!); return }
         self.photoLocations = photoLocations
         photoLocations.forEach {
            FlickrAPI.downloadPhoto($0, completionHandler: self.handlePhotoDownload(data:error:))
         }
      }
   }
   
   func handlePhotoDownload(data: Data?, error: Error?) {
      guard let data = data else { print(error!); return }
      if let image = UIImage(data: data) {
         photos.append(image)
//         collectionView.reloadItems(at: [IndexPath(item: photos.endIndex, section: 0)])
         collectionView.reloadData()
      }
   }
   
   @objc func dropPin(_ sender: UILongPressGestureRecognizer) {
      switch sender.state {
//      case .possible:
//      case .began:
//      case .changed:
      case .ended:
         let pinCoord = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
         let pin = MKPointAnnotation()
         pin.coordinate = pinCoord
         mapView.addAnnotation(pin)
         mapView.setCenter(pin.coordinate, animated: true)
         getPhotos(at: pin.coordinate)
         collectionView.isHidden = false
//      case .cancelled:
//      case .failed:
      default:
         break
      }
   }
}

// MARK: - UICollectionViewDataSource

extension ViewController: UICollectionViewDataSource {
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
