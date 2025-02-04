//
//  BookmarkOutlineViewDataSourceTests.swift
//
//  Copyright © 2021 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
@testable import DuckDuckGo_Privacy_Browser

class BookmarkOutlineViewDataSourceTests: XCTestCase {

    @MainActor
    func testWhenOutlineViewExpandsItem_ThenTheObjectIDIsAddedToExpandedItems() {
        let mockFolder = BookmarkFolder.mock
        let treeController = createTreeController(with: [mockFolder])
        let mockFolderNode = treeController.node(representing: mockFolder)!
        let dataSource = BookmarkOutlineViewDataSource(contentMode: .foldersOnly, bookmarkManager: LocalBookmarkManager(), treeController: treeController, sortMode: .manual)

        let notification = Notification(name: NSOutlineView.itemDidExpandNotification, object: nil, userInfo: ["NSObject": mockFolderNode])
        dataSource.outlineViewItemDidExpand(notification)

        XCTAssertEqual(dataSource.expandedNodesIDs, [mockFolder.id])
    }

    @MainActor
    func testWhenOutlineViewCollapsesItem_ThenTheObjectIDIsRemovedFromExpandedItems() {
        let mockFolder = BookmarkFolder.mock
        let treeController = createTreeController(with: [mockFolder])
        let mockFolderNode = treeController.node(representing: mockFolder)!
        let dataSource = BookmarkOutlineViewDataSource(contentMode: .foldersOnly, bookmarkManager: LocalBookmarkManager(), treeController: treeController, sortMode: .manual)

        let expandNotification = Notification(name: NSOutlineView.itemDidExpandNotification, object: nil, userInfo: ["NSObject": mockFolderNode])
        dataSource.outlineViewItemDidExpand(expandNotification)

        XCTAssertEqual(dataSource.expandedNodesIDs, [mockFolder.id])

        let collapseNotification = Notification(name: NSOutlineView.itemDidCollapseNotification, object: nil, userInfo: ["NSObject": mockFolderNode])
        dataSource.outlineViewItemDidCollapse(collapseNotification)

        XCTAssertEqual(dataSource.expandedNodesIDs, [])
    }

    @MainActor
    func testWhenGettingPasteboardWriterForItem_AndItemIsBookmarkEntity_ThenWriterIsReturned() {
        let mockFolder = BookmarkFolder.mock
        let mockOutlineView = NSOutlineView(frame: .zero)
        let treeController = createTreeController(with: [mockFolder])
        let mockFolderNode = treeController.node(representing: mockFolder)!
        let dataSource = BookmarkOutlineViewDataSource(contentMode: .foldersOnly, bookmarkManager: LocalBookmarkManager(), treeController: treeController, sortMode: .manual)

        let writer = dataSource.outlineView(mockOutlineView, pasteboardWriterForItem: mockFolderNode) as? FolderPasteboardWriter
        XCTAssertNotNil(writer)

        let writerDictionary = writer?.internalDictionary
        XCTAssertEqual(writerDictionary?["id"], mockFolder.id)
    }

    @MainActor
    func testWhenGettingPasteboardWriterForItem_AndItemIsNotBookmarkEntity_ThenNilIsReturned() {
        let mockFolder = BookmarkFolder.mock
        let mockOutlineView = NSOutlineView(frame: .zero)
        let treeController = createTreeController(with: [mockFolder])
        let dataSource = BookmarkOutlineViewDataSource(contentMode: .foldersOnly, bookmarkManager: LocalBookmarkManager(), treeController: treeController, sortMode: .manual)

        let spacerNode = BookmarkNode(representedObject: SpacerNode.blank, parent: nil)
        let writer = dataSource.outlineView(mockOutlineView, pasteboardWriterForItem: spacerNode) as? FolderPasteboardWriter
        XCTAssertNil(writer)
    }

    @MainActor
    func testWhenValidatingBookmarkDrop_AndDestinationIsFolder_ThenMoveDragOperationIsReturned() {
        let mockDestinationFolder = BookmarkFolder.mock
        let bookmarkStoreMock = BookmarkStoreMock()
        let faviconManagerMock = FaviconManagerMock()
        let bookmarkManager = LocalBookmarkManager(bookmarkStore: bookmarkStoreMock, faviconManagement: faviconManagerMock)

        bookmarkStoreMock.bookmarks = [mockDestinationFolder]
        bookmarkManager.loadBookmarks()

        let treeDataSource = BookmarkSidebarTreeController(bookmarkManager: bookmarkManager)
        let treeController = BookmarkTreeController(dataSource: treeDataSource, sortMode: .manual)
        let mockDestinationNode = treeController.node(representing: mockDestinationFolder)!
        let dataSource = BookmarkOutlineViewDataSource(contentMode: .foldersOnly, bookmarkManager: LocalBookmarkManager(), treeController: treeController, sortMode: .manual)

        let pasteboardBookmark = PasteboardBookmark(id: UUID().uuidString, url: "https://example.com", title: "Pasteboard Bookmark")
        let result = dataSource.validateDrop(for: [pasteboardBookmark], destination: mockDestinationNode)

        XCTAssertEqual(result, .move)
    }

    @MainActor
    func testWhenValidatingFolderDrop_AndDestinationIsFolder_ThenMoveDragOperationIsReturned() {
        let mockDestinationFolder = BookmarkFolder.mock
        let bookmarkStoreMock = BookmarkStoreMock()
        let faviconManagerMock = FaviconManagerMock()
        let bookmarkManager = LocalBookmarkManager(bookmarkStore: bookmarkStoreMock, faviconManagement: faviconManagerMock)

        bookmarkStoreMock.bookmarks = [mockDestinationFolder]
        bookmarkManager.loadBookmarks()

        let treeDataSource = BookmarkSidebarTreeController(bookmarkManager: bookmarkManager)
        let treeController = BookmarkTreeController(dataSource: treeDataSource, sortMode: .manual)
        let mockDestinationNode = treeController.node(representing: mockDestinationFolder)!
        let dataSource = BookmarkOutlineViewDataSource(contentMode: .foldersOnly, bookmarkManager: LocalBookmarkManager(), treeController: treeController, sortMode: .manual)

        let pasteboardFolder = PasteboardFolder(folder: .init(id: UUID().uuidString, title: "Pasteboard Folder"))
        let result = dataSource.validateDrop(for: [pasteboardFolder], destination: mockDestinationNode)

        XCTAssertEqual(result, .move)
    }

    @MainActor
    func testWhenValidatingFolderDrop_AndDestinationIsSameFolder_ThenNoDragOperationIsReturned() {
        let mockDestinationFolder = BookmarkFolder.mock
        let bookmarkStoreMock = BookmarkStoreMock()
        let faviconManagerMock = FaviconManagerMock()
        let bookmarkManager = LocalBookmarkManager(bookmarkStore: bookmarkStoreMock, faviconManagement: faviconManagerMock)

        bookmarkStoreMock.bookmarks = [mockDestinationFolder]
        bookmarkManager.loadBookmarks()

        let treeDataSource = BookmarkSidebarTreeController(bookmarkManager: bookmarkManager)
        let treeController = BookmarkTreeController(dataSource: treeDataSource, sortMode: .manual)
        let dataSource = BookmarkOutlineViewDataSource(contentMode: .foldersOnly, bookmarkManager: LocalBookmarkManager(), treeController: treeController, sortMode: .manual)
        let mockDestinationNode = treeController.node(representing: mockDestinationFolder)!

        let pasteboardFolder = PasteboardFolder(folder: mockDestinationFolder)
        let result = dataSource.validateDrop(for: [pasteboardFolder], destination: mockDestinationNode)

        XCTAssertEqual(result, .none)
    }

    @MainActor
    func testWhenValidatingFolderDrop_AndDestinationIsAncestor_ThenNoneIsReturned() {
        let childFolder = BookmarkFolder(id: UUID().uuidString, title: "Child")
        let rootFolder = BookmarkFolder(id: UUID().uuidString, title: "Root", children: [childFolder])

        let bookmarkStoreMock = BookmarkStoreMock()
        let faviconManagerMock = FaviconManagerMock()
        let bookmarkManager = LocalBookmarkManager(bookmarkStore: bookmarkStoreMock, faviconManagement: faviconManagerMock)

        bookmarkStoreMock.bookmarks = [rootFolder]
        bookmarkManager.loadBookmarks()

        let treeDataSource = BookmarkSidebarTreeController(bookmarkManager: bookmarkManager)
        let treeController = BookmarkTreeController(dataSource: treeDataSource, sortMode: .manual)
        let dataSource = BookmarkOutlineViewDataSource(contentMode: .foldersOnly, bookmarkManager: LocalBookmarkManager(), treeController: treeController, sortMode: .manual)
        let mockDestinationNode = treeController.node(representing: childFolder)!

        // Simulate dragging the root folder onto the child folder:
        let draggedFolder = PasteboardFolder(folder: rootFolder)
        let result = dataSource.validateDrop(for: [draggedFolder], destination: mockDestinationNode)

        XCTAssertEqual(result, .none)
    }

    @MainActor
    func testWhenCellFiresDelegate_ThenOnMenuRequestedActionShouldFire() throws {
        // GIVEN
        let mockFolder = BookmarkFolder.mock
        let mockOutlineView = NSOutlineView(frame: .zero)
        let treeController = createTreeController(with: [mockFolder])
        let mockFolderNode = treeController.node(representing: mockFolder)!
        var didFireClosure = false
        var capturedCell: BookmarkOutlineCellView?
        let dataSource = BookmarkOutlineViewDataSource(contentMode: .foldersOnly, bookmarkManager: LocalBookmarkManager(), treeController: treeController, sortMode: .manual) { cell in
            didFireClosure = true
            capturedCell = cell
        }
        let cell = try XCTUnwrap(dataSource.outlineView(mockOutlineView, viewFor: nil, item: mockFolderNode) as? BookmarkOutlineCellView)

        // WHEN
        cell.delegate?.outlineCellViewRequestedMenu(cell)

        // THEN
        XCTAssertTrue(didFireClosure)
        XCTAssertEqual(cell, capturedCell)
    }

    @MainActor
    func testWhenShowMenuButtonOnHoverIsTrue_ThenCellShouldHaveShouldMenuButtonFlagTrue() throws {
        // GIVEN
        let mockFolder = BookmarkFolder.mock
        let mockOutlineView = NSOutlineView(frame: .zero)
        let treeController = createTreeController(with: [mockFolder])
        let mockFolderNode = treeController.node(representing: mockFolder)!
        let dataSource = BookmarkOutlineViewDataSource(contentMode: .bookmarksAndFolders, bookmarkManager: LocalBookmarkManager(), treeController: treeController, sortMode: .manual, showMenuButtonOnHover: true)

        // WHEN
        let cell = try XCTUnwrap(dataSource.outlineView(mockOutlineView, viewFor: nil, item: mockFolderNode) as? BookmarkOutlineCellView)

        // THEN
        XCTAssertTrue(cell.shouldShowMenuButton)
    }

    @MainActor
    func testWhenShowMenuButtonOnHoverIsFalse_ThenCellShouldHaveShouldMenuButtonFlagFalse() throws {
        // GIVEN
        let mockFolder = BookmarkFolder.mock
        let mockOutlineView = NSOutlineView(frame: .zero)
        let treeController = createTreeController(with: [mockFolder])
        let mockFolderNode = treeController.node(representing: mockFolder)!
        let dataSource = BookmarkOutlineViewDataSource(contentMode: .foldersOnly, bookmarkManager: LocalBookmarkManager(), treeController: treeController, sortMode: .manual, showMenuButtonOnHover: false)

        // WHEN
        let cell = try XCTUnwrap(dataSource.outlineView(mockOutlineView, viewFor: nil, item: mockFolderNode) as? BookmarkOutlineCellView)

        // THEN
        XCTAssertFalse(cell.shouldShowMenuButton)
    }

    // MARK: - Private

    @MainActor
    private func createTreeController(with bookmarks: [BaseBookmarkEntity]) -> BookmarkTreeController {
        let bookmarkStoreMock = BookmarkStoreMock()
        let faviconManagerMock = FaviconManagerMock()
        let bookmarkManager = LocalBookmarkManager(bookmarkStore: bookmarkStoreMock, faviconManagement: faviconManagerMock)

        bookmarkStoreMock.bookmarks = bookmarks
        bookmarkManager.loadBookmarks()

        let treeDataSource = BookmarkSidebarTreeController(bookmarkManager: bookmarkManager)
        return BookmarkTreeController(dataSource: treeDataSource, sortMode: .manual)
    }

}

extension Bookmark {

    static var mock: Bookmark = Bookmark(id: UUID().uuidString,
                                         url: URL.duckDuckGo.absoluteString,
                                         title: "Title",
                                         isFavorite: false)

}

extension BookmarkFolder {

    static var mock = BookmarkFolder(id: UUID().uuidString, title: "Title")

}
