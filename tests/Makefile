# Prefix of all clip test cases
CLIP_TESTS=$(patsubst %.tcl,%,$(wildcard t*-*.tcl))

all: avlunits units $(CLIP_TESTS)
png: $(patsubst %.ps,%.png,$(wildcard results/*/*.ps))

# Unit tests for core procs
avlunits:
	./avlunits.tcl

units:
	./units.tcl

# Clipping test for different cases
t%:
	./$@*

# Convert postscript to png with ghostscript
results/t19-worldmap-50/%.png: results/t19-worldmap-50/%.ps
	gs -dSAFER -sDEVICE=png16m -dTextAlphaBits=4 -dGraphicsAlphaBits=1 -dFitPage -g860x460 -o $@ $^

%.png: %.ps
	gs -dSAFER -sDEVICE=png16m -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -dFitPage -g200x200 -o $@ $^

clean_png:
	$(RM) results/*/*.png

clean: clean_png
	$(RM) results/*/*.ps
