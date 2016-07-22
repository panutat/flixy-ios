import Foundation
import AWSCore
import AWSSNS

class AWSSNSService {

    static func sendNotification(target: User, message: String, payload: Dictionary<String, String>) -> Void {
        if target.endpointArn != "" {
            do {
                // Parse payload
                let payloadData = try NSJSONSerialization.dataWithJSONObject(payload, options: NSJSONWritingOptions.PrettyPrinted)
                var payloadStr = NSString(data: payloadData, encoding: NSUTF8StringEncoding) as? String
                payloadStr = payloadStr!.stringByReplacingOccurrencesOfString("\n", withString: "")

                // Build message
                let dictionary = ["default": message, "APNS_SANDBOX": "{\"payload\": \(payloadStr!), \"aps\": {\"alert\": \"\(message)\", \"sound\": \"default\", \"badge\": \(1), \"category\": \"MESSAGE_CATEGORY\"} }"]
                let jsonData = try NSJSONSerialization.dataWithJSONObject(dictionary, options: NSJSONWritingOptions.PrettyPrinted)

                // Publish message
                let sns = AWSSNS.defaultSNS()
                let notification = AWSSNSPublishInput()
                notification.messageStructure = "json"
                notification.message = NSString(data: jsonData, encoding: NSUTF8StringEncoding) as? String
                notification.targetArn = target.endpointArn
                sns.publish(notification).continueWithBlock({
                    (task) -> AnyObject? in
                    return nil
                })
            } catch {
                print("Error: ", error)
            }
        }
    }

}
