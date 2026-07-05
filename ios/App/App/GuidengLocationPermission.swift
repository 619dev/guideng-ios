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
        CAPPluginMethod(name: "requestWhenInUse", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestAlways", returnType: CAPPluginReturnPromise)
    ]

    private enum RequestKind {
        case whenInUse
        case always
    }

    private var locationManager: CLLocationManager?
    private var pendingCall: CAPPluginCall?
    private var requestKind: RequestKind?

    @objc func requestWhenInUse(_ call: CAPPluginCall) {
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

            if status == .authorizedWhenInUse {
                call.resolve(["status": "authorizedWhenInUse"])
                return
            }

            if status == .denied || status == .restricted {
                call.reject("Location permission has been denied or restricted", "NOT_AUTHORIZED")
                return
            }

            if status == .notDetermined {
                let manager = self.makeLocationManager(call: call, kind: .whenInUse)
                manager.requestWhenInUseAuthorization()
            } else {
                call.reject("Unsupported location authorization status", "NOT_AUTHORIZED")
                self.resetRequest()
            }
        }
    }

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

            let manager = self.makeLocationManager(call: call, kind: .always)
            manager.requestAlwaysAuthorization()
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorization(CLLocationManager.authorizationStatus())
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorization(status)
    }

    private func handleAuthorization(_ status: CLAuthorizationStatus) {
        guard let call = pendingCall, let kind = requestKind else {
            return
        }

        switch status {
        case .authorizedAlways:
            call.resolve(["status": "authorizedAlways"])
            resetRequest()
        case .authorizedWhenInUse:
            if kind == .whenInUse {
                call.resolve(["status": "authorizedWhenInUse"])
                resetRequest()
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
        requestKind = nil
    }

    private func makeLocationManager(call: CAPPluginCall, kind: RequestKind) -> CLLocationManager {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        locationManager = manager
        pendingCall = call
        requestKind = kind
        return manager
    }
}
