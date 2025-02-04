//
//  BookmarksOutlineView.swift
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

import AppKit

extension NSDragOperation {

    static let none = NSDragOperation([])

}

final class BookmarksOutlineView: NSOutlineView {

    var lastRow: RoundedSelectionRowView?

    override func frameOfOutlineCell(atRow row: Int) -> NSRect {
        let frame = super.frameOfOutlineCell(atRow: row)

        guard let node = item(atRow: row) as? BookmarkNode else {
            return frame
        }

        if node.representedObject is SpacerNode {
            return .zero
        }

        guard node.representedObject is PseudoFolder else {
            return frame
        }

        if node.childNodes.isEmpty {
            return .zero
        } else {
            return frame
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let scrollView = enclosingScrollView else { return }

        let trackingArea = NSTrackingArea(rect: .zero, options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect], owner: self, userInfo: nil)

        scrollView.addTrackingArea(trackingArea)
    }

    override func mouseMoved(with event: NSEvent) {
        lastRow?.highlight = false
        let point = convert(event.locationInWindow, to: nil)
        let row = row(at: point)
        guard row >= 0, let rowView = rowView(atRow: row, makeIfNecessary: false) as? RoundedSelectionRowView else { return }
        let item = item(atRow: row) as? BookmarkNode
        rowView.highlight = !(item?.representedObject is SpacerNode)
        lastRow = rowView
    }

    func scrollTo(_ item: Any, code: ((Int) -> Void)? = nil) {
        let rowIndex = row(forItem: item)

        if rowIndex != -1 {
            scrollRowToVisible(rowIndex)
            code?(rowIndex)
        }
    }

    /// Scrolls to the passed node and tries to position it in the second row.
    func scrollToAdjustedPositionInOutlineView(_ item: Any) {
        scrollTo(item) { rowIndex in
            if let enclosingScrollView = self.enclosingScrollView {
                let rowRect = self.rect(ofRow: rowIndex)
                let desiredTopPosition = rowRect.origin.y - self.rowHeight // Adjusted position one row height from the top.
                let scrollPoint = NSPoint(x: 0, y: desiredTopPosition - enclosingScrollView.contentInsets.top)
                enclosingScrollView.contentView.scroll(to: scrollPoint)
            }
        }
    }

    func highlight(_ item: Any) {
        let row = row(forItem: item)
        guard let rowView = rowView(atRow: row, makeIfNecessary: false) as? RoundedSelectionRowView else { return }

        rowView.highlight = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            rowView.highlight = false
        }
    }

    func isItemVisible(_ item: Any) -> Bool {
        let rowIndex = self.row(forItem: item)

        if rowIndex == -1 {
            return false
        }

        let visibleRowsRange = self.rows(in: self.visibleRect)
        return visibleRowsRange.contains(rowIndex)
    }
}
