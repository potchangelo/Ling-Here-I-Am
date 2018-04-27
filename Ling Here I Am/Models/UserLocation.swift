//
//  UserLocation.swift
//  Ling Here I Am
//
//  Created by Potchara Puttawanchai on 27/4/2561 BE.
//  Copyright © 2561 Potchara Puttawanchai. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps

class UserLocation: NSObject {
    
    // MARK: - Variables
    
    var uid = ""
    var email = ""
    var latestCoordinate: CLLocationCoordinate2D?
    var isShared = false
    var updatedAt = Date()
    
    // MARK: - Variables : Helpers
    
    // MARK: -- Marker
    
    var marker: GMSMarker?
    
    // MARK: -- Firebase : Writing
    
    var refinedUpdatedSharedUserLocation: [String: Any] {
        var obj = [String: Any]()
        obj["email"] = self.email
        if let coordinate = self.latestCoordinate {
            obj["latestCoordinate"] = GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        obj["isShared"] = self.isShared
        obj["updatedAt"] = Date()
        return obj
    }
    
    // MARK: - Initializer
    
    override init() {}
    
    init(docSnapshot: DocumentSnapshot) {
        super.init()
        guard let obj = docSnapshot.data() else { return }
        self.uid = docSnapshot.documentID
        self.email = obj["email"] as? String ?? ""
        let geopoint = obj["latestCoordinate"] as? GeoPoint
        if let geopoint = geopoint {
            self.latestCoordinate = CLLocationCoordinate2DMake(geopoint.latitude, geopoint.longitude)
        }
        self.isShared = obj["isShared"] as? Bool ?? false
        self.updatedAt = obj["updatedAt"] as? Date ?? Date()
    }
    
    // MARK: - Functions : Marker display
    
    func addToMap(_ mapView: GMSMapView) {
        // Remove first
        removeFromMap()
        
        // Then add new
        guard let latestCoordinate = self.latestCoordinate else { return }
        self.marker = GMSMarker(position: latestCoordinate)
        self.marker?.title = self.email
        self.marker?.map = mapView
    }
    
    func updateOnMap() {
        guard let latestCoordinate = self.latestCoordinate else { return }
        self.marker?.position = latestCoordinate
    }
    
    func removeFromMap() {
        self.marker?.map = nil
    }
    
}
