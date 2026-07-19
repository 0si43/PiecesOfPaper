// Consolidates docs/progress/ fragment files into the Work Log of docs/PROGRESS.md.
//
// Usage (from the repository root):
//   swift scripts/consolidate-progress.swift
//
// Flow: group docs/progress/YYYY-MM-DD-<slug>.md by date, merge them into the
// "## Work Log" section newest date first (appending to an existing section for
// the same date), then delete the consumed fragments. Does nothing when there
// are no fragments. Run only when the user asks, one run at a time; put the
// result in a chore PR.

import Foundation

let progressPath = "docs/PROGRESS.md"
let fragmentsDir = "docs/progress"
let logHeading = "## Work Log"

let fragmentNamePattern = #/^(\d{4}-\d{2}-\d{2})-.+\.md$/#
let sectionHeadingPattern = #/^### (\d{4}-\d{2}-\d{2})(?:\s|$)/#

struct Fragment {
    let date: String
    let body: String
}

final class Section {
    let date: String
    let headingLine: String
    var bodyLines: [String]

    init(date: String, headingLine: String, bodyLines: [String]) {
        self.date = date
        self.headingLine = headingLine
        self.bodyLines = bodyLines
    }
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func trimTrailingBlank(_ lines: inout [String]) {
    while let last = lines.last, last.trimmingCharacters(in: .whitespaces).isEmpty {
        lines.removeLast()
    }
}

func stripLeadingBlank(_ lines: [String]) -> [String] {
    var start = 0
    while start < lines.count, lines[start].trimmingCharacters(in: .whitespaces).isEmpty {
        start += 1
    }
    return Array(lines[start...])
}

func parseFragment(name: String, content: String) -> Fragment {
    guard let match = name.wholeMatch(of: fragmentNamePattern) else {
        fail("\(fragmentsDir)/\(name) does not match the naming rule YYYY-MM-DD-<slug>.md")
    }
    var lines = content.components(separatedBy: "\n")
    trimTrailingBlank(&lines)
    let body = stripLeadingBlank(lines).joined(separator: "\n")
    if body.isEmpty {
        fail("\(fragmentsDir)/\(name) is empty")
    }
    if body.components(separatedBy: "\n").contains(where: { $0.hasPrefix("#") }) {
        fail("\(fragmentsDir)/\(name) contains a heading line (#). Fragments must be bullet lists only")
    }
    return Fragment(date: String(match.1), body: body)
}

func mergeFragments(progressText: String, fragments: [Fragment]) -> String {
    guard !fragments.isEmpty else { return progressText }

    let lines = progressText.components(separatedBy: "\n")
    guard let headingIndex = lines.firstIndex(where: {
        $0.trimmingCharacters(in: .whitespaces) == logHeading
    }) else {
        fail("\(progressPath) has no \"\(logHeading)\" heading")
    }

    // The Work Log region runs from the line after the heading to the next "## " heading or EOF
    var regionEnd = lines.count
    for index in (headingIndex + 1)..<lines.count where lines[index].hasPrefix("## ") {
        regionEnd = index
        break
    }

    var sections: [Section] = []
    for index in (headingIndex + 1)..<regionEnd {
        let line = lines[index]
        if let match = line.firstMatch(of: sectionHeadingPattern) {
            sections.append(Section(date: String(match.1), headingLine: line, bodyLines: []))
        } else if let current = sections.last {
            current.bodyLines.append(line)
        } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
            fail("Work Log region has text before the first ### heading: \"\(line)\"")
        }
    }

    var byDate = Dictionary(uniqueKeysWithValues: sections.map { ($0.date, $0) })
    for fragment in fragments {
        let bodyLines = fragment.body.components(separatedBy: "\n")
        if let existing = byDate[fragment.date] {
            trimTrailingBlank(&existing.bodyLines)
            existing.bodyLines.append(contentsOf: bodyLines)
        } else {
            let section = Section(
                date: fragment.date,
                headingLine: "### \(fragment.date)",
                bodyLines: bodyLines
            )
            byDate[fragment.date] = section
            sections.append(section)
        }
    }

    sections.sort { $0.date > $1.date }
    var regionLines: [String] = []
    for section in sections {
        trimTrailingBlank(&section.bodyLines)
        regionLines.append("")
        regionLines.append(section.headingLine)
        regionLines.append("")
        regionLines.append(contentsOf: stripLeadingBlank(section.bodyLines))
    }
    if regionEnd < lines.count {
        regionLines.append("")
    }

    let result = (lines[0...headingIndex] + regionLines + lines[regionEnd...])
        .joined(separator: "\n")
    return result.hasSuffix("\n") ? result : result + "\n"
}

let fileManager = FileManager.default
guard let entries = try? fileManager.contentsOfDirectory(atPath: fragmentsDir) else {
    fail("Cannot read \(fragmentsDir) — run this script from the repository root")
}
let names = entries.filter { $0 != "README.md" && !$0.hasPrefix(".") }.sorted()
if names.isEmpty {
    print("No fragments to consolidate.")
    exit(0)
}

let fragments = names.map { name -> Fragment in
    guard let content = try? String(contentsOfFile: "\(fragmentsDir)/\(name)", encoding: .utf8) else {
        fail("Cannot read \(fragmentsDir)/\(name)")
    }
    return parseFragment(name: name, content: content)
}

guard let progressText = try? String(contentsOfFile: progressPath, encoding: .utf8) else {
    fail("Cannot read \(progressPath) — run this script from the repository root")
}

let merged = mergeFragments(progressText: progressText, fragments: fragments)
do {
    try merged.write(toFile: progressPath, atomically: true, encoding: .utf8)
} catch {
    fail("Failed to write \(progressPath): \(error.localizedDescription)")
}
for name in names {
    do {
        try fileManager.removeItem(atPath: "\(fragmentsDir)/\(name)")
    } catch {
        fail("Merged into \(progressPath) but failed to delete \(fragmentsDir)/\(name): \(error.localizedDescription)")
    }
}

print("Consolidated \(names.count) fragment(s) into \(progressPath):")
for name in names {
    print("  - \(name)")
}
