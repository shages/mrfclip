# Tests

## Makefile
`make all` will execute unit tests followed by the clipping tests. Generating PNG images must be run second with `make png` (see below).

## Unit tests
Most core functionality is tested with unit tests in `units.tcl`. Simply execute the script to run the tests.

The unit tests utilize a testing framework - `unitt` - provided in the scripts/ directory.

## Clipping tests
Clipping tests are all standalone scripts beginning with `t`. They require Tk in order to draw the results. They also use a utility proc defined in `scripts/testutils.tcl`, which is used to simplify the test code.

Results are shown on in a GUI and saved to Postscript files in the results/ directory. The postscript files can be converted to PNG. `make png` uses Ghostscript to convert all PS files to PNG format.

## Performance tests
TBD
