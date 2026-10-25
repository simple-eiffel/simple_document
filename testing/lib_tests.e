note
	description: "[
		Tests for simple_document: DOC_TEXT's spans, flags and stretches;
		DOC_BLOCK kinds, tables and equality; SIMPLE_DOCUMENT's numbering,
		plain text and editing (insert, replace, remove). Contracts run on
		every call; the assertions check behavior on top.
	]"
	author: "Larry Rix"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- DOC_TEXT

	test_flags_and_stretches
			-- Overlapping spans answer as one set of bits per character,
			-- and the stretches of one setting are found.
		local
			r: DOC_TEXT
		do
			create r.make ("abcdefghijklmnop")
			r.add_bold (1, 8)
			r.add_italic (5, 8)
			r.add_link (10, 5, "John 3:16")
			assert_integers_equal ("bold at 1", r.Flag_bold, r.flags_at (1))
			assert_integers_equal ("bold italic at 6", r.Flag_bold | r.Flag_italic, r.flags_at (6))
			assert_integers_equal ("italic link at 11", r.Flag_italic | r.Flag_link, r.flags_at (11))
			assert_integers_equal ("link alone at 14", r.Flag_link, r.flags_at (14))
			assert_integers_equal ("plain after", 0, r.flags_at (15))
			assert_integers_equal ("the bold stretch ends at 4", 4, r.stretch_end (1))
			assert_integers_equal ("bold italic 5 .. 8", 8, r.stretch_end (5))
			assert_integers_equal ("italic 9", 9, r.stretch_end (9))
			assert_integers_equal ("italic link 10 .. 12", 12, r.stretch_end (10))
			assert_integers_equal ("plain runs to the end", 16, r.stretch_end (15))
			assert_integers_equal ("the link is found", 3, r.link_at (12))
			assert_true ("its target kept", r.span_target (3).same_string ("John 3:16"))
			assert_true ("a flag per kind", r.flag_of (r.Kind_strike) = r.Flag_strike and r.flag_of (r.Kind_code) = r.Flag_code)
		end

	test_set_text_cuts_spans
		local
			r: DOC_TEXT
		do
			create r.make ("abcdefghijklmnop")
			r.add_bold (1, 8)
			r.add_link (10, 5, "x")
			r.set_text ("abcdefghij")
			assert_integers_equal ("the link cut to the end", 1, r.span_length (2))
			r.set_text ("abc")
			assert_integers_equal ("the link past the end went", 1, r.span_count)
			assert_integers_equal ("the bold cut", 3, r.span_length (1))
			r.remove_spans
			assert_integers_equal ("plain", 0, r.span_count)
		end

	test_take_copies
			-- `take' copies the characters and spans, and the copy is apart.
		local
			a, b: DOC_TEXT
		do
			create a.make ("see John 3:16")
			a.add_link (5, 9, "John 3:16")
			a.add_bold (1, 3)
			create b.make ("old")
			b.take (a)
			assert_true ("the same", b.is_same_as (a))
			a.set_text ("changed")
			assert_true ("apart", b.text.same_string ("see John 3:16") and b.span_count = 2)
		end

	test_unicode_text_kept
			-- Pointed Hebrew and polytonic Greek are held as typed.
		local
			r: DOC_TEXT
			s: STRING_32
		do
			create s.make (8)
			s.append_code (0x05D1)
			s.append_code (0x05BC)
			s.append_code (0x05B0)
			s.append_character (' ')
			s.append_code (0x1F18)
			s.append_code (0x03BD)
			create r.make (s)
			assert_integers_equal ("six characters", 6, r.count)
			assert_true ("as typed", r.text.same_string (s))
			r.add_bold (1, 3)
			assert_integers_equal ("a span over a pointed letter", 3, r.stretch_end (1))
		end

feature -- SIMPLE_DOCUMENT

	test_numbers_and_plain_text
			-- Numbered items count within their run and depth; the plain
			-- text has bullets, numbers, a code block and a table's tabs.
		local
			d: SIMPLE_DOCUMENT
			t: DOC_BLOCK
			l_expected: STRING_32
		do
			create d.make
			d.add_heading (1, "Notes").do_nothing
			d.add_numbered (1, "one").do_nothing
			d.add_bullet (2, "inner").do_nothing
			d.add_numbered (1, "two").do_nothing
			d.add_paragraph ("break").do_nothing
			d.add_numbered (1, "again").do_nothing
			d.add_rule
			d.add_code_block ("x := 1%Ny := 2").do_nothing
			t := d.add_table (<<"Word", "Gloss">>)
			t.add_row (<<"bara", "create">>)
			assert_integers_equal ("first", 1, d.number_of (2))
			assert_integers_equal ("a deeper item does not break the run", 2, d.number_of (4))
			assert_integers_equal ("a paragraph restarts it", 1, d.number_of (6))
			assert_integers_equal ("not numbered", 0, d.number_of (3))
			create l_expected.make (80)
			l_expected.append ("Notes%N1. one%N")
			l_expected.append_code (0x2022)
			l_expected.append (" inner%N2. two%Nbreak%N1. again%N%Nx := 1%Ny := 2%NWord%TGloss%Nbara%Tcreate")
			assert_strings_equal ("plain text", l_expected, d.plain_text)
		end

	test_insert_replace_remove
			-- An edited block can become two, or none; every change bumps
			-- the revision.
		local
			d: SIMPLE_DOCUMENT
			l_new: ARRAYED_LIST [DOC_BLOCK]
			l_rev: INTEGER
		do
			create d.make
			d.add_paragraph ("one").do_nothing
			d.add_paragraph ("three").do_nothing
			l_rev := d.revision
			d.insert (create {DOC_BLOCK}.make ({DOC_BLOCK}.Kind_paragraph, 1, "two"), 2)
			assert_true ("inserted in the middle", d.block (2).content.text.same_string ("two") and d.count = 3)
			assert_true ("revision grew", d.revision > l_rev)
			create l_new.make (2)
			l_new.extend (create {DOC_BLOCK}.make ({DOC_BLOCK}.Kind_heading, 2, "Two"))
			l_new.extend (create {DOC_BLOCK}.make ({DOC_BLOCK}.Kind_paragraph, 1, "and a half"))
			d.replace (2, l_new)
			assert_integers_equal ("one became two", 4, d.count)
			assert_integers_equal ("a heading now", {DOC_BLOCK}.Kind_heading, d.block (2).kind)
			assert_true ("in order", d.block (3).content.text.same_string ("and a half")
				and d.block (4).content.text.same_string ("three"))
			d.replace (4, create {ARRAYED_LIST [DOC_BLOCK]}.make (0))
			assert_integers_equal ("replaced by nothing: gone", 3, d.count)
			d.insert (create {DOC_BLOCK}.make ({DOC_BLOCK}.Kind_rule, 1, ""), 4)
			assert_integers_equal ("inserted at the end", {DOC_BLOCK}.Kind_rule, d.block (4).kind)
			d.remove (1)
			assert_true ("removed the first", d.block (1).kind = {DOC_BLOCK}.Kind_heading)
		end

	test_sameness
			-- Two documents built alike are the same; a span, a kind or a
			-- cell apart, they are not.
		local
			a, b: SIMPLE_DOCUMENT
		do
			a := built
			b := built
			assert_true ("built alike", a.is_same_as (b))
			b.block (1).content.add_italic (1, 2)
			assert_false ("a span apart", a.is_same_as (b))
			b := built
			b.block (2).set_kind ({DOC_BLOCK}.Kind_quote, 1)
			assert_false ("a kind apart", a.is_same_as (b))
			b := built
			b.block (3).cell (2, 2).set_text ("make")
			assert_false ("a cell apart", a.is_same_as (b))
		end

feature {NONE} -- Fixtures

	built: SIMPLE_DOCUMENT
		local
			t: DOC_BLOCK
		do
			create Result.make
			Result.add_paragraph ("For God so loved").add_link (1, 16, "John 3:16")
			Result.add_paragraph ("plain").do_nothing
			t := Result.add_table (<<"Word", "Gloss">>)
			t.add_row (<<"bara", "create">>)
		end

end
