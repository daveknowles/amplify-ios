//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

// swiftlint:disable:next type_name
class DefaultLoggingPluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        let plugin = AWSUnifiedLoggingPlugin()
        XCTAssertNotNil(plugin.version)
    }

}
