// Created for EssentialFeed.
// Copyright © 2021. All rights reserved.

import XCTest
import EssentialFeed

class CacheFeedUseCaseTests: XCTestCase {
  
  func test_init_doesNotMessageStoreUponCreation() {
    let (_, store) = makeSUT()
    
    XCTAssertEqual(store.receivedMessages, [])
  }
  
  func test_save_requestsCacheDeletion() {
    let (sut, store) = makeSUT()

    sut.save(uniqueImageFeed().models) { _ in }
    
    XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
  }
  
  func test_save_doesNotRequestCacheInsertionOnDeletionError() {
    let (sut, store) = makeSUT()
    let deletionError = anyNSError()
    
    sut.save(uniqueImageFeed().models) { _ in }
    store.completeDeletion(with: deletionError)
    
    XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed])
  }
  
  func test_save_requestsNewCacheInsertionWithTimeStampOnSuccessfulDeletion() {
    let timestamp = Date()
    let (sut, store) = makeSUT(currentDate: { timestamp })
    let feed = uniqueImageFeed()
    
    sut.save(feed.models) { _ in }
    store.completeDeletionSuccessfully()
    
    XCTAssertEqual(store.receivedMessages, [.deleteCacheFeed, .insert(feed.local, timestamp)])
  }
  
  func test_save_failsOnDeletionError() {
    let (sut, store) = makeSUT()
    let deletionError = anyNSError()
    
    expect(sut, toCompleteWithError: deletionError, when: {
      store.completeDeletion(with: deletionError)
    })
  }
  
  func test_save_failsOnInsertionError() {
    let (sut, store) = makeSUT()
    let insertionError = anyNSError()
    
    expect(sut, toCompleteWithError: insertionError, when: {
      store.completeDeletionSuccessfully()
      store.completeInsertion(with: insertionError)
    })
  }
  
  func test_save_succeedsOnSuccessfulCacheInsertion() {
    let (sut, store) = makeSUT()
    
    expect(sut, toCompleteWithError: nil, when: {
      store.completeDeletionSuccessfully()
      store.completeInsertionSuccessfully()
    })
  }
  
  func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    
    var receivedResults = [LocalFeedLoader.SaveResult]()
    sut?.save(uniqueImageFeed().models) { receivedResults.append($0) }
    
    sut = nil
    store.completeDeletion(with: anyNSError())
    
    XCTAssertTrue(receivedResults.isEmpty)
  }
  
  func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    
    var receivedResults = [LocalFeedLoader.SaveResult]()
    sut?.save(uniqueImageFeed().models) { receivedResults.append($0) }
    
    store.completeDeletionSuccessfully()
    sut = nil
    store.completeInsertion(with: anyNSError())
    
    XCTAssertTrue(receivedResults.isEmpty)
  }
  
  // MARK: -  Helpers
  private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
    let store = FeedStoreSpy()
    let sut = LocalFeedLoader(store: store, currentDate: currentDate)
    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return (sut, store)
  }
  
  private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
    let exp = expectation(description: "Wait for save completion")
    
    var receivedError: Error?
    
    sut.save(uniqueImageFeed().models) { error in
      receivedError = error
      exp.fulfill()
    }
    
    action()
    wait(for: [exp], timeout: 1.0)
    
    XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
  }
  
  private func anyNSError() -> NSError {
    return NSError(domain: "Any Error", code: 0)
  }
  
  private func uniqueImage() -> FeedImage {
    return FeedImage(id: UUID(), description: "Any", location: "Any", url: anyURL())
  }
  
  private func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let models = [uniqueImage(), uniqueImage()]
    let local = models.map {
      LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
    }
    return (models, local)
  }
  
  private func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
  }
  
  private class FeedStoreSpy: FeedStore {
    
    enum ReceivedMessage: Equatable {
      case deleteCacheFeed
      case insert([LocalFeedImage], Date)
    }
    
    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    private(set) var receivedMessages = [ReceivedMessage]()
    
    func deleteCacheFeed(completion: @escaping DeletionCompletion) {
      deletionCompletions.append(completion)
      receivedMessages.append(.deleteCacheFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
      deletionCompletions[index](error)
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
      insertionCompletions.append(completion)
      receivedMessages.append(.insert(feed, timestamp))
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
      deletionCompletions[index](nil)
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
      insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
      insertionCompletions[index](nil)
    }
  }
}