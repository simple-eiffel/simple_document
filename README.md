# simple_document

![Windows: tests pass](https://img.shields.io/badge/Windows-tests%20pass-0078D6?logo=windows&logoColor=white) ![Linux: tests pass](https://img.shields.io/badge/Linux-tests%20pass-FCC624?logo=linux&logoColor=black) ![macOS: tests pass](https://img.shields.io/badge/macOS-tests%20pass-000000?logo=apple&logoColor=white)

A rich document model for the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem: Unicode text in blocks, with inline styles and links. No markup and no rendering - one model for every library that reads, shows or writes a rich document.

> **Status: 0.1.0 pre-release.** Made for simple_bible (gap GW-13): commentaries, lexicon entries, dictionary articles and notes.

## What it holds

- `SIMPLE_DOCUMENT` - an ordered list of blocks, with `number_of` (a numbered item's number), `plain_text`, and editing: `add_*`, `insert`, `replace`, `remove`.
- `DOC_BLOCK` - a paragraph, a heading (levels 1 to 3), a bulleted or numbered item or a block quote (depths 1 to 3), a rule, a code block, or a table (a header row, then rows of cells).
- `DOC_TEXT` - the characters of one text and the spans over them: bold, italic, small capitals, superscript, code, strikethrough, and links with a target. `flags_at` answers every kind over a character as one set of bits and `stretch_end` where that set changes, so a renderer walks the text one setting at a time.

```eiffel
local
    doc: SIMPLE_DOCUMENT
    t: DOC_BLOCK
do
    create doc.make
    doc.add_heading (1, "Notes").do_nothing
    doc.add_paragraph ("For God so loved the world").add_link (1, 26, "John 3:16")
    t := doc.add_table (<<"Word", "Gloss">>)
    t.add_row (<<"bara", "create">>)
    print (doc.plain_text)
end
```

## Who uses it

- **simple_markdown** reads Markdown into a document and writes one back out.
- **simple_widgets** shows and edits one (`SW_DOCUMENT_VIEW`).
- A host builds one from other sources (simple_bible: a commentary's HTML).

## Building and testing

```bash
/d/prod/ec.sh test -config simple_document.ecf -target simple_document_tests
./EIFGENs/simple_document_tests/F_code/simple_document.exe
```

Depends only on EiffelBase. Void-safe, SCOOP-compatible, every class with contracts. 7 tests pass at 0.1.0.

## License

MIT (`LICENSE`).
