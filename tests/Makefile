# Prefix of all clip test cases
CLIP_TESTS=$(patsubst %.tcl,%,$(wildcard t*-*.tcl))

all: units $(CLIP_TESTS)
png: $(patsubst %.ps,%.png,$(wildcard results/*/*.ps))

# Unit tests for core procs
units:
	./units.tcl

# Clipping test for different cases
t%:
	./$@*

# Convert postscript to png with ghostscript
%.png: %.ps
	gs -dSAFER -sDEVICE=png16m -dGraphicsAlphaBits=4 -dFitPage -g300x300 -o $@ $^

clean_png:
	$(RM) results/*/*.png

clean: clean_png
	$(RM) results/*/*.ps
