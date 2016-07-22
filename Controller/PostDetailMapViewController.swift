import UIKit
import MapKit
import Haneke

class PostDetailMapViewController: CommonViewController, MKMapViewDelegate {

    // MARK: @IBOutlet

    @IBOutlet weak var mapView: MKMapView!

    // MARK: Local Variables

    var post: Post!
    var location: CLLocation!
    var postDetailViewController: PostDetailViewController!

    // MARK: Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check user exists
        self.checkCurrentUser()

        // Check user settings
        self.checkUserSettings()

        // Assign delegates
        self.mapView.delegate = self

        // Set default settings
        self.mapView.rotateEnabled = false
        self.mapView.pitchEnabled = false
        self.mapView.zoomEnabled = false
        self.mapView.scrollEnabled = false
        self.mapView.userInteractionEnabled = false

        // Center map
        self.centerMapOnLocation(self.location)

        // Add annocation
        self.addPostLocationAnnotation(self.location)
    }

    // MARK: @IBAction

    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func goButtonPressed(sender: UIBarButtonItem) {
        self.gotoHomeView(self.location)
    }

    // MARK: MKMapViewDelegate

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKindOfClass(MKUserLocation.classForCoder()) {
            return nil
        }

        if annotation.isKindOfClass(MKPointAnnotation.classForCoder()) {
            var pinView = self.mapView.dequeueReusableAnnotationViewWithIdentifier("postPin")
            if pinView == nil {
                pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: "postPin")
                pinView?.canShowCallout = false
                pinView?.image = UIImage(named: "Icon-MapPin")
                pinView?.centerOffset = CGPointMake(0, -25)
            } else {
                pinView?.annotation = annotation
            }

            return pinView
        }

        return nil
    }

    // MARK: Helpers

    func centerMapOnLocation(location: CLLocation) -> Void {
        // Shift up map by 1 offsets to compensate menu
        let adjustedLocation = CLLocationCoordinate2DMake(location.coordinate.latitude - MAP_OFFSET_LAT / 4, location.coordinate.longitude)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(adjustedLocation, MAP_RADIUS, MAP_RADIUS)
        self.mapView.setRegion(coordinateRegion, animated: true)
    }

    func addPostLocationAnnotation(location: CLLocation) -> Void {
        let postPin = MKPointAnnotation()
        postPin.coordinate = CLLocationCoordinate2DMake(self.location.coordinate.latitude, self.location.coordinate.longitude)
        self.mapView.addAnnotation(postPin)
    }
}
