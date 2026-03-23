import XCTest

final class MoodAppUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testMainFlow() throws {
        // 1. Verify Main View Elements
        XCTAssertTrue(app.navigationBars["今日状态"].exists)
        XCTAssertTrue(app.staticTexts["记录心情"].exists)
        XCTAssertTrue(app.staticTexts["我安好"].exists)
        XCTAssertTrue(app.staticTexts["紧急联系"].exists)
        
        // 2. Mood Check-in
        app.buttons["记录心情"].tap()
        XCTAssertTrue(app.staticTexts["心情签到"].exists)
        app.buttons["😄"].tap()
        app.buttons["完成"].tap()
        XCTAssertTrue(app.navigationBars["今日状态"].waitForExistence(timeout: 2))
        
        // 3. Safety Check
        app.buttons["我安好"].tap()
        XCTAssertTrue(app.staticTexts["安全签到"].exists)
        app.buttons["我安好"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap() // Back button
        XCTAssertTrue(app.navigationBars["今日状态"].exists)
        
        // 4. Emergency Contact
        app.buttons["紧急联系"].tap()
        XCTAssertTrue(app.staticTexts["紧急联系人"].exists)
        // Note: CNContactPicker and permissions cannot be fully automated in unit tests without custom mocks,
        // but we can assert the button existence.
        XCTAssertTrue(app.buttons["添加联系人"].exists)
    }
}
