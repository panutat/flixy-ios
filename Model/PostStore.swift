import Foundation
import MapKit

class PostStore {

    private var _store: [Post]

    var store: [Post] {
        get {
            return _store
        }
    }

    init() {
        self._store = [Post]()
    }

    func addPost(post: Post) -> Void {
        self._store.append(post)
    }

    func clear() {
        self._store = [Post]()
    }

    func isEmpty() -> Bool {
        return (self._store.count == 0)
    }

}
