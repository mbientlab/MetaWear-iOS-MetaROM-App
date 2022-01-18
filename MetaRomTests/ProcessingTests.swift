//
//  ProcessingTests.swift
//  MetaClinicTests
//
//  Created by Stephen Schiffli on 6/25/18.
//  Copyright © 2018 MBIENTLAB, INC. All rights reserved.
//

@testable import MetaClinic
import XCTest
import GLKit
import SceneKit

class ProcessingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetZeroQuat() {
        // Print the quaternion of the skeleton with the limb pointed where you want
        let output = GLKQuaternionMake(0.0273817, 0.680668, 0.731471, -0.0295848)
        // Print the quaternion of the MetaWear after calibration and axis-remap
        let input = GLKQuaternionMake(0.011507, 0.00735253, 0.820496, 0.571467)
        

        let invInput = GLKQuaternionInvert(input)
        let zeroQuat = GLKQuaternionMultiply(output, invInput)
        GLKQuaternionMultiply(zeroQuat, input).dump()
        zeroQuat.dump()
    }
    
    func testConvertQuat() {
        let orig = GLKQuaternionMake(-0.564599, -0.0361487, -0.0284109, 0.824084)
        let scn = SCNQuaternion(orig)
        XCTAssertEqual(orig.x, scn.x)
        XCTAssertEqual(orig.y, scn.y)
        XCTAssertEqual(orig.z, scn.z)
        XCTAssertEqual(orig.w, scn.w)
        
        let gl = GLKQuaternion(scn)
        XCTAssertEqual(orig.x, gl.x)
        XCTAssertEqual(orig.y, gl.y)
        XCTAssertEqual(orig.z, gl.z)
        XCTAssertEqual(orig.w, gl.w)
    }
    
    func testConvertEuler() {
        let orig = GLKQuaternionMake(-0.564599, -0.0361487, -0.0284109, 0.824084)
        let euler = orig.asEuler
        XCTAssertEqual(orig.x.radiansToDegrees, -32.3491, accuracy: 0.001)
        XCTAssertEqual(orig.y.radiansToDegrees, -2.07117, accuracy: 0.001)
        XCTAssertEqual(orig.z.radiansToDegrees, -1.62782, accuracy: 0.001)
        
        let quat = euler.asQuaternion
        XCTAssertEqual(orig.x, quat.x, accuracy: 0.001)
        XCTAssertEqual(orig.y, quat.y, accuracy: 0.001)
        XCTAssertEqual(orig.z, quat.z, accuracy: 0.001)
        XCTAssertEqual(orig.w, quat.w, accuracy: 0.001)
    }
    
    func testPeak() {
        let samples = openCSV(file: "Flexion-Extension")
        let peaks = findPeaksAndValleys(samples: samples)
        print(peaks)
    }
}

func openCSV(file: String) -> [(Date, Double)] {
    let bundle = Bundle(identifier: "com.mbientlab.MetaClinicTests")!
    let url = bundle.url(forResource: file, withExtension: "csv")!
    return url.processTheraCSV()
}
