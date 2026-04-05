import SwiftUI

/// Simple markdown renderer using SwiftUI Text views
struct MarkdownText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(attributedString)
    }
    
    private var attributedString: AttributedString {
        var result = AttributedString()
        
        // Process line by line to handle block elements
        let lines = text.components(separatedBy: "\n")
        
        for (index, line) in lines.enumerated() {
            let processedLine = processLine(line)
            result.append(processedLine)
            
            // Add newline if not the last line
            if index < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }
        
        return result
    }
    
    private func processLine(_ line: String) -> AttributedString {
        // Code block markers (```)
        if line.hasPrefix("```") {
            var attr = AttributedString(line)
            attr.font = .system(.body, design: .monospaced)
            attr.backgroundColor = Color.gray.opacity(0.2)
            return attr
        }
        
        // Headers
        if line.hasPrefix("# ") {
            var attr = AttributedString(String(line.dropFirst(2)))
            attr.font = .title2.bold()
            return attr
        }
        if line.hasPrefix("## ") {
            var attr = AttributedString(String(line.dropFirst(3)))
            attr.font = .title3.bold()
            return attr
        }
        if line.hasPrefix("### ") {
            var attr = AttributedString(String(line.dropFirst(4)))
            attr.font = .headline.bold()
            return attr
        }
        
        // Bullet lists
        if line.hasPrefix("- ") || line.hasPrefix("* ") {
            var attr = AttributedString("• " + String(line.dropFirst(2)))
            return processInlineStyles(attr)
        }
        
        // Numbered lists
        if let match = line.range(of: "^\\d+\\. ", options: .regularExpression) {
            let prefix = String(line[match])
            let rest = String(line[match.upperBound...])
            var attr = AttributedString(prefix + rest)
            return processInlineStyles(attr)
        }
        
        // Regular line with inline styles
        var attr = AttributedString(line)
        return processInlineStyles(attr)
    }
    
    private func processInlineStyles(_ input: AttributedString) -> AttributedString {
        var result = input
        
        // Bold: **text**
        result = applyPattern(&result, pattern: "\\*\\*(.+?)\\*\\*") { str, range in
            var attr = AttributedString(str[range])
            attr.font = .body.bold()
            return attr
        }
        
        // Italic: *text* or _text_
        result = applyPattern(&result, pattern: "(?<![*])\\*(?![*])(.+?)(?<![*])\\*(?![*])") { str, range in
            var attr = AttributedString(str[range])
            attr.font = .body.italic()
            return attr
        }
        
        // Inline code: `code`
        result = applyPattern(&result, pattern: "`([^`]+)`") { str, range in
            var attr = AttributedString(str[range])
            attr.font = .system(.body, design: .monospaced)
            attr.backgroundColor = Color.gray.opacity(0.15)
            return attr
        }
        
        // Links: [text](url)
        result = applyPattern(&result, pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)") { str, range in
            var attr = AttributedString(str[range])
            attr.foregroundColor = .blue
            attr.underlineStyle = .single
            return attr
        }
        
        return result
    }
    
    private func applyPattern(
        _ input: AttributedString,
        pattern: String,
        transform: (String, Range<String.Index>) -> AttributedString
    ) -> AttributedString {
        let string = String(input.characters)
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return input
        }
        
        var result = AttributedString()
        var lastEnd = string.startIndex
        
        let nsRange = NSRange(string.startIndex..., in: string)
        let matches = regex.matches(in: string, range: nsRange)
        
        for match in matches {
            guard let range = Range(match.range, in: string) else { continue }
            let matchRange = Range(match.range(at: 1), in: string) ?? range
            
            // Append text before match
            result.append(AttributedString(string[lastEnd..<range.lowerBound]))
            
            // Transform the match
            let transformed = transform(string, matchRange)
            result.append(transformed)
            
            lastEnd = range.upperBound
        }
        
        // Append remaining text
        if lastEnd < string.endIndex {
            result.append(AttributedString(string[lastEnd...]))
        }
        
        return result
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        MarkdownText("**Bold text**")
        MarkdownText("*Italic text*")
        MarkdownText("`inline code`")
        MarkdownText("# Header 1")
        MarkdownText("## Header 2")
        MarkdownText("- Bullet item")
        MarkdownText("1. Numbered item")
        MarkdownText("**Bold** and *italic* together")
        MarkdownText("[Link](https://example.com)")
        MarkdownText("```\ncode block\n```")
    }
    .padding()
}
