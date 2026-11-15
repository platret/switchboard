import XCTest

final class MarkdownParserTests: XCTestCase {
    func testHeadingsParagraphsAndRules() {
        let blocks = MarkdownParser.parse("# Title\n\nFirst line\nsecond line\n\n---\n\n### Sub ##\ntext")
        XCTAssertEqual(blocks, [
            .heading(level: 1, text: "Title"),
            .paragraph("First line\nsecond line"),
            .rule,
            .heading(level: 3, text: "Sub"),
            .paragraph("text"),
        ])
    }

    func testListsWithNestingAndContinuation() {
        let blocks = MarkdownParser.parse("- one\n  - nested\n    more text\n- two\n\n1. first\n2. second\n   - child\n\n**bold** is not a list\n#hashtag")
        XCTAssertEqual(blocks, [
            .bulletList([
                MarkdownListItem(level: 0, number: nil, text: "one"),
                MarkdownListItem(level: 1, number: nil, text: "nested\nmore text"),
                MarkdownListItem(level: 0, number: nil, text: "two"),
            ]),
            .numberedList([
                MarkdownListItem(level: 0, number: 1, text: "first"),
                MarkdownListItem(level: 0, number: 2, text: "second"),
                MarkdownListItem(level: 1, number: nil, text: "child"),
            ]),
            .paragraph("**bold** is not a list\n#hashtag"),
        ])
    }

    func testCodeBlocks() {
        let blocks = MarkdownParser.parse("Run this:\n```bash title\npnpm test\n\n# not a heading\n```\nDone\n~~~\nplain\n~~~")
        XCTAssertEqual(blocks, [
            .paragraph("Run this:"),
            .code(language: "bash", text: "pnpm test\n\n# not a heading"),
            .paragraph("Done"),
            .code(language: nil, text: "plain"),
        ])
    }

    func testUnfinishedCodeBlockWhileStreaming() {
        XCTAssertEqual(MarkdownParser.parse("```swift\nlet a = 1"), [.code(language: "swift", text: "let a = 1")])
        XCTAssertEqual(MarkdownParser.parse("  ```\n  indented\n  ```"), [.code(language: nil, text: "indented")])
    }

    func testQuotesAndTables() {
        let blocks = MarkdownParser.parse("> quoted\n> more\n\n| Name | Value |\n|---|:--:|\n| a | 1 |\n| b \\| c |\nafter | pipe")
        XCTAssertEqual(blocks, [
            .quote("quoted\nmore"),
            .table(header: ["Name", "Value"], rows: [["a", "1"], ["b | c", ""], ["after", "pipe"]]),
        ])
        XCTAssertEqual(MarkdownParser.parse("a | b"), [.paragraph("a | b")])
    }

    func testEmptyAndWindowsLineEndings() {
        XCTAssertEqual(MarkdownParser.parse(""), [])
        XCTAssertEqual(MarkdownParser.parse("a\r\n\r\nb"), [.paragraph("a"), .paragraph("b")])
    }

    func testInlineMarkdown() {
        XCTAssertEqual(InlineMarkdown.plain("Use **bold**, *italic* and `code` [link](https://example.test)"), "Use bold, italic and code link")
        XCTAssertEqual(InlineMarkdown.plain("unfinished **bold"), "unfinished **bold")
        let link = InlineMarkdown.attributed("[link](https://example.test)")
        XCTAssertEqual(link.runs.first?.link, URL(string: "https://example.test"))
    }
}
