import Foundation
import MapKit

class MapUtil {

    static func roundToDouble(degrees: CLLocationDegrees) -> Double {
        return round(1000 * degrees) / 1000
    }

    static func getMapCellStoreKey(degrees: CLLocationDegrees) -> Double {
        return round(1000 * degrees)
    }

    static func nearestGridLatitude(lat: CLLocationDegrees, offset: Double) -> Double {
        let nearestLat = lat as Double
        return (nearestLat - ((nearestLat * 100000) % (MAP_OFFSET_LAT * 100000)) / 100000 + offset)
    }

    static func nearestGridLongitude(lon: CLLocationDegrees, offset: Double) -> Double {
        let nearestLon = lon as Double
        return (nearestLon - ((nearestLon * 100000) % (MAP_OFFSET_LON * 100000)) / 100000 - offset)
    }

    static func polygonContainsPoint(polygon: MKPolygonRenderer, lat: CLLocationDegrees, lon: CLLocationDegrees) -> Bool {
        return CGPathContainsPoint(polygon.path, nil, CGPointMake(CGFloat(lat), CGFloat(lon)), true)
    }

    static func generatePolygon(mapCell: MapCell, lat_offset: Double, lon_offset: Double) -> MKPolygon {
        return self.buildPolygonFromCoordinate(mapCell.origin_lat, lon: mapCell.origin_lon, lat_offset: lat_offset, lon_offset: lon_offset)
    }

    static func buildPolygonFromCoordinate(lat: CLLocationDegrees, lon: CLLocationDegrees, lat_offset: Double, lon_offset: Double) -> MKPolygon {
        // Construct and return polygon
        let point1 = CLLocationCoordinate2DMake(lat, lon)
        let point2 = CLLocationCoordinate2DMake(lat, lon + lon_offset)
        let point3 = CLLocationCoordinate2DMake(lat - lat_offset, lon + lon_offset)
        let point4 = CLLocationCoordinate2DMake(lat - lat_offset, lon)
        var points: [CLLocationCoordinate2D] = [point1, point2, point3, point4]
        return MKPolygon(coordinates: &points[0], count: 4)
    }
}
