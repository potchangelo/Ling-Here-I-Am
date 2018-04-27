//
//  UsersLocationCollection.swift
//  Ling Here I Am
//
//  Created by Potchara Puttawanchai on 27/4/2561 BE.
//  Copyright © 2561 Potchara Puttawanchai. All rights reserved.
//

import UIKit
import GoogleMaps

class UsersLocationCollection: NSObject {
    
    // MARK: - Variables
    
    var usersLocationArray = [UserLocation]()
    
    // MARK: - Initializer
    
    override init() {}
    
    // MARK: - Functions
    
    func updateAll(_ updatedUsersLocationArray: [UserLocation], toMap mapView: GMSMapView) {
        // MARK: -- Remove from users location array
        // Get removed users location to be in new array
        let removedUsersLocationArray = self.usersLocationArray.filter { (currentUserLocation) -> Bool in
            return !updatedUsersLocationArray.contains(where: { (updatedUserLocation) -> Bool in
                return updatedUserLocation.uid == currentUserLocation.uid
            })
        }
        // Remove, where current.uid == removed.uid
        // Also remove from map
        for removedUserLocation in removedUsersLocationArray {
            let removedIndex = self.usersLocationArray.index { (currentUserLocation) -> Bool in
                return currentUserLocation.uid == removedUserLocation.uid
            }
            if let removedIndex = removedIndex {
                let userLocation = self.usersLocationArray.remove(at: removedIndex)
                userLocation.removeFromMap()
            }
        }
        
        // MARK: -- Update or Add to users location array
        // Update, where current.uid == updated.uid
        // Add, where current.uid != updated.uid
        for updatedUserlocation in updatedUsersLocationArray {
            let existsUserLocation = self.usersLocationArray.first { (currentUserLocation) -> Bool in
                return currentUserLocation.uid == updatedUserlocation.uid
            }
            if let userLocation = existsUserLocation {
                // Exists, then update data & position on map
                userLocation.latestCoordinate = updatedUserlocation.latestCoordinate
                userLocation.updatedAt = updatedUserlocation.updatedAt
                userLocation.updateOnMap()
            }
            else {
                // Not exists, then add new data & position on map
                updatedUserlocation.addToMap(mapView)
                self.usersLocationArray.append(updatedUserlocation)
            }
        }
    }
    
    func removeAllFromMap() {
        // Remove all users location from map
        // Then remove all from users location array
        for userLocation in self.usersLocationArray {
            userLocation.removeFromMap()
        }
        self.usersLocationArray.removeAll()
    }
    
}
