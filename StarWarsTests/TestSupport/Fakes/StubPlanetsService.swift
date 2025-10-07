/// Path: StarWarsTests/TestSupport/Fakes/StubPlanetsService.swift
/// Role: Scriptable service to drive ViewModel tests without network

// Given: scripted PlanetsPage(s) or error provided by the test
// When: fetch/search methods are invoked
// Then: return publishers emitting the scripted values or failing as directed

import Combine
import Foundation

@testable import StarWarsCombine

// MARK: - Stub

final class StubPlanetsService: PlanetsService {

    // MARK: Scripted responses

    var firstPage: PlanetsPage?
    var nextPage: PlanetsPage?
    var searchResults: PlanetsPage?
    var error: AppError?

    // MARK: Lifecycle

    /// Clears all scripted state to a pristine condition.
    func reset() {
        firstPage = nil
        nextPage = nil
        searchResults = nil
        error = nil
    }

    // MARK: PlanetsService

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
    func fetchPage(at pageURL: URL) -> AnyPublisher<PlanetsPage, AppError> {
        if let error = error { return Fail(error: error).eraseToAnyPublisher() }
        if let page = nextPage { return Just(page).setFailureType(to: AppError.self).eraseToAnyPublisher() }
        return Empty().eraseToAnyPublisher()
    }

    // Given: optional error or searchResults scripted
    // When: searchPlanets(query:) is called
    // Then: emit searchResults, fail with error, or emit nothing
    func searchPlanets(query searchQuery: String) -> AnyPublisher<PlanetsPage, AppError> {
        if let error = error { return Fail(error: error).eraseToAnyPublisher() }
        if let page = searchResults { return Just(page).setFailureType(to: AppError.self).eraseToAnyPublisher() }
        return Empty().eraseToAnyPublisher()
    }
}
