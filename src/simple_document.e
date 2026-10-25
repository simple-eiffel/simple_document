note
	description: "[
		A rich document, independent of any markup and any screen: an
		ordered list of DOC_BLOCKs - paragraphs, headings, list items,
		quotes, rules, code blocks and tables - each holding DOC_TEXT
		with inline bold, italic, small capitals, superscript, code,
		strikethrough and links.

		One model for every producer and consumer: simple_markdown reads
		Markdown into one and writes one back out, simple_widgets shows
		and edits one (SW_DOCUMENT_VIEW), and a host builds one from a
		commentary's HTML. Each add_* returns the new block's text so its
		spans can be added at once:

		    doc.add_paragraph ("For God so loved").add_link (1, 16, "John 3:16")

		`plain_text' is the document as plain text (what Copy gives).
	]"
	author: "Larry Rix"

class
	SIMPLE_DOCUMENT

create
	make

feature {NONE} -- Initialization

	make
			-- No blocks.
		do
			create blocks.make (16)
		ensure
			empty: count = 0
		end

feature -- Access

	count: INTEGER
			-- Blocks.
		do
			Result := blocks.count
		end

	block (a_i: INTEGER): DOC_BLOCK
		require
			in_range: a_i >= 1 and a_i <= count
		do
			Result := blocks.i_th (a_i)
		end

	revision: INTEGER
			-- Grows when blocks are added, removed or replaced (a block's
			-- own text changes show in DOC_BLOCK.revision).

	number_of (a_i: INTEGER): INTEGER
			-- The number numbered item `a_i' shows: one more than the item
			-- above it at its depth, counting from 1 after anything that is
			-- not a list item or deeper. 0 for a block that is not a
			-- numbered item.
		require
			in_range: a_i >= 1 and a_i <= count
		local
			j: INTEGER
			l_done: BOOLEAN
		do
			if blocks.i_th (a_i).kind = {DOC_BLOCK}.Kind_numbered then
				Result := 1
				from
					j := a_i - 1
				until
					j < 1 or l_done
				loop
					if not blocks.i_th (j).is_list_item or else blocks.i_th (j).level < blocks.i_th (a_i).level then
						l_done := True
					elseif blocks.i_th (j).level = blocks.i_th (a_i).level then
						if blocks.i_th (j).kind = {DOC_BLOCK}.Kind_numbered then
							Result := Result + 1
						else
							l_done := True
						end
					end
					j := j - 1
				end
			end
		ensure
			numbered_only: (Result > 0) = (block (a_i).kind = {DOC_BLOCK}.Kind_numbered)
		end

	plain_text: STRING_32
			-- Every block as plain text, one per line: items with their
			-- bullet or number, a table's cells joined by tabs, a rule as an
			-- empty line.
		local
			i: INTEGER
		do
			create Result.make (256)
			from
				i := 1
			until
				i > count
			loop
				if i > 1 then
					Result.append_character ('%N')
				end
				Result.append (block_text (i))
				i := i + 1
			end
		end

	block_text (a_i: INTEGER): STRING_32
			-- Block `a_i' as plain text (see `plain_text').
		require
			in_range: a_i >= 1 and a_i <= count
		local
			b: DOC_BLOCK
			r, c: INTEGER
		do
			b := blocks.i_th (a_i)
			create Result.make (b.content.count + 4)
			inspect b.kind
			when {DOC_BLOCK}.Kind_bullet then
				Result.append_code (0x2022)
				Result.append_character (' ')
				Result.append (b.content.text)
			when {DOC_BLOCK}.Kind_numbered then
				Result.append_integer (number_of (a_i))
				Result.append ({STRING_32} ". ")
				Result.append (b.content.text)
			when {DOC_BLOCK}.Kind_rule then
			when {DOC_BLOCK}.Kind_table then
				from
					r := 1
				until
					r > b.row_count
				loop
					if r > 1 then
						Result.append_character ('%N')
					end
					from
						c := 1
					until
						c > b.column_count
					loop
						if c > 1 then
							Result.append_character ('%T')
						end
						Result.append (b.cell (r, c).text)
						c := c + 1
					end
					r := r + 1
				end
			else
				Result.append (b.content.text)
			end
		end

	is_same_as (a_other: SIMPLE_DOCUMENT): BOOLEAN
			-- Does `a_other' hold the same blocks, each the same?
		local
			i: INTEGER
		do
			Result := count = a_other.count
			from
				i := 1
			until
				not Result or i > count
			loop
				Result := block (i).is_same_as (a_other.block (i))
				i := i + 1
			end
		end

feature -- Element change

	add_paragraph (a_text: READABLE_STRING_GENERAL): DOC_TEXT
			-- A paragraph reading `a_text'; its text, for spans.
		do
			Result := add_text_block ({DOC_BLOCK}.Kind_paragraph, 1, a_text)
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count).content
		end

	add_heading (a_level: INTEGER; a_text: READABLE_STRING_GENERAL): DOC_TEXT
			-- A heading at `a_level' (1 the largest).
		require
			level_valid: a_level >= 1 and a_level <= {DOC_BLOCK}.Max_level
		do
			Result := add_text_block ({DOC_BLOCK}.Kind_heading, a_level, a_text)
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count).content
		end

	add_bullet (a_depth: INTEGER; a_text: READABLE_STRING_GENERAL): DOC_TEXT
			-- A bulleted item at `a_depth'.
		require
			depth_valid: a_depth >= 1 and a_depth <= {DOC_BLOCK}.Max_level
		do
			Result := add_text_block ({DOC_BLOCK}.Kind_bullet, a_depth, a_text)
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count).content
		end

	add_numbered (a_depth: INTEGER; a_text: READABLE_STRING_GENERAL): DOC_TEXT
			-- A numbered item at `a_depth'.
		require
			depth_valid: a_depth >= 1 and a_depth <= {DOC_BLOCK}.Max_level
		do
			Result := add_text_block ({DOC_BLOCK}.Kind_numbered, a_depth, a_text)
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count).content
		end

	add_quote (a_depth: INTEGER; a_text: READABLE_STRING_GENERAL): DOC_TEXT
			-- A block quote at `a_depth'.
		require
			depth_valid: a_depth >= 1 and a_depth <= {DOC_BLOCK}.Max_level
		do
			Result := add_text_block ({DOC_BLOCK}.Kind_quote, a_depth, a_text)
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count).content
		end

	add_code_block (a_text: READABLE_STRING_GENERAL): DOC_TEXT
			-- A code block showing `a_text' as typed.
		do
			Result := add_text_block ({DOC_BLOCK}.Kind_code_block, 1, a_text)
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count).content
		end

	add_rule
			-- A horizontal rule.
		do
			blocks.extend (create {DOC_BLOCK}.make ({DOC_BLOCK}.Kind_rule, 1, {STRING_32} ""))
			revision := revision + 1
		ensure
			one_more: count = old count + 1
			rule: block (count).kind = {DOC_BLOCK}.Kind_rule
		end

	add_table (a_header: ARRAY [READABLE_STRING_GENERAL]): DOC_BLOCK
			-- A table headed `a_header'; the block, for its rows.
		require
			has_columns: a_header.count > 0
		do
			create Result.make_table (a_header)
			blocks.extend (Result)
			revision := revision + 1
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count)
		end

	add_block (a_block: DOC_BLOCK)
			-- `a_block' at the end.
		do
			blocks.extend (a_block)
			revision := revision + 1
		ensure
			one_more: count = old count + 1
			is_the_last: block (count) = a_block
		end

	insert (a_block: DOC_BLOCK; a_i: INTEGER)
			-- `a_block' becomes block `a_i'; the ones from `a_i' on move down.
		require
			position_valid: a_i >= 1 and a_i <= count + 1
		do
			if a_i = count + 1 then
				blocks.extend (a_block)
			else
				blocks.go_i_th (a_i)
				blocks.put_left (a_block)
			end
			revision := revision + 1
		ensure
			one_more: count = old count + 1
			placed: block (a_i) = a_block
		end

	replace (a_i: INTEGER; a_blocks: LIST [DOC_BLOCK])
			-- Block `a_i' gives way to `a_blocks', in order (none: it goes).
			-- An edited block that became two paragraphs, or a heading.
		require
			in_range: a_i >= 1 and a_i <= count
		local
			k: INTEGER
		do
			blocks.go_i_th (a_i)
			blocks.remove
			k := a_i
			across a_blocks as b loop
				if k = blocks.count + 1 then
					blocks.extend (b)
				else
					blocks.go_i_th (k)
					blocks.put_left (b)
				end
				k := k + 1
			end
			revision := revision + 1
		ensure
			counted: count = old count - 1 + a_blocks.count
		end

	remove (a_i: INTEGER)
			-- Block `a_i' goes; the ones after it move up.
		require
			in_range: a_i >= 1 and a_i <= count
		do
			blocks.go_i_th (a_i)
			blocks.remove
			revision := revision + 1
		ensure
			one_fewer: count = old count - 1
		end

	wipe_out
		do
			blocks.wipe_out
			revision := revision + 1
		ensure
			empty: count = 0
		end

feature {NONE} -- Implementation

	blocks: ARRAYED_LIST [DOC_BLOCK]

	add_text_block (a_kind, a_level: INTEGER; a_text: READABLE_STRING_GENERAL): DOC_TEXT
		require
			text_kind: a_kind /= {DOC_BLOCK}.Kind_rule and a_kind /= {DOC_BLOCK}.Kind_table
			level_valid: a_level >= 1 and a_level <= {DOC_BLOCK}.Max_level
		local
			b: DOC_BLOCK
		do
			create b.make (a_kind, a_level, a_text)
			blocks.extend (b)
			revision := revision + 1
			Result := b.content
		ensure
			one_more: count = old count + 1
			is_the_last: Result = block (count).content
		end

invariant
	blocks_attached: blocks /= Void
	revision_non_negative: revision >= 0

end
