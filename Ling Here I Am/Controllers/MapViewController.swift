//
//  MapViewController.swift
//  Ling Here I Am
//
//  Created by Potchara Puttawanchai on 26/4/2561 BE.
//  Copyright © 2561 Potchara Puttawanchai. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps

class MapViewController: UIViewController {
    
    // MARK: - Variables
    
    // MARK: -- Models
    
    var myLocation = UserLocation()
    var othersLocationCollection = UsersLocationCollection()
    
    // MARK: -- Locations
    
    var locationManager = CLLocationManager()
    var isSetCurrentLocationOnDidLoad = false
    
    // MARK: -- UI helpers
    
    var isLaunchedUpdateUIAfterLogOut = false
    var isLaunchedUpdateUIAfterLogIn = false
    
    // MARK: -- Timers
    
    var updateMySharedLocationTimer: Timer?
    var fetchOthersSharedLocationTimer: Timer?
    var delayPlayingTimer: Timer?
    
    // MARK: -- Firebase
    
    var fsRef: Firestore!
    
    // MARK: - Variables : Storyboard UI

    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var authStackView: UIStackView!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var togglePlayStopButton: UIButton!
    
    // MARK: - Constants
    
    let defaultCoordinate = CLLocationCoordinate2DMake(13.973459, 100.586262)
    let defaultZoom: Float = 16.0
    
    let refreshLocationInterval = 30.0
    let delayPlayingInterval = 2.5
    
    // MARK: - Functions : Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup location manager
        initLocationManager()
        
        // Setup Google Maps view
        setupMapView()
        
        // Setup UI
        if self.isLaunchedUpdateUIAfterLogIn {
            updateUIAfterLogIn()
        }
        else if self.isLaunchedUpdateUIAfterLogOut {
            updateUIAfterLogOut()
        }
        
        // Firebase init
        self.fsRef = Firestore.firestore()
    }
    
    // MARK: - Functions : Storyboard UI actions
    
    @IBAction func togglePlayStopClicked(_ sender: UIButton) {
        if !self.myLocation.isShared {
            self.startPlaying()
        }
        else {
            self.stopPlaying()
        }
    }
    
    @IBAction func logoutClicked(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Firebase : sign out error = \(error.localizedDescription)")
        }
    }
    
    // MARK: - Functions : Firebase
    
    // MARK: -- Reading
    
    @objc func fetchOthersSharedLocation() {
        // Firebase : Get all now-playing users location
        self.fsRef.collection("usersLocation").whereField("isShared", isEqualTo: true).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Firebase : Fetch others location error = \(error.localizedDescription)")
                return
            }
            print("Firebase : Fetch others location completed")
            
            guard let querySnapshot = querySnapshot else { return }
            
            // Add all new others shared location to new array
            var updatedOthersLocationArray = [UserLocation]()
            for docSnapshot in querySnapshot.documents {
                let otherLocation = UserLocation(docSnapshot: docSnapshot)
                
                // Skip appending if this location is my location
                if otherLocation.uid == self.myLocation.uid {
                    continue
                }
                
                updatedOthersLocationArray.append(otherLocation)
            }
            
            // Update others location
            self.othersLocationCollection.updateAll(updatedOthersLocationArray, toMap: self.mapView)
        }
    }
    
    // MARK: -- Writing
    
    @objc func updateMySharedLocation() {
        // Firebase : Update my location, if document exists
        self.fsRef.collection("usersLocation").document(self.myLocation.uid).updateData(self.myLocation.refinedUpdatedSharedUserLocation) { (error) in
            if let error = error {
                // Firebase : Set (add new) my location instead, if document does not exists
                print("Firebase : Update my location error = \(error.localizedDescription)")
                print("Firebase : Then add my location data for the first time")
                self.fsRef.collection("usersLocation").document(self.myLocation.uid).setData(self.myLocation.refinedUpdatedSharedUserLocation)
                return
            }
            print("Firebase : Update my location completed")
        }
    }
    
    func unsetMySharedLocation() {
        self.fsRef.collection("usersLocation").document(self.myLocation.uid).updateData(["isShared": false])
    }
    
    // MARK: - Functions : Location manager
    
    func initLocationManager() {
        self.locationManager = CLLocationManager()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.distanceFilter = 50
        self.locationManager.startUpdatingLocation()
        self.locationManager.delegate = self
    }

    // MARK: - Functions : Google Maps view
    
    func setupMapView() {
        self.mapView.camera = GMSCameraPosition.camera(withTarget: self.defaultCoordinate, zoom: self.defaultZoom)
        self.mapView.mapType = .normal
        self.mapView.isMyLocationEnabled = true
        self.mapView.settings.myLocationButton = true
        self.mapView.settings.compassButton = true
    }
    
    // MARK: - Functions : Update UI
    
    func updateUIAfterLogIn() {
        // Show
        self.logoutButton.isHidden = false
        self.togglePlayStopButton.isHidden = false
        
        // Hide
        self.authStackView.isHidden = true
        
        // Assign
        let user = Auth.auth().currentUser
        self.myLocation.uid = user?.uid ?? ""
        self.myLocation.email = user?.email ?? ""
    }
    
    func updateUIAfterLogOut() {
        // Show
        self.authStackView.isHidden = false
        
        // Hide
        self.logoutButton.isHidden = true
        self.togglePlayStopButton.isHidden = true
        
        // Assign
        self.myLocation.uid = ""
        self.myLocation.email = ""
    }
    
    // MARK: - Functions : Play and Stop
    
    func startPlaying() {
        // Update buttons state
        self.togglePlayStopButton.isEnabled = false
        self.logoutButton.isEnabled = false
        
        // Enable sharing
        self.myLocation.isShared = true
        
        // Update my shared location to Firebase
        // - Immediately for first time
        updateMySharedLocation()
        // - Then, every 30 seconds
        self.updateMySharedLocationTimer = Timer.scheduledTimer(timeInterval: self.refreshLocationInterval, target: self, selector: #selector(updateMySharedLocation), userInfo: nil, repeats: true)
        
        // Delay playing for 2.5 seconds
        // To make sure that any users location data is updated to latest data on Firebase
        self.delayPlayingTimer = Timer.scheduledTimer(withTimeInterval: self.delayPlayingInterval, repeats: false, block: { (timer) in
            // Update buttons state
            self.togglePlayStopButton.setTitle("STOP", for: .normal)
            self.togglePlayStopButton.isEnabled = true
            self.logoutButton.isEnabled = false

            
            // Fetch others location from Firebase
            // - Immediately for first time
            self.fetchOthersSharedLocation()
            // - Then, every 30 seconds
            self.fetchOthersSharedLocationTimer = Timer.scheduledTimer(timeInterval: self.refreshLocationInterval, target: self, selector: #selector(self.fetchOthersSharedLocation), userInfo: nil, repeats: true)
        })
    }
    
    func stopPlaying() {
        // Update buttons state
        self.togglePlayStopButton.setTitle("PLAY", for: .normal)
        self.logoutButton.isEnabled = true
        
        // Disable sharing
        self.myLocation.isShared = false
        
        // Remove all others location
        self.othersLocationCollection.removeAllFromMap()
        
        // Stop all timers
        self.updateMySharedLocationTimer?.invalidate()
        self.fetchOthersSharedLocationTimer?.invalidate()
        self.delayPlayingTimer?.invalidate()
        
        // Unset my shared location to Firebase
        unsetMySharedLocation()
    }
}

// MARK: - Extension : CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location manager : access was restricted.")
        case .denied:
            print("Location manager : user denied access to location.")
        case .notDetermined:
            print("Location manager : status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location manager : status OK.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Update my location coordinate on every update
        self.myLocation.latestCoordinate = location.coordinate
        
        // Set map view position to my location
        // Only first-time start
        if !isSetCurrentLocationOnDidLoad {
            let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: self.defaultZoom)
            self.mapView.animate(to: camera)
            self.isSetCurrentLocationOnDidLoad = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.locationManager.stopUpdatingLocation()
        print("Location manager : Error = \(error.localizedDescription)")
    }
    
}

