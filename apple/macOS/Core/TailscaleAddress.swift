import Darwin
import Foundation

enum TailscaleAddress {
    static func isTailscale(_ address: String) -> Bool {
        let parts = address.split(separator: ".").compactMap { Int($0) }
        return parts.count == 4 && parts[0] == 100 && (64...127).contains(parts[1])
    }

    static func find() -> String? {
        interfaceAddresses().first { $0.name.hasPrefix("utun") && isTailscale($0.address) }?.address
    }

    static func interfaceAddresses() -> [(name: String, address: String)] {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0 else { return [] }
        defer { freeifaddrs(head) }
        var found: [(name: String, address: String)] = []
        var cursor = head
        while let entry = cursor {
            cursor = entry.pointee.ifa_next
            guard let socketAddress = entry.pointee.ifa_addr, socketAddress.pointee.sa_family == sa_family_t(AF_INET) else { continue }
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let length = socklen_t(MemoryLayout<sockaddr_in>.size)
            guard getnameinfo(socketAddress, length, &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST) == 0 else { continue }
            found.append((String(cString: entry.pointee.ifa_name), String(cString: buffer)))
        }
        return found
    }
}
