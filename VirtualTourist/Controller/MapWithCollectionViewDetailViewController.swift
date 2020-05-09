//
//  MapWithCollectionViewDetailViewController.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 4/30/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapWithCollectionViewDetailViewController: UIViewController, NSFetchedResultsControllerDelegate {

   @IBOutlet weak var mapView: MKMapView!
   @IBOutlet weak var collectionView: UICollectionView!
   @IBOutlet weak var newCollectionButton: UIBarButtonItem!
   @IBOutlet weak var noImagesLabel: UILabel!
   
   var pin: Pin!
   
   var dataController: DataController!
   var fetchedResultsController: NSFetchedResultsController<Photos>!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      noImagesLabel.isHidden = true
      
      getPhotos(at: pin.coordinate)
      
      mapView.region = MKCoordinateRegion(center: pin.coordinate, latitudinalMeters: CLLocationDistance(exactly: 2000)!, longitudinalMeters: CLLocationDistance(exactly: 2000)!)
      let annotation = MKPointAnnotation()
      annotation.coordinate = pin.coordinate
      mapView.addAnnotation(annotation)
      mapView.delegate = self
      
      collectionView.dataSource = self
      collectionView.delegate = self
   }
   
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      setupFetchedResultsController()
   }
   
   override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      fetchedResultsController = nil
   }
   
   @IBAction func newCollectionTapped(_ sender: UIBarButtonItem) {
      pin.removeFromPhotos(pin.photos!)
      for _ in 0..<30 {
         let photo = Photos(context: dataController.viewContext)
         pin.addToPhotos(photo)
      }
      try? dataController.viewContext.save()
      getPhotos(at: pin.coordinate)
   }
   
   fileprivate func getPhotos(at location: CLLocationCoordinate2D) {
      setLoadingNewCollection(true)
      FlickrAPI.searchForPhotos(at: (lat: location.latitude, long: location.longitude)) { [unowned self] (photoLocations, error) in
         guard error == nil else { print(error!); return }
         photoLocations.forEach {
            FlickrAPI.downloadPhoto($0, completionHandler: self.handlePhotoDownload(data:error:))
         }
         if photoLocations.count < 30 {
            let photos = self.performFetch(offset: photoLocations.count)
            photos?.forEach { self.dataController.viewContext.delete($0) }
            if photoLocations.count == 0 {
               self.noImagesLabel.isHidden = false
            }
         }
      }
   }
   
   fileprivate func handlePhotoDownload(data: Data?, error: Error?) {
      guard let data = data else { print(error!); return }
      if let image = UIImage(data: data) {
         if let photos = performFetch() {
            if photos.count == 30 {
               photos.first(where: {$0.isPlaceholderImage})?.image = image
            } else {
               let newPhoto = Photos(context: dataController.viewContext)
               newPhoto.image = image
               pin.addToPhotos(newPhoto)
            }
            try? dataController.viewContext.save()
            if photos.first(where: {$0.isPlaceholderImage}) == nil {
               setLoadingNewCollection(false)
            }
         }
      }
   }
   
   fileprivate func setLoadingNewCollection(_ loading: Bool) {
      newCollectionButton.isEnabled = !loading
   }
   
   fileprivate func setupFetchedResultsController() {
      fetchedResultsController = NSFetchedResultsController(fetchRequest: createFetchRequest(), managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin.coordinate)")
      fetchedResultsController.delegate = self
      do {
         try fetchedResultsController.performFetch()
      } catch {
         fatalError("The fetch could not be performed: \(error.localizedDescription)")
      }
   }
   
   fileprivate func performFetch(offset: Int? = nil) -> [Photos]? {
      return try? dataController.viewContext.fetch(createFetchRequest(offset))
   }
   
   fileprivate func createFetchRequest(_ offset: Int? = nil) -> NSFetchRequest<Photos> {
      let fetchRequest: NSFetchRequest<Photos> = Photos.fetchRequest()
      let predicate = NSPredicate(format: "pin == %@", pin)
      fetchRequest.predicate = predicate
      let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
      fetchRequest.sortDescriptors = [sortDescriptor]
      if let offset = offset {
         fetchRequest.fetchOffset = offset
      }
      return fetchRequest
   }
   
   // MARK: - NSFetchedResultsControllerDelegate
   
   private var blockOperations = [BlockOperation]()
   
   func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
      
      switch type {
      case .insert:
         blockOperations.append(BlockOperation { [unowned self] in
            self.collectionView.insertItems(at: [newIndexPath!])
         })
      case .delete:
         blockOperations.append(BlockOperation { [unowned self] in
            self.collectionView.deleteItems(at: [indexPath!])
         })
      case .update:
         blockOperations.append(BlockOperation { [unowned self] in
            self.collectionView.reloadItems(at: [indexPath!])
         })
      case .move:
         fallthrough
      @unknown default:
         fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
      }
   }
   
   func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      blockOperations.removeAll()
   }
   
   func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      collectionView.performBatchUpdates({
         blockOperations.forEach { $0.start() }
      }, completion: nil)
   }
}

// MARK: - UICollectionViewDataSource

extension MapWithCollectionViewDetailViewController: UICollectionViewDataSource {
   
   func numberOfSections(in collectionView: UICollectionView) -> Int {
      return fetchedResultsController.sections?.count ?? 1
   }
   
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return fetchedResultsController.sections?[section].numberOfObjects ?? 0
   }
   
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let photo = fetchedResultsController.object(at: indexPath)
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
      cell.imageView.image = UIImage(data: photo.imageData!)
      return cell
   }
}

// MARK: - UICollectionViewDelegate

extension MapWithCollectionViewDetailViewController: UICollectionViewDelegate {
   func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      let photo = fetchedResultsController.object(at: indexPath)
      dataController.viewContext.delete(photo)
      try? dataController.viewContext.save()
      
      FlickrAPI.searchForRandomPhoto(at: (lat: pin.coordinate.latitude, long: pin.coordinate.longitude)) { (photolocation, error) in
         guard let photolocation = photolocation else {
            print(error!)
            return
         }
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
