import Foundation
import Darwin
internal import Combine


@MainActor
class FindEndpoints: ObservableObject {
    @Published var endpoints: [(ip: String, port: Int, models: [String])] = []
    @Published var isScanning = false
    
    private let ports: [Int] = [7590, 11434, 1234, 8000, 8080, 5000]
    
    func scan(key: String) async {
        guard !isScanning else { return }
        
        isScanning = true
        defer { isScanning = false }
        
        endpoints = []
        
        guard let subnet = currentSubnet() else { return }
        
        await withTaskGroup(of: (String, Int, [String])?.self) { group in
            for host in 1...254 {
                let ip = "\(subnet).\(host)"
                
                for port in ports {
                    group.addTask {
                        await self.check(ip: ip, port: port, key: key)
                    }
                }
            }
            
            for await result in group {
                if let result {
                    endpoints.append((ip: result.0, port: result.1, models: result.2))
                }
            }
            
            endpoints.sort {
                $0.ip == $1.ip ? $0.port < $1.port : $0.ip < $1.ip
            }
        }
    }
    
    private func currentSubnet() -> String? {
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr)}
        
        var ptr = first
        while true {
            let interface = ptr.pointee
            if interface.ifa_addr.pointee.sa_family == UInt8(AF_INET),
                String(cString: interface.ifa_name) == "en0" {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                
                getnameinfo(
                    interface.ifa_addr,
                    socklen_t(interface.ifa_addr.pointee.sa_len),
                    &host,
                    socklen_t(host.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                )
                
                let parts = String(cString: host).split(separator: ".")
                if parts.count == 4 {
                    return "\(parts[0]).\(parts[1]).\(parts[2])"
                }
            }
            
            guard let next = interface.ifa_next else { break }
            ptr = next
        }
        
        return nil
    }
    
    func check(ip: String, port: Int, key: String) async -> (String, Int, [String])? {
        guard let url = URL(string: "http://\(ip):\(port)/v1/models") else { return nil }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        if !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data,response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let items = json?["data"] as? [[String: Any]] ?? []
            let models = items.compactMap { $0["id"] as? String }
            
            return models.isEmpty ? nil : (ip, port, models)
        } catch {
            return nil
        }
    }
}
