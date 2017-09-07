## Test case file format
Test files are to be placed in the `cases` directory.
The file name must be formatted as `<module>_<number>_{in|out}.dat`.

A line in a test file may be one of:
* a line beginning with a `#`. This line is ignored.
* an empty line, also ignored.
* any number of lower case hexadecimal characters or `-` meaning don't care. This is considered a data line.

For data lines there may be an arbitrary number of characters from the set `[0-9a-f\-]`.
The `-` character will yield `true` in all comparisons.

For AXI stream interfaces with single transaction data a single line should correspond to a single frame.
Using more or less characters will result in a failed test as the `tkeep` and `tlast` signal are generated / checked.

## Test case sequencing
It is possible to execute parts of the test case files in a predefined sequence.
The commands `%WAIT_GEN`, `%WAIT_CHK` and `%WAIT_EMU` may be placed at the beginning of a line in one of the `in.dat`, `out.dat` or `emu` files.
If the corresponding component has executed all previous lines, it will stop until the specified component emits an `%EVENT`.
A component may not wait for itself.

### Example
The goal for this example is that the generator and checker modules start after the complete CPU interface tests has been run.

This is achieved by placing a single line with `%WAIT_EMU` each at the beginning of the `in.dat` and `out.dat` files.
Also a line with `%EVENT` is appended to the `.emu` file.

## Test cases

\verbinclude cases.json
