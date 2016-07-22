import Foundation

class Delay {

    static let Login: Double = 1.0
    static let Logout: Double = 1.0

    static func run(seconds: Double, withCompletion: () -> Void) {
        let delay = seconds * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            withCompletion()
        }
    }

}
