import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

public final class WatchConnectivityManager: NSObject, ObservableObject {
    public static let shared = WatchConnectivityManager()
    
    #if canImport(WatchConnectivity)
    private var session: WCSession?
    #endif
    
    @Published public var isReachable: Bool = false
    
    // Callbacks for receiving data on either side
    public var onWorkoutReceived: ((SyncWorkoutMessage) -> Void)?
    public var onSetCompleted: ((SyncSetCompletionEvent) -> Void)?
    
    private override init() {
        super.init()
        #if canImport(WatchConnectivity)
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        #endif
    }
    
    public func sendWorkoutState(_ message: SyncWorkoutMessage) {
        #if canImport(WatchConnectivity)
        guard let session = session, session.activationState == .activated else { return }
        
        do {
            let data = try JSONEncoder().encode(message)
            
            // If reachable, send immediately. Otherwise update Application Context for later pickup.
            if session.isReachable {
                session.sendMessage(["workoutState": data], replyHandler: nil, errorHandler: { error in
                    print("Failed to send workout state: \(error.localizedDescription)")
                })
            }
            
            try session.updateApplicationContext(["workoutState": data])
        } catch {
            print("Encoding error: \(error)")
        }
        #endif
    }
    
    public func sendSetCompletion(_ event: SyncSetCompletionEvent) {
        #if canImport(WatchConnectivity)
        guard let session = session, session.activationState == .activated else { return }
        
        do {
            let data = try JSONEncoder().encode(event)
            // Send set completions via outstanding UserInfo queue so it reliably delivers offline events
            session.transferUserInfo(["setCompletion": data])
        } catch {
            print("Encoding error: \(error)")
        }
        #endif
    }
}

#if canImport(WatchConnectivity)
extension WatchConnectivityManager: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    // Receive Messages (Realtime)
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncomingData(message)
    }
    
    // Receive Context (Background Sync)
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handleIncomingData(applicationContext)
    }
    
    // Receive UserInfo (Queued offline events)
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleIncomingData(userInfo)
    }
    
    private func handleIncomingData(_ payload: [String: Any]) {
        if let data = payload["workoutState"] as? Data {
            if let message = try? JSONDecoder().decode(SyncWorkoutMessage.self, from: data) {
                DispatchQueue.main.async {
                    self.onWorkoutReceived?(message)
                }
            }
        }
        
        if let data = payload["setCompletion"] as? Data {
            if let event = try? JSONDecoder().decode(SyncSetCompletionEvent.self, from: data) {
                DispatchQueue.main.async {
                    self.onSetCompleted?(event)
                }
            }
        }
    }
}
#endif
