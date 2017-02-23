#
# This is a simple Makefile for the e-comments repository, it is
# used solely for development purposes.
#
#


#
# NOP
#
nop:
	@echo "This Makefile is for development purposes only."
	@echo " "
	@echo "Valid targets:"
	@echo " "
	@echo "make format - Pretty-print the client-side javascript."
	@echo "make test   - Run the test-cases. "
	@true


#
# Pretty-Print the code.  Install js-beautify via:
#
#    # apt-get install jsbeautifier
#
format:
	@if ( test -x /usr/bin/js-beautify ) ; then /usr/bin/js-beautify -r client/js/e-comments.js ; fi


#
# Run the minimal test-cases.
#
test:
	./tests/runner
