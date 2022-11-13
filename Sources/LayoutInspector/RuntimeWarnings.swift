// Source: Point-Free, Swift Composable Architecture, RuntimeWarnings.swift
// https://github.com/pointfreeco/swift-composable-architecture/blob/399bc83dcfc7bdcee99f7f6cc0a687ca29e8494b/Sources/ComposableArchitecture/Internal/RuntimeWarnings.swift
//
// Based on: Point-Free, Unobtrusive runtime warnings for libraries (2022-01-03)
// https://www.pointfree.co/blog/posts/70-unobtrusive-runtime-warnings-for-libraries
//
// ---
//
// License:
//
// MIT License
//
// Copyright (c) 2020 Point-Free, Inc.
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
// Slightly modified by Ole Begemann

#if DEBUG
    import os

    // NB: Xcode runtime warnings offer a much better experience than traditional assertions and
    //     breakpoints, but Apple provides no means of creating custom runtime warnings ourselves.
    //     To work around this, we hook into SwiftUI's runtime issue delivery mechanism, instead.
    //
    // Feedback filed: https://gist.github.com/stephencelis/a8d06383ed6ccde3e5ef5d1b3ad52bbc
    private let rw = (
        dso: { () -> UnsafeMutableRawPointer in
            let count = _dyld_image_count()
            for i in 0..<count {
                if let name = _dyld_get_image_name(i) {
                    let swiftString = String(cString: name)
                    if swiftString.hasSuffix("/SwiftUI") {
                        if let header = _dyld_get_image_header(i) {
                            return UnsafeMutableRawPointer(mutating: UnsafeRawPointer(header))
                        }
                    }
                }
            }
            return UnsafeMutableRawPointer(mutating: #dsohandle)
        }(),
        log: OSLog(subsystem: "com.apple.runtime-issues", category: "DebugLayout")
    )
#endif

@_transparent
@inline(__always)
func runtimeWarning(
    _ message: @autoclosure () -> StaticString,
    _ args: @autoclosure () -> [CVarArg] = [],
    file: StaticString? = nil,
    line: UInt? = nil
) {
    #if DEBUG
        let message = message()
        unsafeBitCast(
            os_log as (OSLogType, UnsafeRawPointer, OSLog, StaticString, CVarArg...) -> Void,
            to: ((OSLogType, UnsafeRawPointer, OSLog, StaticString, [CVarArg]) -> Void).self
        )(.fault, rw.dso, rw.log, message, args())
    #endif
}
