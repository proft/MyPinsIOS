//
//  ViewController.swift
//  MyPins
//
//  Created by Ivan Morgun on /2910/20.
//

import UIKit
import GoogleMaps
import CoreLocation
import RealmSwift
import GeoQueries

class MapViewController: UIViewController {
    var mapView: GMSMapView!
    var myMarker: GMSMarker?
    var markers = [Pin]()
    let center = CLLocationCoordinate2D(latitude: 50.401699, longitude: 30.252512)
    
    let locationManager = CLLocationManager()
    let realm = try! Realm()
    var searchButton: UIBarButtonItem!
    var isSearchMode = false {
        didSet {
            overallStackView.isHidden = !isSearchMode
            if isSearchMode {
                searchButton.tintColor = .red
            } else {
                searchButton.tintColor = .systemBlue
            }
        }
    }
    
    let radiusTF: UITextField = {
        let v = UITextField()
        v.placeholder = "Radius in meters"
        v.backgroundColor = UIColor(white: 0, alpha: 0.03)
        v.borderStyle = .roundedRect
        v.font = UIFont.systemFont(ofSize: 14)
        v.keyboardType = .numberPad
        v.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return v
    }()
    
    let goButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("GO", for: .normal)
        v.backgroundColor = UIColor(red: 149/255, green: 204/255, blue: 244/255, alpha: 1)
        v.layer.cornerRadius = 5
        v.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        v.setTitleColor(.white, for: .normal)
        v.addTarget(self, action: #selector(handleGoSearch), for: .touchUpInside)
        return v
    }()
    
    lazy var overallStackView = UIStackView(arrangedSubviews: [
        radiusTF, goButton
    ])
    
    @objc func handleTextInputChange() {
        UserData.searchRadius = Int(radiusTF.text ?? "") ?? 1000
    }
    
    @objc func handleGoSearch() {
        self.view.endEditing(true)
        fetchPins()
    }

    fileprivate func setupMapView() {
        let camera = GMSCameraPosition.camera(withLatitude: center.latitude, longitude: center.longitude, zoom: 9.0)
        mapView = GMSMapView.map(withFrame: self.view.frame, camera: camera)
        mapView.delegate = self
        view.addSubview(mapView)
    }
    
    fileprivate func setupNavigationBar() {
        navigationItem.title = "My Pins"
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"),  style: .plain, target: self, action: #selector(handleSettings))
        searchButton = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"),  style: .plain, target: self, action: #selector(handleSearch))
        
        navigationItem.rightBarButtonItems = [settingsButton, searchButton]
    }
    
    fileprivate func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        checkLocationAutorization()
    }
    
    fileprivate func setupSearch() {
        overallStackView.distribution = .fillProportionally
        overallStackView.axis = .horizontal
        overallStackView.spacing = 8
        overallStackView.isHidden = true
        view.addSubview(overallStackView)
        overallStackView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 16, left: 8, bottom: 0, right: 8))
        radiusTF.text = String(UserData.searchRadius)
        goButton.constrainWidth(44)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView()
        setupLocationManager()
        setupNavigationBar()
        setupSearch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPins()
    }
    
    @objc func handleSettings() {
        let vc = SettingsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func handleSearch() {
        isSearchMode.toggle()
    }
    
    func fetchPins() {
        if !markers.isEmpty {
            markers.removeAll()
            mapView.clear()
        }
        
        if isSearchMode {
            let radius = Double(radiusTF.text ?? "") ?? 1000.0
            markers = try! Realm().findNearby(type: Pin.self, origin: mapView.camera.target, radius: radius, sortAscending: true)
            for pin in markers {
                addMarker(title: pin.title, coordinate: CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.lng), color: pin.color)
            }
        } else {
            markers = realm.objects(Pin.self).map({$0})
            markers.forEach { (pin) in
                addMarker(title: pin.title, coordinate: CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.lng), color: pin.color)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationManager.stopUpdatingLocation()
    }
    
    func saveMarker(title: String, coordinate: CLLocationCoordinate2D, color: String) {
        let pin = Pin()
        pin.title = title
        pin.lat = coordinate.latitude
        pin.lng = coordinate.longitude
        pin.color = color
        try! realm.write {
            realm.add(pin)
        }
        
        markers.append(pin)
    }
    
    func addMarker(title: String, coordinate: CLLocationCoordinate2D, color: String) {
        let marker = GMSMarker()
        marker.position = coordinate
        marker.title = title
        marker.appearAnimation = .pop
        marker.icon = GMSMarker.markerImage(with: UIColor(hex: color))
        marker.map = mapView
    }
    
    func startLocation() {
        locationManager.startUpdatingLocation()

        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    func checkLocationAutorization(){
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            if (mapView.isMyLocationEnabled == false ){
                startLocation()
            }
            break
        case .denied:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            break
        case .authorizedAlways:
            break
        default:
            break
        }
    }
    
}

extension MapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        self.view.endEditing(true)
        let title = "Pin \(markers.count)"
        
        saveMarker(title: title, coordinate: coordinate, color: UserData.pinColor)
        addMarker(title: title, coordinate: coordinate, color: UserData.pinColor)
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        if isSearchMode {
            fetchPins()
        }
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else { return }
        startLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        let loc = location.coordinate
        
        if myMarker != nil {
            myMarker?.position = loc
        } else {
            myMarker = GMSMarker(position: loc)
            myMarker!.title = "You are here"
            myMarker!.icon = GMSMarker.markerImage(with: UIColor(hex: "#41c300"))
            myMarker!.map = mapView
            mapView.camera = GMSCameraPosition(target: loc, zoom: 15, bearing: 0, viewingAngle: 0)
        }
    }
}

