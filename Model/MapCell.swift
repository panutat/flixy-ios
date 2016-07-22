import Foundation
import MapKit

class MapCell {

    private var _origin_lat: CLLocationDegrees
    private var _origin_lon: CLLocationDegrees

    var origin_lat: CLLocationDegrees {
        get {
            return _origin_lat
        }
    }

    var origin_lon: CLLocationDegrees {
        get {
            return _origin_lon
        }
    }

    init(lat: CLLocationDegrees, lon: CLLocationDegrees) {
        self._origin_lat = lat
        self._origin_lon = lon
    }

}
