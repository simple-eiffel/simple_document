# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added (0.1.0 - THE MODEL; for simple_bible GW-13)

Larry chose one neutral model for rich documents, so that Markdown notes can
be read, shown, edited and written back without two models or a grammar in two
libraries. The classes moved here from simple_widgets 0.21.0 (SW_DOCUMENT,
SW_DOC_BLOCK, SW_RICH_TEXT), which had no outside users yet.

- `SIMPLE_DOCUMENT`, `DOC_BLOCK`, `DOC_TEXT`, all Unicode.
- New against the widget version: code blocks; inline code and
  strikethrough; `flags_at` and `stretch_end` in place of the shaping-specific
  styles (this library knows nothing of drawing); `insert`, `replace` and
  `add_block` for an editor; `is_same_as` on all three for round-trip tests.
- Tests: flags and stretches over overlapping spans, cutting spans on a text
  change, pointed Hebrew and polytonic Greek held as typed, numbering and plain
  text, insert / replace / remove, and sameness. 6 pass.
