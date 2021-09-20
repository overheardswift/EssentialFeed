// Created for EssentialFeed.
// Copyright © 2021. All rights reserved.

import XCTest
import EssentialFeed

class LocalFeedLoader {
  
  private let store: FeedStore
  private let currentDate: () -> Date
  
  init(store: FeedStore, currentDate: @escaping () -> Date) {
    self.store = store
    self.currentDate = currentDate
  }
  
  func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
    store.deleteCacheFeed { [unowned self] error in
      completion(error)
      if error == nil {
        self.store.insert(items, timestamp: self.currentDate())
      }
    }
  }
}

class FeedStore {
  typealias DeletionCompletion = (Error?) -> Void
  
  enum ReceivedMessage: Equatable {
    case deleteCacheFeed
    case insert([FeedItem], Date)
  }
  
  private var deletionCompletions = [DeletionCompletion]()
  private(set) var receivedMessages = [ReceivedMessage]()
  
  func deleteCacheFeed(completion: @escaping DeletionCompletion) {
    deletionCompletions.append(completion)
    receivedMessages.append(.deleteCacheFeed)
  }
  
  func completeDeletion(with error: Error, at index: Int = 0) {
    deletionCompletions[index](error)
  }
  
  func insert(_ items: [FeedItem], timestamp: Date) {
    receivedMessages.append(.insert(items, timestamp))
  }
  
  func completeDeletionSuccessfully(at index: Int = 0) {
    deletionCompletions[index](nil)
  }
}

class CacheFeedUseCaseTests: XCTestCase {
  
  func test_init_doesNotMessageStoreUponCreation() {
    let (_, store) = makeSUT()

    XCTAssertEqual(store.receivedMessages, [])
  }
  
  func test_save_requestsCacheDeletion() {
    let (sut, store) = makeSUT()
    let items = [uniqueItem(), uniqueItem()]
    
    sut.save(items) { _ in }
    
    XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
  }
  
  func test_save_doesNotRequestCacheInsertionOnDeletionError() {
    let (sut, store) = makeSUT()
    let items = [uniqueItem(), uniqueItem()]
    let deletionError = anyNSError()
    
    sut.save(items) { _ in }
    store.completeDeletion(with: deletionError)
    
    XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
  }
  
  func test_save_requestsNewCacheInsertionWithTimeStampOnSuccessfulDeletion() {
    let timestamp = Date()
    let (sut, store) = makeSUT(currentDate: { timestamp })
    let items = [uniqueItem(), uniqueItem()]
   
    sut.save(items) { _ in }
    store.completeDeletionSuccessfully()
    
    XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed, .insert(items, timestamp)])
  }
  
  func test_save_failsOnDeletionError() {
    let (sut, store) = makeSUT()
    let items = [uniqueItem(), uniqueItem()]
    let deletionError = anyNSError()
    let exp = expectation(description: "Wait for save completion")
    
    var receivedError: Error?
    
    sut.save(items) { error in
      receivedError = error
      exp.fulfill()
    }
    
    store.completeDeletion(with: deletionError)
    wait(for: [exp], timeout: 1.0)
    
    XCTAssertEqual(receivedError as NSError?, deletionError)
  }

  
  // MARK: -  Helpers
  
  private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
    let store = FeedStore()
    let sut = LocalFeedLoader(store: store, currentDate: currentDate)
    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return (sut, store)
  }
  
  private func anyNSError() -> NSError {
    return NSError(domain: "Any Error", code: 0)
  }
  
  private func uniqueItem() -> FeedItem {
    return FeedItem(id: UUID(), description: "Any", location: "Any", imageURL: anyURL())
  }
  
  private func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
  }
}
