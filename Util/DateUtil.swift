import Foundation

class DateUtil {

    static func timeAgo(date: NSDate, numericDates: Bool = true) -> String {
        let calendar = NSCalendar.currentCalendar()
        let now = NSDate()
        let earliest = now.earlierDate(date)
        let latest = (earliest == now) ? date : now
        let components:NSDateComponents = calendar.components([NSCalendarUnit.Minute , NSCalendarUnit.Hour , NSCalendarUnit.Day , NSCalendarUnit.WeekOfYear , NSCalendarUnit.Month , NSCalendarUnit.Year , NSCalendarUnit.Second], fromDate: earliest, toDate: latest, options: NSCalendarOptions())

        if (components.year >= 2) {
            return "\(components.year) yrs ago"
        } else if (components.year >= 1){
            if (numericDates){
                return "1 yr ago"
            } else {
                return "Last yr"
            }
        } else if (components.month >= 2) {
            return "\(components.month) mos ago"
        } else if (components.month >= 1){
            if (numericDates){
                return "1 mo ago"
            } else {
                return "Last mo"
            }
        } else if (components.weekOfYear >= 2) {
            return "\(components.weekOfYear) wks ago"
        } else if (components.weekOfYear >= 1){
            if (numericDates){
                return "1 wk ago"
            } else {
                return "Last wk"
            }
        } else if (components.day >= 2) {
            return "\(components.day) days ago"
        } else if (components.day >= 1){
            if (numericDates){
                return "1 day ago"
            } else {
                return "Yesterday"
            }
        } else if (components.hour >= 2) {
            return "\(components.hour) hrs ago"
        } else if (components.hour >= 1){
            if (numericDates){
                return "1 hr ago"
            } else {
                return "An hr ago"
            }
        } else if (components.minute >= 2) {
            return "\(components.minute) mins ago"
        } else if (components.minute >= 1){
            if (numericDates){
                return "1 min ago"
            } else {
                return "A min ago"
            }
        } else if (components.second >= 3) {
            return "\(components.second) secs ago"
        } else {
            return "Just now"
        }

    }

}
