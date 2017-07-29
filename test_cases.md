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

## Test cases

\verbinclude cases.json
