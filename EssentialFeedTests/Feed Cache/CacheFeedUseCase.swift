// Created for EssentialFeed.
// Copyright © 2021. All rights reserved.

import XCTest
import EssentialFeed

class LocalFeedLoader {
  
  private let store: FeedStore
  
  init(store: FeedStore) {
    self.store = store
  }
  
  func save(_ items: [FeedItem]) {
    store.deleteCacheFeed()
  }
}

class FeedStore {
  var deleteCachedFeedCallCount = 0
  
  func deleteCacheFeed() {
    deleteCachedFeedCallCount += 1
  }
}

class CacheFeedUseCaseTests: XCTestCase {
  
  func test_init_doesNotDeleteCacheUponCreation() {
    let (_, store) = makeSUT()

    XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
  }
  
  func test_save_requestsCacheDeletion() {
    let (sut, store) = makeSUT()
    let items = [uniqueItem(), uniqueItem()]
    
    sut.save(items)
    
    XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
  }
  
  // MARK: -  Helpers
  
  private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
    let store = FeedStore()
    let sut = LocalFeedLoader(store: store)
    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return (sut, store)
  }
  
  private func uniqueItem() -> FeedItem {
    return FeedItem(id: UUID(), description: "Any", location: "Any", imageURL: anyURL())
  }
  
  private func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
  }
}
