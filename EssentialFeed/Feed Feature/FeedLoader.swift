//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Bayu Kurniawan on 8/18/21.
//

import Foundation

public protocol FeedLoader {
  typealias Result = Swift.Result<[FeedImage], Error>
  
  func load(completion: @escaping (Result) -> Void)
}
