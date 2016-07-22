import Foundation
import Firebase
import GeoFire

class GfireDataService {

    static let ds = GfireDataService()

    private var _POSTS = GeoFire(firebaseRef: Firebase(url: "\(FBASE_ROOT_URL)/post_locations"))
    private var _USERS = GeoFire(firebaseRef: Firebase(url: "\(FBASE_ROOT_URL)/user_locations"))

    // MARK: Handle post locations

    func addPostLocation(location: CLLocation, forKey: String, withCompletionBlock: ((NSError?) -> Void)!) {
        self._POSTS.setLocation(location, forKey: forKey, withCompletionBlock: {
            (error) in
            withCompletionBlock(error)
        })
    }

    func getPostLocation(forKey: String, withCompletionBlock: ((CLLocation, NSError?) -> Void)!) {
        self._POSTS.getLocationForKey(forKey, withCallback: {
            (location, error) in
            withCompletionBlock(location, error)
        })
    }

    func queryPostsWithRegion(region: MKCoordinateRegion, withCompletionBlock: ((String, CLLocation) -> Void)!) {
        let regionQuery = self._POSTS.queryWithRegion(region)
        regionQuery.observeEventType(GFEventType.KeyEntered, withBlock: {
            (key, location) in
            withCompletionBlock(key, location)
        })
    }

    func queryPostsWithRegionOnce(region: MKCoordinateRegion, withCompletionBlock: ((String, CLLocation) -> Void)!) {
        let regionQuery = self._POSTS.queryWithRegion(region)
        regionQuery.observeEventType(GFEventType.KeyEntered, withBlock: {
            (key, location) in
            withCompletionBlock(key, location)
        })
        regionQuery.observeReadyWithBlock({
            regionQuery.removeAllObservers()
        })
    }

    func deletePostLocation(forKey: String, withCompletionBlock: ((NSError?) -> Void)!) {
        self._POSTS.removeKey(forKey, withCompletionBlock: {
            (error) in
            withCompletionBlock(error)
        })
    }

    // MARK: Handle user locations

    func setUserLocation(location: CLLocation, forKey: String, withCompletionBlock: ((NSError?) -> Void)!) {
        self._USERS.setLocation(location, forKey: forKey, withCompletionBlock: {
            (error) in
            withCompletionBlock(error)
        })
    }

}
