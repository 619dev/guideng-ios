import Capacitor
import CoreLocation

class MainViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        super.capacitorDidLoad()
        bridge?.registerPluginType(GuidengLocationPermission.self)
    }
}

@objc(GuidengLocationPermission)
public class GuidengLocationPermission: CAPPlugin, CAPBridgedPlugin, CLLocationManagerDelegate {
    public let identifier = "GuidengLocationPermission"
    public let jsName = "GuidengLocationPermission"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestAlways", returnType: CAPPluginReturnPromise)
    ]

    private var locationManager: CLLocationManager?
    private var pendingCall: CAPPluginCall?
    private var didRequestAlways = false

    @objc func requestAlways(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if self.pendingCall != nil {
                call.reject("Location permission request is already in progress", "IN_PROGRESS")
                return
            }

            let status = CLLocationManager.authorizationStatus()
            if status == .authorizedAlways {
                call.resolve(["status": "authorizedAlways"])
                return
            }

            if status == .denied || status == .restricted {
                call.reject("Location permission has been denied or restricted", "NOT_AUTHORIZED")
                return
            }

            let manager = CLLocationManager()
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager = manager
            self.pendingCall = call
            self.didRequestAlways = false

            if status == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else if status == .authorizedWhenInUse {
                self.didRequestAlways = true
                manager.requestAlwaysAuthorization()
            } else {
                call.reject("Unsupported location authorization status", "NOT_AUTHORIZED")
                self.resetRequest()
            }
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorization(CLLocationManager.authorizationStatus())
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorization(status)
    }

    private func handleAuthorization(_ status: CLAuthorizationStatus) {
        guard let call = pendingCall else {
            return
        }

        switch status {
        case .authorizedAlways:
            call.resolve(["status": "authorizedAlways"])
            resetRequest()
        case .authorizedWhenInUse:
            if didRequestAlways {
                call.resolve(["status": "authorizedWhenInUse"])
                resetRequest()
            } else {
                didRequestAlways = true
                locationManager?.requestAlwaysAuthorization()
            }
        case .denied, .restricted:
            call.reject("Location permission has been denied or restricted", "NOT_AUTHORIZED")
            resetRequest()
        case .notDetermined:
            break
        @unknown default:
            call.reject("Unknown location authorization status", "NOT_AUTHORIZED")
            resetRequest()
        }
    }

    private func resetRequest() {
        locationManager?.delegate = nil
        locationManager = nil
        pendingCall = nil
        didRequestAlways = false
    }
}
