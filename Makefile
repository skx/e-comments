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
	@echo "make serve  - Start the server running, using redis for storage"
	@echo "make format - Pretty-print the client-side javascript"
	@echo "make minify - Build the minified version of the client-side javascript"
	@echo " "
	@true

#
# Start the server
#
serve:
	STORAGE=redis ./server/comments.rb

#
# Pretty-Print the code.  Install js_beautify via:
#
#    apt-get install libjavascript-beautifier-perl
#
format:
	@if ( test -x /usr/bin/js_beautify ) ; then /usr/bin/js_beautify -o client/js/e-comments.js ; fi

#
# Produce a minified version of the client-side code.
#
# To run this:
#
#    apt-get install libjavascript-minifier-perl
#
minify:
	@if ( test -x ./utils/minify ) ; then ./utils/minify ; fi


#
# Run the minimal test-cases.
#
test:
	./tests/runner
