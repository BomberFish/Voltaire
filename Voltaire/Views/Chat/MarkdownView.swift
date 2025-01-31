// bomberfish
// MarkdownView.swift – Voltaire
// created on 2025-01-29

import SwiftUI
import LaTeXSwiftUI

// markdown view that offers more than what swiftui provides ootb
// (i.e. codeblocks, headers, latex)
struct MarkdownView: View {
    @Binding var markdown: String
    @State private var lines: [MarkdownLine] = []
    
    init(_ md: Binding<String>) {
        self._markdown = md
    }
    
    init(_ md: String) {
        self._markdown = .constant(md)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(lines) { line in
//                if line.type == .includesLatex {
//                    let split = line.content.split(separator: "$$")
//                    HStack {
//                        MarkdownLineView(line: MarkdownLine(type: .regular, content: String(split[safe: 0] ?? "")))
//                        LaTeX(String(split[safe: 1] ?? ""))
//                            .errorMode(.original)
//                        MarkdownLineView(line: MarkdownLine(type: .regular, content: String(split[safe: 2] ?? "")))
//                    }
//                } else if line.type == .includesWeirdLatex {
//                    let split = line.content.split(separator: "$")
//                    HStack {
//                        MarkdownLineView(line: MarkdownLine(type: .regular, content: String(split[safe: 0] ?? "")))
//                        LaTeX(String(split[safe: 1] ?? ""))
//                            .errorMode(.original)
//                        MarkdownLineView(line: MarkdownLine(type: .regular, content: String(split.last ?? "")))
//                    }
//                } else {
                    MarkdownLineView(line: line)
//                }
            }
        }
        .textSelection(.enabled)
        .animation(.default, value: lines)
        .onChange(of: markdown) {
            lines = parseMD(markdown)
        }
        .onAppear {
            lines = parseMD(markdown)
        }
    }
}

struct MarkdownLineView: View {
    public var line: MarkdownLine
    var body: some View {
        switch line.type {
        case .h1:
            Text(line.content)
                .font(.title)
        case .h2:
            Text(line.content)
                .font(.title2)
        case .h3:
            Text(line.content)
                .font(.title3)
        case .h4:
            Text(line.content)
                .font(.headline)
        case .codeblock:
            Text(line.content)
                .font(.system(.body, design: .monospaced))
        case .codeblockTitle:
            Text(line.content)
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .latex:
            LaTeX(line.content)
                .errorMode(.rendered)
                .parsingMode(.all)
        case .includesLatex:
            LaTeX(line.content)
                .errorMode(.original)
                .parsingMode(.onlyEquations)
        default:
            Text((try? AttributedString(markdown: line.content)) ?? AttributedString(stringLiteral: line.content))
        }
    }
}

struct MarkdownLine: Identifiable, Equatable, Hashable {
    var id = UUID()
    var type: MarkdownLineType
    var content: String
}

func parseMD(_ markdown: String) -> [MarkdownLine] {
    let lines = markdown.components(separatedBy: "\n")
    var parsedLines: [MarkdownLine] = []
    
    var withinCodeblock = false
    var withinLatex = false
    
    for line in lines {
        if withinCodeblock {
            if line.starts(with: "```") {
                withinCodeblock = false
            }
            parsedLines.append(MarkdownLine(type: .codeblock, content: line))
        } else if withinLatex {
            if line.starts(with: "$$") {
                withinLatex = false
            }
            parsedLines.append(MarkdownLine(type: .latex, content: line))
        } else if line.starts(with: "# ") {
            parsedLines.append(MarkdownLine(type: .h1, content: String(line.dropFirst(2))))
        } else if line.starts(with: "## ") {
            parsedLines.append(MarkdownLine(type: .h2, content: String(line.dropFirst(3))))
        } else if line.starts(with: "### ") {
            parsedLines.append(MarkdownLine(type: .h3, content: String(line.dropFirst(4))))
        } else if line.starts(with: "#### ") {
            parsedLines.append(MarkdownLine(type: .h4, content: String(line.dropFirst(5))))
        } else if line == "```" {
            //            parsedLines.append(MarkdownLine(type: .codeblock, content: line))
            withinCodeblock = true
        } else if line.starts(with: "```") {
            parsedLines.append(MarkdownLine(type: .codeblockTitle, content: String(line.dropFirst(3))))
            withinCodeblock = true
        } else if line == "$$" || line == "$" { // some models really like to use single even if the system prompt instructs otherwise.
            //            parsedLines.append(MarkdownLine(type: .latex, content: line))
            withinLatex = true
        } else if (line.starts(with: "$$") && line.hasSuffix("$$")) {
            parsedLines.append(MarkdownLine(type: .latex, content: String(line.dropFirst(2).dropLast(2))))
        } else if ((line.starts(with: "$") && line.hasSuffix("$"))) {
            parsedLines.append(MarkdownLine(type: .latex, content: String(line.dropFirst().dropLast())))
        } else if line.contains("$$") || line.contains("$"){
            parsedLines.append(MarkdownLine(type: .includesLatex, content: line))
        } else {
            parsedLines.append(MarkdownLine(type: .regular, content: line))
        }
    }
    print(parsedLines)
    return parsedLines
}

enum MarkdownLineType: Equatable {
    case h1,h2,h3,h4,codeblock,codeblockTitle,regular,includesLatex,latex
}

#Preview {
    MarkdownView("""
# Heading 1
Body
## Heading 2
**Bold** *Italic* `Code`
### Heading 3
$$\\sqrt{2}$$
$\\sqrt{2}$

""")
}
