import Foundation
import MapKit

class MapCellStore {

    private var _store: Dictionary<CLLocationDegrees, Dictionary<CLLocationDegrees, MapCell>>

    var store: Dictionary<CLLocationDegrees, Dictionary<CLLocationDegrees, MapCell>> {
        get {
            return _store
        }
    }

    init() {
        self._store = Dictionary<CLLocationDegrees, Dictionary<CLLocationDegrees, MapCell>>()
    }

    func addMapCell(mapCell: MapCell) -> Bool {
        // Check if store has cell lat
        if let lons = self.getLonListForLat(MapUtil.getMapCellStoreKey(mapCell.origin_lat)) {
            // Cell lat has lons so check for cell lon
            if lons[MapUtil.getMapCellStoreKey(mapCell.origin_lon)] != nil {
                // Map cell already instore
                return false
            } else {
                // Add map cell to store
                self._store[MapUtil.getMapCellStoreKey(mapCell.origin_lat)]![MapUtil.getMapCellStoreKey(mapCell.origin_lon)] = mapCell
                return true
            }
        } else {
            // Cell lat does not exist so create new
            self._store[MapUtil.getMapCellStoreKey(mapCell.origin_lat)] = Dictionary<CLLocationDegrees, MapCell>()
            self._store[MapUtil.getMapCellStoreKey(mapCell.origin_lat)]![MapUtil.getMapCellStoreKey(mapCell.origin_lon)] = mapCell
            return true
        }
    }

    func getLonListForLat(lat: CLLocationDegrees) -> Dictionary<CLLocationDegrees, MapCell>? {
        if let lonList = self._store[lat] {
            return lonList
        } else {
            return nil
        }
    }

    func getPolygonsForCells(lat_offset: Double = MAP_OFFSET_LAT, lon_offset: Double = MAP_OFFSET_LON) -> [MKPolygon] {
        var polygons = [MKPolygon]()
        for (_, lons) in self._store {
            for (_, cell) in lons {
                // Add pologon to polygon array
                let polygon = MapUtil.generatePolygon(cell, lat_offset: lat_offset, lon_offset: lon_offset)
                polygons.append(polygon)
            }
        }

        return polygons
    }

    func clear() {
        self._store = Dictionary<CLLocationDegrees, Dictionary<CLLocationDegrees, MapCell>>()
    }

    func isEmpty() -> Bool {
        return (self._store.count == 0)
    }

    func cellCount() -> Int {
        var count: Int = 0

        for (_, lons) in self._store {
            for (_, _) in lons {
                count = count + 1
            }
        }

        return count
    }
}
