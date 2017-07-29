## Test case file format
Test files are to be placed in the `cases` directory.
The file ending `.dat` is recommended.

A line in a test file may be one of:
* a line beginning with a `#`. This line is ignored.
* an empty line, also ignored.
* any number of lower case hexadecimal characters or `-` meaning don't care. This is considered a data line.

For data lines there may be an arbitrary number of characters from the set `[0-9a-f\-]`.
The `-` character will yield `true` in all comparisons.

For AXI stream interfaces with single transaction data a single line should correspond to a single frame.
Using more or less characters will result in a failed test as the `tkeep` and `tlast` signal are generated / checked.

## Test cases
| module    | in file suffix | out file suffix | description                                    |
| --------- | -------------- | --------------- | ---------------------------------------------- |
| testbench | `_00_in.dat`   | `_00_out.dat`   | skip comments and empty lines                  |
| testbench | `_01_in.dat`   | `_01_out.dat`   | split frames on tlast                          |
