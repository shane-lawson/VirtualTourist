//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 4/30/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource {

   @IBOutlet weak var collectionView: UICollectionView!
   
   var photoLocations: [PhotoResponse]!
   var photos = [UIImage]()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      // Do any additional setup after loading the view.
      
      FlickrAPI.searchForPhotos(at: (lat: 43.5, long: -96.7)) { (photoLocations, error) in
         guard error == nil else { print(error!); return }
         self.photoLocations = photoLocations
         photoLocations.forEach {
            FlickrAPI.downloadPhoto($0, completionHandler: self.handlePhotoDownload(data:error:))
         }
      }
      collectionView.dataSource = self
   }
   
   func handlePhotoDownload(data: Data?, error: Error?) {
      guard let data = data else { print(error!); return }
      if let image = UIImage(data: data) {
         photos.append(image)
//         collectionView.reloadItems(at: [IndexPath(item: photos.endIndex, section: 0)])
         collectionView.reloadData()
      }
   }
}

// MARK: - UICollectionViewDataSource

extension ViewController {
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
