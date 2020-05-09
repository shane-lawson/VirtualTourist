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

   // MARK: IBOutlets
   
   @IBOutlet weak var mapView: MKMapView!
   @IBOutlet weak var collectionView: UICollectionView!
   @IBOutlet weak var newCollectionButton: UIBarButtonItem!
   @IBOutlet weak var noImagesLabel: UILabel!
   
   // MARK: Properties
   
   // injected properties
   var pin: Pin!
   var dataController: DataController!
   
   var fetchedResultsController: NSFetchedResultsController<Photo>!
   
   // MARK: Lifecycle Overrides
   
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
      setupCollectionViewLayout()
   }
   
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      setupFetchedResultsController()
   }
   
   override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      fetchedResultsController = nil
   }
   
   // MARK: IBActions
   
   @IBAction func newCollectionTapped(_ sender: UIBarButtonItem) {
      pin.removeFromPhotos(pin.photos!)
      for _ in 0..<30 {
         let photo = Photo(context: dataController.viewContext)
         pin.addToPhotos(photo)
      }
      try? dataController.viewContext.save()
      getPhotos(at: pin.coordinate)
   }
   
   // MARK: Helpers
   
   fileprivate func getPhotos(at location: CLLocationCoordinate2D) {
      setLoadingNewCollection(true) // UI update
      // get photos from a search querying the latitude and longitude
      FlickrAPI.searchForPhotos(at: (lat: location.latitude, long: location.longitude)) { [unowned self] (photoLocations, error) in
         guard error == nil else { print(error!); return }
         // pass results on to be downloaded
         photoLocations.forEach {
            FlickrAPI.downloadPhoto($0, completionHandler: self.handlePhotoDownload(data:error:))
         }
         // if the location has less than 30 images, clear out collection view items containing placeholders that won't be filled
         if photoLocations.count < 30 {
            let photos = self.performFetch(offset: photoLocations.count)
            photos?.forEach { self.dataController.viewContext.delete($0) }
            // if no photos for location, show label indicating as much
            if photoLocations.count == 0 {
               self.noImagesLabel.isHidden = false
            }
         }
      }
   }
   
   fileprivate func handlePhotoDownload(data: Data?, error: Error?) {
      // turn downloaded data into UIImages
      guard let data = data else { print(error!); return }
      if let image = UIImage(data: data) {
         if let photos = performFetch() {
            if photos.count == 30 {
               // if collectionView is full, insert the downloaded image in the first item containing a placeholder image. This is used when loading the whole collection the first time
               photos.first(where: {$0.isPlaceholderImage})?.image = image
            } else {
               // if collectionView is not full, create a photo with the image, and add it to the pin's collection. This is used to add single photos to the collection when deleting images
               let newPhoto = Photo(context: dataController.viewContext)
               newPhoto.image = image
               pin.addToPhotos(newPhoto)
            }
            try? dataController.viewContext.save()
            // if no placeholder images exist, update UI
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
   
   fileprivate func performFetch(offset: Int? = nil) -> [Photo]? {
      return try? dataController.viewContext.fetch(createFetchRequest(offset))
   }
   
   fileprivate func createFetchRequest(_ offset: Int? = nil) -> NSFetchRequest<Photo> {
      let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
      let predicate = NSPredicate(format: "pin == %@", pin)
      fetchRequest.predicate = predicate
      let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
      fetchRequest.sortDescriptors = [sortDescriptor]
      if let offset = offset {
         fetchRequest.fetchOffset = offset
      }
      return fetchRequest
   }
   
   fileprivate func setupCollectionViewLayout() {
      let spacing: CGFloat = 5
      let width = UIScreen.main.bounds.width
      let layout = UICollectionViewFlowLayout()
      layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: 50, right: spacing)
      let numberOfItems: CGFloat = 3
      let itemSize = (width - (spacing * (numberOfItems+1))) / numberOfItems
      layout.itemSize = CGSize(width: itemSize, height: itemSize)
      layout.minimumInteritemSpacing = spacing
      layout.minimumLineSpacing = spacing
      collectionView.collectionViewLayout = layout
   }
   
   // MARK: - NSFetchedResultsControllerDelegate
   
   // have to batch update collection view, so store blocks to be run after controller changes content
   
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
      // delete selected photo from store
      let photo = fetchedResultsController.object(at: indexPath)
      dataController.viewContext.delete(photo)
      try? dataController.viewContext.save()
      
      // get new random image to repopulate collection view
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
