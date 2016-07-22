import UIKit
import MobileCoreServices
import MapKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import imglyKit

class HomeViewController: CommonViewController, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UINavigationControllerDelegate {

    // MARK: @IBOutlet

    @IBOutlet weak var locationSearchField: SearchTextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationIconView: MenuIconView!
    @IBOutlet weak var rankIconView: MenuIconView!
    @IBOutlet weak var cameraIconView: MenuIconView!
    @IBOutlet weak var peopleIconView: MenuIconView!
    @IBOutlet weak var settingsIconView: MenuIconView!

    // MARK: Local Variables

    var photoViewController: PhotoViewController!
    var timelineViewController: TimelineViewController!
    var postDetailView: PostDetailViewController!
    var personView: PersonViewController!

    var locationManager: CLLocationManager!
    var current_lat: CLLocationDegrees!
    var current_lon: CLLocationDegrees!
    var current_cell_lat: CLLocationDegrees!
    var current_cell_lon: CLLocationDegrees!
    var centered_once: Bool!
    var center_lat: CLLocationDegrees!
    var center_lon: CLLocationDegrees!

    var mapCells: MapCellStore!
    var posts: PostStore!
    var nonCurrentLocationOverlays: [MKOverlay]!
    var currentLocationOverlay: MKOverlay?
    var selectedPostRegion: MKCoordinateRegion!

    var zoom_multiplier: Double!

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Init vars
        self.centered_once = false
        self.locationManager = CLLocationManager()

        // Assign delegates
        self.mapView.delegate = self
        self.locationManager.delegate = self
        self.locationManager.distanceFilter = 50.0
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;

        // Create data stores
        self.mapCells = MapCellStore()
        self.nonCurrentLocationOverlays = [MKOverlay]()
        self.posts = PostStore()

        // Set default settings
        self.mapView.rotateEnabled = false
        self.mapView.pitchEnabled = false
        self.zoom_multiplier = 1.0

        // Create temp dir for photo S3 upload
        self.createUploadTempFolder()

        // Check user exists
        self.checkCurrentUser()

        // Check user settings
        self.checkUserSettings()

        // Check push notification
        self.checkPushNotification()

        // Setup tap handlers
        self.setupTapHandlers()

        // Setup search field delegate
        self.locationSearchField.delegate = self
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        SpinnerView.hide()

        // Check user exists
        self.checkCurrentUser()

        if CLLocationManager.locationServicesEnabled() {
            // Start updating location
            self.locationAuthStatus()
        } else {
            // Location GPS not available
            self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_LOCATION_SERVICE_DISABLED)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        SpinnerView.hide()

        // Stop updating location if view goes away
        self.locationManager.stopUpdatingLocation()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? PhotoViewController where segue.identifier == SEGUE_CAMERA {
            self.photoViewController = vc
            vc.parentView = self
        } else if let vc = segue.destinationViewController as? TimelineViewController where segue.identifier == SEGUE_TIMELINE {
            self.timelineViewController = vc
            vc.parentView = self
            vc.region = self.selectedPostRegion
        } else if let vc = segue.destinationViewController as? PostDetailViewController where segue.identifier == SEGUE_POST_DETAIL {
            self.postDetailView = vc
            vc.homeParentView = self
            vc.post = sender as! Post
        } else if let vc = segue.destinationViewController as? PersonViewController where segue.identifier == SEGUE_PERSON {
            self.personView = vc
            vc.parentView = self
            vc.person = sender as! User
        }
    }

    // MARK: @IBAction

    func locationIconTapHandler(gesture: UIGestureRecognizer) -> Void {
        if let lat = self.current_lat, let lon = self.current_lon {
            let location = CLLocation(latitude: lat, longitude: lon)
            if CLLocationCoordinate2DIsValid(location.coordinate) {
                // Center map on current location
                let currentLocation = CLLocation(latitude: lat, longitude: lon)
                self.centerMapOnLocation(currentLocation)
            } else {
                // User location not yet available
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_LOCATION_UNAVAILABLE)
            }
        } else {
            // User location not yet available
            self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_LOCATION_UNAVAILABLE)
        }
    }

    func rankIconTapHandler(gesture: UIGestureRecognizer) -> Void {
        self.performSegueWithIdentifier(SEGUE_RANKING, sender: self)
    }

    func cameraIconTapHandler(gesture: UIGestureRecognizer) -> Void {
        self.performSegueWithIdentifier(SEGUE_CAMERA, sender: self)
    }

    func peopleIconTapHandler(gesture: UIGestureRecognizer) -> Void {
        performSegueWithIdentifier(SEGUE_PEOPLE, sender: self)
    }

    func settingsIconTapHandler(gesture: UIGestureRecognizer) -> Void {
        performSegueWithIdentifier(SEGUE_SETTINGS, sender: self)
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        if let criteria = textField.text {
            let address = criteria.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            if address != "" {
                let geocoder = CLGeocoder()
                geocoder.geocodeAddressString(address, completionHandler: {
                    (placemarks, error) -> Void in
                    if error != nil {
                        self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_LOCATION_NOT_FOUND)
                    } else {
                        if let placemark = placemarks?.first {
                            if let addrList = placemark.addressDictionary?["FormattedAddressLines"] as? [String] {
                                let address =  addrList.joinWithSeparator(", ")
                                self.locationSearchField.text = address
                            }

                            let coordinate = placemark.location!.coordinate
                            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                            self.centerMapOnLocation(location)
                        } else {
                            self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_LOCATION_NOT_FOUND)
                        }
                    }
                })
            } else {
                self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: ALERT_MESSAGE_LOCATION_MISSING_CRITERIA)
            }
        }

        return true
    }

    // MARK: CLLocationManagerDelegate

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations[0] as CLLocation? {
            // Update user location in Firebase
            GfireDataService.ds.setUserLocation(location, forKey: self.user.uid, withCompletionBlock: {
                (error) in
            })

            // When user location updated, re-center map and draw grid overlay
            if (!self.centered_once) {
                self.centerMapOnLocation(location)
                self.centered_once = true
            }

            // Set zoom multiplier
            self.setZoomMultiplier()

            // Set as current position
            self.current_lat = location.coordinate.latitude
            self.current_lon = location.coordinate.longitude

            // Find root coord of current cell
            self.current_cell_lat = MapUtil.nearestGridLatitude(self.current_lat, offset: MAP_OFFSET_LAT)
            self.current_cell_lon = MapUtil.nearestGridLongitude(self.current_lon, offset: MAP_OFFSET_LON)

            // Draw grid
            self.drawCurrentLocation()
        }
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        // Stop location service on error
        // self.showAlert(ALERT_MESSAGE_TITLE_ERROR, msg: error.description)
    }

    // MARK: MKMapViewDelegate

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if self.center_lat ==  nil && self.center_lon == nil {
            // Initialize value if first time
            self.center_lat = mapView.centerCoordinate.latitude
            self.center_lon = mapView.centerCoordinate.longitude
        }

        // Set zoom multiplier
        let last_zoom = self.zoom_multiplier
        self.setZoomMultiplier()
        let current_zoom = self.zoom_multiplier

        // Compare distance and only redraw when far enough
        let last_center = CLLocation(latitude: self.center_lat, longitude: self.center_lon)
        let current_center = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        let min_meters = self.zoom_multiplier * (Double(MAP_GRID_WIDTH) / 6) * MAP_OFFSET_LON * MAP_METERS_PER_DEGREE
        let traveled = last_center.distanceFromLocation(current_center)

        if traveled >= min_meters || self.mapCells.store.count == 0 || last_zoom != current_zoom {
            // Set current center coordinate
            self.center_lat = mapView.centerCoordinate.latitude
            self.center_lon = mapView.centerCoordinate.longitude

            // Clear overlays and map cells
            self.clearMap()

            // Fetch posts
            self.posts.clear()
            self.fetchPosts(CLLocation.init(latitude: self.mapView.centerCoordinate.latitude, longitude: self.mapView.centerCoordinate.longitude))

            // Draw grid
            self.drawCurrentLocation()
        } else if self.mapView.camera.altitude >= MAP_MAX_ALTITUDE * 2 {
            // Clear overlays and map cells
            self.clearMap()
        }
    }

    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolygon {
            let polygon = overlay as! MKPolygon
            let polygonView = MKPolygonRenderer(overlay: polygon)

            // Old logic for current cell: self.isCurrentLocationOverlay(polygon)
            if let currentOverlay = self.currentLocationOverlay where currentOverlay === overlay {
                // If current position in current cell, highlight
                polygonView.strokeColor = CustomColor.MAP_CELL_CURRENT_BORDER
                //polygonView.fillColor = CustomColor.MAP_CELL_CURRENT
                polygonView.lineWidth = CGFloat(1.6 / self.zoom_multiplier)
                polygonView.alpha = 1.0
            } else {
                polygonView.strokeColor = CustomColor.MAP_CELL_BLUE_BORDER
                polygonView.fillColor = CustomColor.MAP_CELL_BLUE
                polygonView.lineWidth = CGFloat(0.4 / self.zoom_multiplier)
                polygonView.alpha = 0.8
            }

            return polygonView
        } else {
            return MKOverlayRenderer()
        }
    }

    // MARK: Helpers

    func dismissImageEditorAndLoadTimeline(location: CLLocation) {
        self.dismissViewControllerAnimated(true, completion: {
            // Set region location for timeline
            let lat = MapUtil.nearestGridLatitude(location.coordinate.latitude, offset: MAP_OFFSET_LAT)
            let lon = MapUtil.nearestGridLongitude(location.coordinate.longitude, offset: MAP_OFFSET_LON)
            let span = MKCoordinateSpanMake(MAP_OFFSET_LAT, MAP_OFFSET_LON)
            let coordinate = CLLocationCoordinate2DMake(lat - MAP_OFFSET_LAT / 2, lon + MAP_OFFSET_LON / 2)
            self.selectedPostRegion = MKCoordinateRegionMake(coordinate, span)

            // Segue to posts view and set region
            self.performSegueWithIdentifier(SEGUE_TIMELINE, sender: self)
        })
    }

    func handlePolygonTap(gesture: UIGestureRecognizer) -> Void {
        let tapPoint = gesture.locationInView(self.mapView)
        let coordinate = self.mapView.convertPoint(tapPoint, toCoordinateFromView: self.mapView)
        let mapPoint = MKMapPointForCoordinate(coordinate)
        let mapRect = MKMapRectMake(mapPoint.x, mapPoint.y, 0.0, 0.0)

        let lat = MapUtil.nearestGridLatitude(coordinate.latitude, offset: MAP_OFFSET_LAT)
        let lon = MapUtil.nearestGridLongitude(coordinate.longitude, offset: MAP_OFFSET_LON)

        for overlay in self.mapView.overlays {
            if overlay.isKindOfClass(MKPolygon.classForCoder()) {
                let polygon = overlay as! MKPolygon
                if polygon.intersectsMapRect(mapRect) {
                    let span = MKCoordinateSpanMake(MAP_OFFSET_LAT, MAP_OFFSET_LON)
                    let coordinate = CLLocationCoordinate2DMake(lat - MAP_OFFSET_LAT / 2, lon + MAP_OFFSET_LON / 2)
                    self.selectedPostRegion = MKCoordinateRegionMake(coordinate, span)

                    // Segue to posts view and set region
                    self.performSegueWithIdentifier(SEGUE_TIMELINE, sender: self)
                }
            }
        }
    }

    func setupTapHandlers() -> Void {
        let polygonTap = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.handlePolygonTap(_:)))
        polygonTap.cancelsTouchesInView = false
        polygonTap.numberOfTapsRequired = 1
        self.mapView.addGestureRecognizer(polygonTap)

        // Setup location icon tap
        let locationIconTap = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.locationIconTapHandler(_:)))
        self.locationIconView.addGestureRecognizer(locationIconTap)
        self.locationIconView.userInteractionEnabled = true

        // Setup rank icon tap
        let rankIconTap = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.rankIconTapHandler(_:)))
        self.rankIconView.addGestureRecognizer(rankIconTap)
        self.rankIconView.userInteractionEnabled = true

        // Setup camera icon tap
        let cameraIconTap = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.cameraIconTapHandler(_:)))
        self.cameraIconView.addGestureRecognizer(cameraIconTap)
        self.cameraIconView.userInteractionEnabled = true

        // Setup people icon tap
        let peopleIconTap = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.peopleIconTapHandler(_:)))
        self.peopleIconView.addGestureRecognizer(peopleIconTap)
        self.peopleIconView.userInteractionEnabled = true

        // Setup settings icon tap
        let settingsIconTap = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.settingsIconTapHandler(_:)))
        self.settingsIconView.addGestureRecognizer(settingsIconTap)
        self.settingsIconView.userInteractionEnabled = true
    }

    func clearMap() -> Void {
        self.mapCells.clear()
        self.mapView.removeOverlays(self.nonCurrentLocationOverlays)
        self.nonCurrentLocationOverlays.removeAll()
    }

    func isCurrentLocationOverlay(polygon: MKPolygon) -> Bool {
        // Normalize polygon coordinate
        let lat = MapUtil.nearestGridLatitude(polygon.coordinate.latitude, offset: MAP_OFFSET_LAT)
        let lon = MapUtil.nearestGridLongitude(polygon.coordinate.longitude, offset: MAP_OFFSET_LON)

        if self.current_cell_lat != nil && self.current_cell_lon != nil {
            if  Validation.doubleEqual(lat, b: self.current_cell_lat, epsilon: MAP_DOUBLE_EPSILON) &&
                Validation.doubleEqual(lon, b: self.current_cell_lon, epsilon: MAP_DOUBLE_EPSILON) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    func locationAuthStatus() -> Void {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            // Location GPS authorized
            self.locationManager.distanceFilter = 10.0;
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
        } else {
            // Ask for Location GPS permission
            locationManager.requestWhenInUseAuthorization()

            // Location GPS authorized
            self.locationManager.distanceFilter = 10.0;
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
        }
    }

    func centerMapOnLocation(location: CLLocation) -> Void {
        // Shift up map by 1 offsets to compensate menu
        let adjustedLocation = CLLocationCoordinate2DMake(location.coordinate.latitude - MAP_OFFSET_LAT * self.zoom_multiplier / 4, location.coordinate.longitude)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(adjustedLocation, MAP_RADIUS, MAP_RADIUS)
        self.mapView.setRegion(coordinateRegion, animated: true)
    }

    func drawCurrentLocation() -> Void {
        if let lat = self.current_lat, let lon = self.current_lon {
            // Draw cell based on current location
            let cell_lat = MapUtil.nearestGridLatitude(lat, offset: MAP_OFFSET_LAT)
            let cell_lon = MapUtil.nearestGridLongitude(lon, offset: MAP_OFFSET_LON)
            let cell = MapCell(lat: cell_lat, lon: cell_lon)

            // Clear old overlay
            if let currentOverlay = self.currentLocationOverlay {
                self.mapView.removeOverlay(currentOverlay)
            }

            // Store reference and load new overlay
            self.currentLocationOverlay = MapUtil.generatePolygon(cell, lat_offset: MAP_OFFSET_LAT, lon_offset: MAP_OFFSET_LON)
            self.mapView.addOverlay(currentLocationOverlay!)
        }
    }

    func fetchPosts(location: CLLocation) -> Void {
        if self.mapView.camera.altitude < MAP_MAX_ALTITUDE * 2 {
            let lat_span = (Double(MAP_GRID_HEIGHT) / 2) * MAP_OFFSET_LAT * self.zoom_multiplier
            let lon_span = (Double(MAP_GRID_WIDTH) / 2) * MAP_OFFSET_LON * self.zoom_multiplier
            let span = MKCoordinateSpan(latitudeDelta: lat_span, longitudeDelta: lon_span)
            let coordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
            let region = MKCoordinateRegion(center: coordinate, span: span)

            GfireDataService.ds.queryPostsWithRegion(region, withCompletionBlock: {
                (key, location) in
                // Draw cell
                let cell_lat = MapUtil.nearestGridLatitude(location.coordinate.latitude, offset: MAP_OFFSET_LAT)
                let cell_lon = MapUtil.nearestGridLongitude(location.coordinate.longitude, offset: MAP_OFFSET_LON)
                let cell = MapCell(lat: cell_lat, lon: cell_lon)

                if self.mapCells.addMapCell(cell) {
                    let overlay = MapUtil.generatePolygon(cell, lat_offset: MAP_OFFSET_LAT, lon_offset: MAP_OFFSET_LON)
                    self.nonCurrentLocationOverlays.append(overlay)
                    self.mapView.addOverlay(overlay)
                }
            })
        }
    }

    func drawBoxAroundLocation(location: CLLocation) -> Void {
        if self.mapView.camera.altitude < MAP_MAX_ALTITUDE * 2 {
            // Find root coord of grid
            let grid_root_lat = MapUtil.nearestGridLatitude(location.coordinate.latitude, offset: MAP_OFFSET_LAT) + (Double(MAP_GRID_HEIGHT) / 2) * MAP_OFFSET_LAT * self.zoom_multiplier
            let grid_root_lon = MapUtil.nearestGridLongitude(location.coordinate.longitude, offset: MAP_OFFSET_LON) - (Double(MAP_GRID_WIDTH) / 2) * MAP_OFFSET_LON * self.zoom_multiplier

            // Store new cells to draw
            let addedMapCells = MapCellStore()

            // Iterate build cells and store
            for i in 0...MAP_GRID_HEIGHT {
                let east = Double(i)
                for j in 0...MAP_GRID_WIDTH {
                    let south = Double(j)

                    // Add cell to cell array
                    let mapCell = MapCell(lat: grid_root_lat - (east * MAP_OFFSET_LAT * self.zoom_multiplier), lon: grid_root_lon + (south * MAP_OFFSET_LON * self.zoom_multiplier))

                    // If new to map cells then add to update
                    if self.mapCells.addMapCell(mapCell) {
                        addedMapCells.addMapCell(mapCell)
                    }
                }
            }

            // Add overlays to map
            self.mapView.addOverlays(addedMapCells.getPolygonsForCells(MAP_OFFSET_LAT * self.zoom_multiplier, lon_offset: MAP_OFFSET_LON * self.zoom_multiplier))
        }
    }

    func redrawMapCellOverlays() {
        self.mapView.removeOverlays(self.mapView.overlays)
        self.mapView.addOverlays(self.mapCells.getPolygonsForCells(MAP_OFFSET_LAT, lon_offset: MAP_OFFSET_LON))
    }

    func setZoomMultiplier() {
        // Only apply overlays within max zoom
        if self.mapView.camera.altitude >= MAP_MAX_ALTITUDE {
            self.zoom_multiplier = 2.0
        } else {
            self.zoom_multiplier = 1.0
        }
    }

    func createUploadTempFolder() -> Void {
        do {
            try NSFileManager.defaultManager().createDirectoryAtURL(
                NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(AWS_S3_UPLOAD_TEMP_FOLDER),
                withIntermediateDirectories: true,
                attributes: nil)
        } catch _ as NSError {
            //print("Creating 'upload' directory failed. Error: \(error)")
        }
    }

}
