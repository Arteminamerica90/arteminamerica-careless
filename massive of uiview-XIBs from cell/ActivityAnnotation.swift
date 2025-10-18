// Файл: ActivityAnnotation.swift (НОВЫЙ ФАЙЛ)
import MapKit

class ActivityAnnotation: NSObject, MKAnnotation {
    let activity: GroupActivity
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(activity: GroupActivity) {
        self.activity = activity
        self.coordinate = CLLocationCoordinate2D(latitude: activity.latitude, longitude: activity.longitude)
        self.title = activity.title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        self.subtitle = "Starts at \(formatter.string(from: activity.startTime))"
        
        super.init()
    }
}
