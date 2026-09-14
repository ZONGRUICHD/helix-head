import XCTest

final class HelixHeadUITests: XCTestCase {
    func testDemoNavigationPauseAndHelp() {
        let app = XCUIApplication(); app.launch()
        XCTAssertTrue(app.buttons["trackingToggle"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["recenter"].isEnabled)
        app.swipeUp()
        app.buttons["startDemo"].tap()
        app.swipeDown()
        XCTAssertTrue(app.staticTexts["DEMO"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["recenter"].isEnabled)
        app.buttons["recenter"].tap()
        app.tabBars.buttons["数据"].tap()
        XCTAssertTrue(app.staticTexts["演示数据 · 非传感器读数"].exists)
        attach("Telemetry", app)
        app.tabBars.buttons["设置"].tap()
        XCTAssertTrue(app.switches["平滑细微抖动"].exists)
        app.switches["平滑细微抖动"].tap()
        attach("Settings", app)
        app.tabBars.buttons["跟踪"].tap()
        app.buttons["trackingToggle"].tap()
        XCTAssertTrue(app.staticTexts["已暂停"].exists)
        XCTAssertFalse(app.buttons["recenter"].isEnabled)
        app.buttons["使用帮助"].tap()
        XCTAssertTrue(app.buttons["完成"].waitForExistence(timeout: 5))
        app.buttons["完成"].tap()
        app.tabBars.buttons["数据"].tap()
        XCTAssertTrue(app.staticTexts["等待运动数据"].exists)
        app.tabBars.buttons["跟踪"].tap()
        app.swipeUp()
        app.buttons["startDemo"].tap()
        app.swipeDown()
        let oldValue = app.staticTexts["yawValue"].label
        let changes = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.staticTexts["yawValue"].label != oldValue
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [changes], timeout: 5), .completed)
        attach("Tracking", app)
        app.buttons["trackingToggle"].tap()
    }
    private func attach(_ name: String, _ app: XCUIApplication) {
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways
        add(shot)
    }
}
