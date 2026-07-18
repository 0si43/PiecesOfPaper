//
//  PreferenceStoreTests.swift
//  PiecesOfPaperTests
//
//  Created by Nakajima on 2026/07/18.
//  Copyright © 2026 Tsuyoshi Nakajima. All rights reserved.
//

import Testing
@testable import Pieces_of_Paper

@MainActor
struct PreferenceStoreTests {
    @Test func test_init_readsValuesWithoutRePersisting() {
        let mock = PreferenceRepositoryMock()
        mock.enablediCloud = true
        mock.enabledAutoSave = false
        mock.enabledInfiniteScroll = false

        let store = PreferenceStore(repository: mock)
        #expect(store.enablediCloud)
        #expect(!store.enabledAutoSave)
        #expect(!store.enabledInfiniteScroll)
        #expect(mock.setEnablediCloudCalls.isEmpty)
        #expect(mock.setEnabledAutoSaveCalls.isEmpty)
        #expect(mock.setEnabledInfiniteScrollCalls.isEmpty)
    }

    @Test func test_enablediCloud_persistsOnChange() {
        let mock = PreferenceRepositoryMock()
        let store = PreferenceStore(repository: mock)
        store.enablediCloud = true
        #expect(mock.setEnablediCloudCalls == [true])
        #expect(mock.getEnablediCloud())
    }

    @Test func test_enabledAutoSave_persistsOnChange() {
        let mock = PreferenceRepositoryMock()
        let store = PreferenceStore(repository: mock)
        store.enabledAutoSave = false
        #expect(mock.setEnabledAutoSaveCalls == [false])
        #expect(!mock.getEnabledAutoSave())
    }

    @Test func test_enabledInfiniteScroll_persistsOnChange() {
        let mock = PreferenceRepositoryMock()
        let store = PreferenceStore(repository: mock)
        store.enabledInfiniteScroll = false
        #expect(mock.setEnabledInfiniteScrollCalls == [false])
        #expect(!mock.getEnabledInfiniteScroll())
    }

    @Test func test_shouldGrantiCloud_isFalseWheniCloudDisabled() {
        let mock = PreferenceRepositoryMock()
        mock.enablediCloud = false
        let store = PreferenceStore(repository: mock)
        #expect(!store.shouldGrantiCloud)
    }
}
