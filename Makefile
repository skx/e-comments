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
	@echo "make serve  - Start the server running, using redis for storage."
	@echo "make format - Pretty-print the client-side javascript."
	@echo "make minify - Build the minified version of the client-side javascript."
	@echo "make test   - Run the test-cases. "
	@true

#
# Start the server
#
# If `bundle` is detected then launch via that - on the assumption the
# user has run `bundle install --path=./vendor/gems/
#
# Otherwise launche natively.
#
serve:
	if ( which bundle >/dev/null 2>/dev/null ) ; then bundle exec ./server/comments.rb --redis ; else   ./server/comments.rb --redis  ; fi


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
