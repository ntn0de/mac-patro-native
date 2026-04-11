
import XCTest
@testable import MacPatroKit

final class DataServiceTests: XCTestCase {
    
    var mockDataService: MockDataService!
    
    override func setUp() {
        super.setUp()
        mockDataService = MockDataService()
    }
    
    override func tearDown() {
        mockDataService = nil
        super.tearDown()
    }
    
    func testLoadDataSuccessfully() {
        let expectation = self.expectation(description: "Load data successfully")
        
        let yearData = YearData(lastUpdatedAt: 0, data: [MonthData(month: 1, days: [])])
        mockDataService.yearData = yearData
        
        mockDataService.loadData(forYear: 2081, bundle: .main) { result in
            switch result {
            case .success(let returnedYearData):
                XCTAssertEqual(returnedYearData.data.count, yearData.data.count)
                expectation.fulfill()
            case .failure:
                XCTFail("Should not have failed")
            }
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFileNotFound() {
        let expectation = self.expectation(description: "File not found error")
        mockDataService.error = DataService.DataServiceError.fileNotFound
        
        mockDataService.loadData(forYear: 2080, bundle: .main) { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                XCTAssertEqual(error as? DataService.DataServiceError, .fileNotFound)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testDecodingFailed() {
        let expectation = self.expectation(description: "Decoding failed error")
        mockDataService.error = DataService.DataServiceError.decodingFailed
        
        mockDataService.loadData(forYear: 2082, bundle: .main) { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                XCTAssertEqual(error as? DataService.DataServiceError, .decodingFailed)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDayDataDecodesWhenEventIsMissing() throws {
        let json = """
        {
          "last_updated_at": 1775921371817,
          "data": [
            {
              "month": 1,
              "days": [
                {
                  "isHoliday": false,
                  "day": "३",
                  "dayInEn": "3",
                  "en": "16"
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(YearData.self, from: json)

        XCTAssertEqual(decoded.data.first?.days.first?.event, "")
    }
}
