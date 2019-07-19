#if os(Linux)

import SwiftTestReporter
import XCTest
@testable import SwiftBoxMetricsTests
@testable import SwiftBoxLoggingTests
@testable import SwiftBoxConfigTests


_ = TestObserver()

XCTMain([
    // Logging
    testCase(Logger2Tests.allTests),
    testCase(LoggingManagerTests.allTests),

    // MetricsTimeAmountTests
    testCase(StatsDHandlerTests.allTests),
    testCase(MetricTypesTests.allTests),
    testCase(TCPStatsDClientTests.allTests),
    testCase(UDPStatsDClientTests.allTests),

    // Configuration
    testCase(ConfigManagerTests.allTests),
    testCase(ConfigSourcesBootstrapTests.allTests),
    testCase(ConfigurationParsingTests.allTests),
    testCase(FlatDictParserTests.allTests),
    testCase(EnvSourceTests.allTests),
    testCase(JSONSourceTests.allTests),
    testCase(DictionarySourceTests.allTests),
    testCase(CommandLineSourceTests.allTests),
])

#endif
