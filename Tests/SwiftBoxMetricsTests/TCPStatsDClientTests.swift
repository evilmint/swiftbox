import Foundation
import XCTest

@testable import NIO
@testable import SwiftBoxMetrics

final class TCPStatsDClientTests: XCTestCase {

    final class FailingHandler: ChannelOutboundHandler {
        typealias OutboundIn = ByteBuffer
        typealias OutboundOut = Never

        func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
            promise?.fail(ChannelError.ioOnClosedChannel)
        }

        func flush(context: ChannelHandlerContext) {
        }
    }

    func testClientShouldPushMetrics() throws {
        let eventLoop = EmbeddedEventLoop()
        let channel = EmbeddedChannel(loop: eventLoop)
        let client = TCPStatsDClient(
                config: TCPConnectionConfig(
                        host: "localhost",
                        connectionFactory: { config in
                            return EventLoopFuture(
                                eventLoop: eventLoop,
                                value: channel,
                                file: #file,
                                line: #line
                            )
                        }
                )
        )

        client.pushMetric(metricLine: "test:1|ms")

        if let buffer = try channel.readOutbound(as: ByteBuffer.self) {
            let data = buffer.getString(at: 0, length: buffer.readableBytes)!
            XCTAssertEqual(data, "test:1|ms\n")
        } else {
            XCTFail("Got invalid type from channel data")
        }
    }

    func testClientShouldRetryWhenChannelError() throws {
        let eventLoop = EmbeddedEventLoop()
        let channel = EmbeddedChannel(loop: eventLoop)
        try channel.pipeline.addHandler(FailingHandler(), position: .first).wait()

        var countChannelInitialization = 0

        let connectionConfig = TCPConnectionConfig(
            host: "localhost",
            connectionFactory: { config in
                countChannelInitialization += 1
                return EventLoopFuture(
                        eventLoop: eventLoop,
                        value: channel,
                        file: #file,
                        line: #line
                )
            }
        )

        let client = TCPStatsDClient(config: connectionConfig)

        client.pushMetric(metricLine: "test:1|ms")

        // Channel should be reinitialized up to 5 times on failure
        XCTAssertEqual(countChannelInitialization, 6)
    }

    func testClientShouldRetryWhenConnectionError() throws {
        let eventLoop = EmbeddedEventLoop()
        var countChannelInitialization = 0

        let client = TCPStatsDClient(
                config: TCPConnectionConfig(
                        host: "localhost",
                        connectionTimeout: TimeAmount.milliseconds(100),
                        connectionFactory: { config in
                            countChannelInitialization += 1
                            return EventLoopFuture(
                                    eventLoop: eventLoop,
                                    error: ChannelError.ioOnClosedChannel,
                                    file: #file,
                                    line: #line
                            )
                        }
                )
        )

        client.pushMetric(metricLine: "test:1|ms")

        // Channel should be reinitialized up to 5 times on failure
        XCTAssertEqual(countChannelInitialization, 6)
    }

    func testClientDefaultFactoryShouldInitializeProperly() throws {
        let client = TCPStatsDClient(
                config: TCPConnectionConfig(
                        host: "localhost",
                        port: 9999
                )
        )

        XCTAssertThrowsError(try client.getConnection().wait(), "Wrong exception thrown", { error in
            XCTAssertTrue(error is NIOConnectionError)
        })
    }

    static var allTests: [(String, (TCPStatsDClientTests) -> () throws -> Void)] {
        return [
            ("testClientShouldPushMetrics", testClientShouldPushMetrics),
            ("testClientShouldRetryWhenChannelError", testClientShouldRetryWhenChannelError),
            ("testClientShouldRetryWhenConnectionError", testClientShouldRetryWhenConnectionError),
            ("testClientDefaultFactoryShouldInitializeProperly", testClientDefaultFactoryShouldInitializeProperly),
        ]
    }
}
