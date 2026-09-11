import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class ForthSession: ForthHostAPI {
    var consoleText: String = ""
    var editorText: String = ""
    var statusLine: String = "Ready"

    private var inputWaiter: CheckedContinuation<String?, Never>?
    private var unreadLines: [String] = []

    func writeConsole(_ text: String) {
        consoleText.append(text)
    }

    func writeConsoleLine(_ text: String) {
        consoleText.append(text)
        if !text.hasSuffix("\n") { consoleText.append("\n") }
    }

    func requestScreenRefresh() {
        statusLine = "Refreshed"
    }

    func readConsoleLine() async -> String? {
        if !unreadLines.isEmpty {
            return unreadLines.removeFirst()
        }
        return await withCheckedContinuation { continuation in
            inputWaiter = continuation
        }
    }

    func submitConsoleLine(_ line: String) {
//        writeConsoleLine(line)
        if let waiter = inputWaiter {
            inputWaiter = nil
            waiter.resume(returning: line)
        } else {
            unreadLines.append(line)
        }
    }

    func openFile(prompt: String, types: [String]) async -> URL? {
        let panel = NSOpenPanel()
        panel.message = prompt
        panel.allowedContentTypes = types.compactMap { UTType(filenameExtension: $0) }
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard await panel.begin() == .OK else { return nil }
        return panel.url
    }

    func saveFile(prompt: String, suggestedName: String, types: [String]) async -> URL? {
        let panel = NSSavePanel()
        panel.message = prompt
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = types.compactMap { UTType(filenameExtension: $0) }
        guard await panel.begin() == .OK else { return nil }
        return panel.url
    }

    func loadText(from url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    func saveText(_ text: String, to url: URL) throws {
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private var keyWaiter: CheckedContinuation<UInt8, Never>?
    private var unreadKeys: [UInt8] = []

    // MARK: Forth primitives

    /// EMIT ( x -- )  emit low 8 bits as a character
    func emit(_ x: UInt8) {
        if x == 10 || x == 13 {
            writeConsole("\n")
            return
        }
        if let scalar = UnicodeScalar(UInt32(x)) {
            writeConsole(String(Character(scalar)))
        }
    }

    /// TYPE ( addr u -- )  here: a Swift String
    func type(_ string: String) {
        writeConsole(string)
    }

    /// CR ( -- )
    func cr() {
        writeConsole("\n")
    }

    /// PAGE / REFRESH
    func page() {
        consoleText = ""
        requestScreenRefresh()
    }

    /// ACCEPT ( addr +n1 -- +n2 )  here: returns the line, truncated
    func accept(maxCount: Int) async -> String {
        let line = await readConsoleLine() ?? ""
        if line.count <= maxCount { return line }
        return String(line.prefix(maxCount))
    }

    /// KEY ( -- char )
    func readKey() async -> UInt8 {
        if !unreadKeys.isEmpty {
            return unreadKeys.removeFirst()
        }
        return await withCheckedContinuation { continuation in
            keyWaiter = continuation
        }
    }

    func submitKey(_ byte: UInt8) {
        if let waiter = keyWaiter {
            keyWaiter = nil
            waiter.resume(returning: byte)
        } else {
            unreadKeys.append(byte)
        }
    }

    func submitKey(character: Character) {
        for scalar in character.unicodeScalars {
            let v = scalar.value
            if v <= 0xFF {
                submitKey(UInt8(v))
            }
        }
    }
}
