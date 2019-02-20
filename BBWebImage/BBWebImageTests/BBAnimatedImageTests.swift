//
//  BBAnimatedImageTests.swift
//  BBWebImageTests
//
//  Created by Kaibo Lu on 2/19/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import XCTest

class BBAnimatedImageTests: XCTestCase {
    var image: BBAnimatedImage!
    
    override func setUp() {
        let url = Bundle(for: classForCoder).url(forResource: "Rotating_earth", withExtension: "gif")!
        let data = try! Data(contentsOf: url)
        image = BBAnimatedImage(bb_data: data)
    }

    override func tearDown() {}

    func testFrameCount() {
        XCTAssertEqual(image.bb_frameCount, 44)
    }
}
