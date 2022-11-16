// Based on: Swift Talk 319, Inspecting HStack Layout (2022-08-26)
// <https://talk.objc.io/episodes/S01E319-inspecting-hstack-layout>
//
// License:
//
// MIT License
//
// Copyright (c) 2022 objc.io
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// ---
//
// Significantly modified by Ole Begemann

import SwiftUI

/// A custom layout that saves the layout proposals and responses for a view
/// to a log.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct DebugLayout: Layout {
    var label: String

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        assert(subviews.count == 1)
        logLayoutStep(label, step: .proposal(proposal))
        let response = subviews[0].sizeThatFits(proposal)
        logLayoutStep(label, step: .response(response))
        return response
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        subviews[0].place(at: bounds.origin, proposal: proposal)
    }
}

/// A custom layout that clears the DebugLayout log at the point where it's
/// placed in the view tree.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
struct ClearDebugLayoutLog: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        assert(subviews.count == 1)
        DispatchQueue.main.async {
            LogStore.shared.log.removeAll()
            LogStore.shared.viewLabels.removeAll()
        }
        return subviews[0].sizeThatFits(proposal)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        assert(subviews.count == 1)
        subviews[0].place(at: bounds.origin, proposal: proposal)
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
func logLayoutStep(_ label: String, step: LogEntry.Step) {
    DispatchQueue.main.async {
        guard let prevEntry = LogStore.shared.log.last else {
            // First log entry → start at indent 0.
            LogStore.shared.log.append(LogEntry(label: label, step: step, indent: 0))
            return
        }

        var newEntry = LogEntry(label: label, step: step, indent: prevEntry.indent)
        let isSameView = prevEntry.label == label
        switch (isSameView, prevEntry.step, step) {
        case (true, .proposal(let prop), .response(let resp)):
            // Response follows immediately after proposal for the same view.
            // → We want to display them in a single row.
            // → Coalesce both layout steps.
            LogStore.shared.log.removeLast()
            newEntry = prevEntry
            newEntry.step = .proposalAndResponse(proposal: prop, response: resp)
            LogStore.shared.log.append(newEntry)

        case (_, .proposal, .proposal):
            // A proposal follows a proposal → nested view → increment indent.
            newEntry.indent += 1
            LogStore.shared.log.append(newEntry)

        case (_, .response, .response),
            (_, .proposalAndResponse, .response):
            // A response follows a response → last child returns to parent → decrement indent.
            newEntry.indent -= 1
            LogStore.shared.log.append(newEntry)

        default:
            // Keep current indentation.
            LogStore.shared.log.append(newEntry)
        }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class LogStore: ObservableObject {
    public static let shared: LogStore = .init()

    @Published public var log: [LogEntry] = []
    var viewLabels: Set<String> = []

    func registerViewLabelAndWarnIfNotUnique(_ label: String, file: StaticString, line: UInt) {
        DispatchQueue.main.async {
            if self.viewLabels.contains(label) {
                let message: StaticString = "Duplicate view label '%s' detected. Use unique labels in layoutStep() calls"
                runtimeWarning(message, [label], file: file, line: line)
            }
            self.viewLabels.insert(label)
        }
    }
}
