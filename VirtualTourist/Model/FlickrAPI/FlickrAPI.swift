//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by Shane Lawson on 5/1/20.
//  Copyright © 2020 Shane Lawson. All rights reserved.
//

import Foundation

class FlickrAPI {
   enum Endpoints {
      case base
      case search(Float, Float)
      case source(PhotoResponse)
      
      var stringValue: String {
         switch self {
         case .base:
            return ""
         case .search(let lat, let long):
            return "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(Auth.key)&lat=\(lat)&lon=\(long)&geo_context=2&per_page=30&format=json&nojsoncallback=1"
         case .source(let photo):
            return "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret)_q.jpg"
         }
      }
      
      var url: URL {
         return URL(string: self.stringValue)!
      }
   }
   
   struct Auth {
      // pull in API key from untracked Keys.plist so as to keep API key hidden in public repository
      // Keys.plist contains a single dictionary with keys of "key" and "secret" with String value types containing the API key and secret, respectively.
      private struct CodableAuth: Codable {
         let key: String
         let secret: String
      }
     
      static let (key, secret): (String, String) = {
         let path = Bundle.main.path(forResource: "Keys", ofType: "plist")!
         let data = FileManager.default.contents(atPath: path)!
         let apiObject = try! PropertyListDecoder().decode(CodableAuth.self, from: data)
         return (apiObject.key, apiObject.secret)
      }()
   }
   
   class func searchForPhotos(at location: (lat: Float, long: Float), completionHandler: @escaping ([PhotoResponse], Error?) -> Void) {
      let request = URLRequest(url: Endpoints.search(location.lat, location.long).url)
      URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
         guard let data = data else {
            completionHandler([], error)
            return
         }
         
         do {
            let responseObject = try JSONDecoder().decode(PhotosSearchResponse.self, from: data)
            let photos = [PhotoResponse](responseObject.photos.photo)
            completionHandler(photos, nil)
         } catch {
            do {
               let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
               completionHandler([], errorResponse)
            } catch {
               completionHandler([],error)
            }
         }
      }).resume()
   }
   
   class func downloadPhoto(_ photo: PhotoResponse, completionHandler: @escaping (Data?, Error?) -> Void) {
      let request = URLRequest(url: Endpoints.source(photo).url)
      URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
         guard let data = data else {
            completionHandler(nil, error)
            return
         }
         
         DispatchQueue.main.async {
            completionHandler(data, nil)
         }
      }).resume()
   }
}
