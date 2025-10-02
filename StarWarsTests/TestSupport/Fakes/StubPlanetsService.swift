// Path: StarWarsTests/TestSupport/Fakes/StubPlanetsService.swift
// Role: Scriptable service to drive VM tests without network

// Given: scripted PlanetsPage(s) or error provided by the test
// When: fetch/search methods are invoked
// Then: return publishers emitting the scripted values or failing as directed

import Combine
import Foundation

@testable import StarWarsCombine

final class StubPlanetsService: PlanetsService {
    var firstPage: PlanetsPage?
    var nextPage: PlanetsPage?
    var searchResults: PlanetsPage?
    var error: AppError?

    // Given: optional error or firstPage scripted
    // When: fetchFirstPage is called
    // Then: emit firstPage, fail with error, or emit nothing
    func fetchFirstPage() -> AnyPublisher<PlanetsPage, AppError> {
        if let error = error { return Fail(error: error).eraseToAnyPublisher() }
        if let page = firstPage { return Just(page).setFailureType(to: AppError.self).eraseToAnyPublisher() }
        return Empty().eraseToAnyPublisher()
    }

    // Given: optional error or nextPage scripted
    // When: fetchPage(at:) is called
    // Then: emit nextPage, fail with error, or emit nothing
    func fetchPage(at url: URL) -> AnyPublisher<PlanetsPage, AppError> {
        if let error = error { return Fail(error: error).eraseToAnyPublisher() }
        if let page = nextPage { return Just(page).setFailureType(to: AppError.self).eraseToAnyPublisher() }
        return Empty().eraseToAnyPublisher()
    }

    // Given: optional error or searchResults scripted
    // When: searchPlanets(query:) is called
    // Then: emit searchResults, fail with error, or emit nothing
    func searchPlanets(query: String) -> AnyPublisher<PlanetsPage, AppError> {
        if let error = error { return Fail(error: error).eraseToAnyPublisher() }
        if let page = searchResults { return Just(page).setFailureType(to: AppError.self).eraseToAnyPublisher() }
        return Empty().eraseToAnyPublisher()
    }
}
