note
	description: "Test application for simple_document."
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			print ("Running SIMPLE_DOCUMENT tests...%N%N")
			create lib_tests
			run_test (agent lib_tests.test_flags_and_stretches, "flags_and_stretches")
			run_test (agent lib_tests.test_set_text_cuts_spans, "set_text_cuts_spans")
			run_test (agent lib_tests.test_unicode_text_kept, "unicode_text_kept")
			run_test (agent lib_tests.test_numbers_and_plain_text, "numbers_and_plain_text")
			run_test (agent lib_tests.test_insert_replace_remove, "insert_replace_remove")
			run_test (agent lib_tests.test_sameness, "sameness")
			print ("%NResults: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Implementation

	lib_tests: LIB_TESTS

	passed, failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			if attached (create {EXCEPTION_MANAGER}).last_exception as al_exception then
				if attached al_exception.tag as al_tag then
					print ("        tag: " + al_tag.to_string_8 + "%N")
				end
				if attached al_exception.description as al_text then
					print ("        why: " + al_text.to_string_8 + "%N")
				end
			end
			failed := failed + 1
			l_retried := True
			retry
		end

end
