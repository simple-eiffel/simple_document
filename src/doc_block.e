note
	description: "[
		One block of a SIMPLE_DOCUMENT: a paragraph, a heading (level
		1 .. 3), a bulleted or numbered list item (depth 1 .. 3), a block
		quote (depth 1 .. 3), a rule, a code block, or a table. Every
		kind but the rule and the table holds one DOC_TEXT (`content'); a
		code block's text is shown as typed, its line breaks kept, with
		no inline spans. A table holds rows of cells, each a DOC_TEXT,
		the first row being the header when `has_header'.

		A numbered item does not store its number: a renderer counts the
		run of numbered items it stands in (SIMPLE_DOCUMENT.number_of).
	]"
	author: "Larry Rix"

class
	DOC_BLOCK

create
	make, make_table

feature {NONE} -- Initialization

	make (a_kind, a_level: INTEGER; a_text: READABLE_STRING_GENERAL)
			-- A block of `a_kind' at `a_level' holding `a_text'.
		require
			kind_valid: is_valid_kind (a_kind) and a_kind /= Kind_table
			level_valid: a_level >= 1 and a_level <= Max_level
		do
			kind := a_kind
			level := a_level
			create content.make (a_text)
			create rows.make (0)
		ensure
			kind_set: kind = a_kind
			level_set: level = a_level
			text_kept: content.text.same_string_general (a_text)
		end

	make_table (a_header: ARRAY [READABLE_STRING_GENERAL])
			-- A table whose header row reads `a_header'; one column each.
		require
			has_columns: a_header.count > 0
		do
			kind := Kind_table
			level := 1
			create content.make ({STRING_32} "")
			create rows.make (4)
			has_header := True
			column_count := a_header.count
			add_row (a_header)
		ensure
			table: kind = Kind_table
			columns: column_count = a_header.count
			header_row: row_count = 1 and has_header
		end

feature -- Constants

	Kind_paragraph: INTEGER = 1
	Kind_heading: INTEGER = 2
	Kind_bullet: INTEGER = 3
	Kind_numbered: INTEGER = 4
	Kind_quote: INTEGER = 5
	Kind_rule: INTEGER = 6
	Kind_table: INTEGER = 7
	Kind_code_block: INTEGER = 8

	Max_level: INTEGER = 3

	is_valid_kind (a_kind: INTEGER): BOOLEAN
		do
			Result := a_kind >= Kind_paragraph and a_kind <= Kind_code_block
		end

feature -- Access

	kind: INTEGER

	level: INTEGER
			-- A heading's level, a list item's or a quote's depth; 1 for
			-- the rest.

	content: DOC_TEXT
			-- The text of every kind but the rule and the table (empty
			-- for those two).

	has_header: BOOLEAN
			-- Is a table's first row its header?

	column_count: INTEGER
			-- A table's columns; 0 for every other kind.

	row_count: INTEGER
			-- A table's rows, the header included.
		do
			Result := rows.count
		end

	cell (a_row, a_column: INTEGER): DOC_TEXT
		require
			table: kind = Kind_table
			row_valid: a_row >= 1 and a_row <= row_count
			column_valid: a_column >= 1 and a_column <= column_count
		do
			Result := rows.i_th (a_row).i_th (a_column)
		end

	revision: INTEGER
			-- Grows whenever any text of the block changes.
		do
			Result := content.revision + own_revision
			across rows as r loop
				across r as c loop
					Result := Result + c.revision
				end
			end
		ensure
			non_negative: Result >= 0
		end

	is_text_kind: BOOLEAN
			-- Does the block show `content'?
		do
			Result := kind /= Kind_rule and kind /= Kind_table
		end

	is_list_item: BOOLEAN
		do
			Result := kind = Kind_bullet or kind = Kind_numbered
		end

	is_same_as (a_other: DOC_BLOCK): BOOLEAN
			-- Does `a_other' hold the same kind, level, text, spans and
			-- cells?
		local
			r, c: INTEGER
		do
			Result := kind = a_other.kind and level = a_other.level and has_header = a_other.has_header
				and content.is_same_as (a_other.content) and row_count = a_other.row_count
				and column_count = a_other.column_count
			from
				r := 1
			until
				not Result or r > row_count
			loop
				from
					c := 1
				until
					not Result or c > column_count
				loop
					Result := cell (r, c).is_same_as (a_other.cell (r, c))
					c := c + 1
				end
				r := r + 1
			end
		end

feature -- Element change

	add_row (a_cells: ARRAY [READABLE_STRING_GENERAL])
			-- Another row of a table, one cell per column.
		require
			table: kind = Kind_table
			one_per_column: a_cells.count = column_count
		local
			l_row: ARRAYED_LIST [DOC_TEXT]
		do
			create l_row.make (column_count)
			across a_cells as c loop
				l_row.extend (create {DOC_TEXT}.make (c))
			end
			rows.extend (l_row)
			own_revision := own_revision + 1
		ensure
			one_more: row_count = old row_count + 1
		end

	set_kind (a_kind, a_level: INTEGER)
			-- Make a text block another text kind: a paragraph a heading,
			-- an item a quote. The text and its spans stay.
		require
			text_kinds: is_text_kind and a_kind /= Kind_rule and a_kind /= Kind_table
				and is_valid_kind (a_kind)
			level_valid: a_level >= 1 and a_level <= Max_level
		do
			kind := a_kind
			level := a_level
			own_revision := own_revision + 1
		ensure
			kind_set: kind = a_kind
			level_set: level = a_level
		end

feature {NONE} -- Implementation

	rows: ARRAYED_LIST [ARRAYED_LIST [DOC_TEXT]]

	own_revision: INTEGER

invariant
	kind_valid: is_valid_kind (kind)
	level_valid: level >= 1 and level <= Max_level
	columns_iff_table: (column_count > 0) = (kind = Kind_table)
	rows_only_in_tables: kind /= Kind_table implies rows.is_empty

end
