// Created for EssentialFeed.
// Copyright © 2021. All rights reserved.

import XCTest
import UIKit
import EssentialFeed
import EssentialFeediOS


class FeedViewControllerTests: XCTestCase {
  func test_loadFeedActions_requestFeedFromLoader() {
    let (sut, loader) = makeSUT()
    XCTAssertEqual(loader.loadCallCount, 0, "Expected no loading requests before view is loaded")
    
    sut.loadViewIfNeeded()
    XCTAssertEqual(loader.loadCallCount, 1, "Expected a loading request once view is loaded")
    
    sut.simulateUserInitiatedFeedReload()
    XCTAssertEqual(loader.loadCallCount, 2, "Expected another loading request once user initiates a reload")
    
    sut.simulateUserInitiatedFeedReload()
    XCTAssertEqual(loader.loadCallCount, 3, "Expected yet another loading request once user initiates another reload")
  }
  
  func test_loadingFeedIndicator_isVisibleWhileLoadingFeed() {
    let (sut, loader) = makeSUT()
    
    sut.loadViewIfNeeded()
    XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once view is loaded")
    
    loader.completeFeedLoading(at: 0)
    XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once loading is completed")
    
    sut.simulateUserInitiatedFeedReload()
    XCTAssertTrue(sut.isShowingLoadingIndicator, "Expected loading indicator once user initiates a reload")
    
    loader.completeFeedLoading(at: 1)
    XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected no loading indicator once user initiated loading is completed")
  }
  
  func test_loadFeedCompletion_rendersSuccessfullyLoadedFeed() {
    let image0 = makeImage(description: "a description", location: "a location")
    let image1 = makeImage(description: nil, location: "another location")
    let image2 = makeImage(description: "another description", location: nil)
    let image3 = makeImage(description: nil, location: nil)
    
    let (sut, loader) = makeSUT()
    
    sut.loadViewIfNeeded()
    assertThat(sut, isRendering: [])
    
    loader.completeFeedLoading(with: [image0], at: 0)
    assertThat(sut, isRendering: [image0])
  
    
    sut.simulateUserInitiatedFeedReload()
    loader.completeFeedLoading(with: [image0, image1, image2, image3], at: 1)
    assertThat(sut, isRendering: [image0, image1, image2, image3])
  }
  
  
  // MARK: -  Helpers
  private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
    let loader = LoaderSpy()
    let sut = FeedViewController(loader: loader)
    trackForMemoryLeaks(loader, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return (sut, loader)
  }
  
  private func assertThat(_ sut: FeedViewController, isRendering feed: [FeedImage], file: StaticString = #file, line: UInt = #line) {
    guard sut.numberOfRenderedFeedImageViews() == feed.count else {
      XCTFail("Expected \(feed.count) images, got \(sut.numberOfRenderedFeedImageViews()) instead", file: file, line: line)
      return
    }
    
    feed.enumerated().forEach { index, image in
      assertThat(sut, hasViewConfiguredFor: image, at: index)
    }
  }
  
  private func assertThat(_ sut: FeedViewController, hasViewConfiguredFor image: FeedImage, at index: Int, file: StaticString = #file, line: UInt = #line) {
    let view = sut.feedImageView(at: index)
    
    guard let cell = view as? FeedImageCell else {
      XCTFail("Expected \(FeedImageCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
      return
    }
    
    let shouldLocationBeVisible = (image.location != nil)
    XCTAssertEqual(cell.isShowingLocation, shouldLocationBeVisible, "Expected `isShowingLocation` to be \(shouldLocationBeVisible) for image view at index (\(index))", file: file, line: line)
    
    XCTAssertEqual(cell.locationText, image.location, "Expected location text to be \(String(describing: image.location)) for image view at index (\(index))", file: file, line: line)
    
    XCTAssertEqual(cell.descriptionText, image.description, "Expected description text to be \(String(describing: image.description)) for image view at index (\(index))", file: file, line: line)
  }
  
  private func makeImage(description: String? = nil, location: String? = nil, url: URL = URL(string: "https://any-url.com")!) -> FeedImage {
    return FeedImage(id: UUID(), description: description, location: location, url: url)
  }
  
  class LoaderSpy: FeedLoader {
    private var completions = [(FeedLoader.Result) -> Void]()
    
    var loadCallCount: Int {
      return completions.count
    }
    
    func load(completion: @escaping (FeedLoader.Result) -> Void) {
      completions.append(completion)
    }
    
    func completeFeedLoading(with feedImage: [FeedImage] = [], at index: Int = .zero) {
      completions[index](.success(feedImage))
    }
  }
  
}

private extension FeedViewController {
  func simulateUserInitiatedFeedReload() {
    refreshControl?.simulatePullToRefresh()
  }
  
  func feedImageView(at row: Int = .zero) -> UITableViewCell? {
    let ds = tableView.dataSource
    let index = IndexPath(row: row, section: feedImagesSection)
    return ds?.tableView(tableView, cellForRowAt: index)
  }
  
  var isShowingLoadingIndicator: Bool {
    refreshControl?.isRefreshing == true
  }
  
  func numberOfRenderedFeedImageViews() -> Int {
    return tableView.numberOfRows(inSection: feedImagesSection)
  }
  
  private var feedImagesSection: Int {
    return .zero
  }
}

private extension FeedImageCell {
  var isShowingLocation: Bool {
    return !locationContainer.isHidden
  }
  
  var locationText: String? {
    return locationLabel.text
  }
  
  var descriptionText: String? {
    return descriptionLabel.text
  }
}

private extension UIRefreshControl {
  func simulatePullToRefresh() {
    allTargets.forEach({ target in
      actions(forTarget: target, forControlEvent: .valueChanged)?.forEach({
        (target as NSObject).perform(Selector($0))
      })
    })
  }
}
