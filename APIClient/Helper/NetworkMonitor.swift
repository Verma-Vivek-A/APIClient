//
//  NetworkMonitor.swift
//  APIClient
//
//  Created by apple on 03/10/23.
//

import Foundation
import Network

class NetworkMonitor {
    static let shared = NetworkMonitor()

    let monitor = NWPathMonitor()
    private var status: NWPath.Status = .requiresConnection
    var isReachable: Bool { self.status == .satisfied }
    var isReachableOnCellular: Bool = true

//    MARK: To watch specific network
//    public init(requiredInterfaceType: NWInterface.InterfaceType) {
//       _ = self.monitor.currentPath.usesInterfaceType(requiredInterfaceType)
//    }
    
    func startMonitoring() {
        self.monitor.pathUpdateHandler = { [weak self] path in
            self?.status = path.status
            self?.isReachableOnCellular = path.isExpensive
            if path.status == .satisfied {
                if path.isExpensive {
                    print("We're connected over cellular or hotspot")
                } else {
                    print("We're connected!")
                }
            } else {
                print("No connection.")
            }
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        self.monitor.start(queue: queue)
    }

    func stopMonitoring() {
        self.monitor.cancel()
    }
}
