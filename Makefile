VERSION=1.0.0
MANDOC=mandoc
MANFLAGS+=-I os=$(VERSION)
MANSTYLE=http://mandoc.bsd.lv/mandoc.css
# MD_FRIENDLY_HTML=./md-friendly-html.pl
MD_FRIENDLY_HTML=nix-shell --pure --run ./md-friendly-html.pl
.DEFAULT_GOAL=all

Semver.3sh: Semver.3sh.mdoc
	$(MANDOC) $(MANFLAGS) -T man $< > $@

README.md: README-preamble.md Semver.3sh.mdoc md-friendly-html.pl
	$(MANDOC) $(MANFLAGS) -T html -O 'fragment,style=$(MANSTYLE)' Semver.3sh.mdoc | \
	    $(MD_FRIENDLY_HTML) | \
	    cat README-preamble.md - > $@

all: Semver.3sh README.md

man: Semver.3sh
	@exec man -l ./Semver.3sh

man-mdoc: Semver.3sh.mdoc
	@exec man -l ./Semver.3sh.mdoc

clean:
	rm Semver.3sh README.md

test:
	./test.sh

.PHONY: all man man-mdoc clean test
