import Foundation
import NIO

public final class MockServer {
    private lazy var group = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    public let host: String
    public let port: Int
    public var baseURL: URL {
        URL(string: "http://\(host):\(port)")!
    }

    public init(host: String = "127.0.0.1",
                port: Int) {
        self.host = host
        self.port = port
    }

    lazy var serverBootstrap: ServerBootstrap = {
        let baseURL = baseURL
        return ServerBootstrap(group: group)
        .serverChannelOption(ChannelOptions.backlog, value: 256)
        .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
        .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
        .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
        .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }()

    public func start() throws {
        try DispatchQueue(label: "server." + UUID().uuidString).sync { [serverBootstrap] in
            print("Starting server at \(host):\(port)")
            _ = try serverBootstrap.bind(host: host, port: port).wait()
        }
    }

    public func stop() throws {
        try group.syncShutdownGracefully()
        print("Stoped server at \(host):\(port)")
    }
}
