
# Unix file/stream column and row manipulation using column names

`pick` is a **command-line** query/programming tool for manipulating streamed tabular data,
by transforming, recombining and selecting columns as well as filtering rows, allowing either
column names or indexes to be used as identifiers.

Pick's functionality is a mix of aspects of unix `cut`, `R` and `awk`.
In simple to middling cases it can avoid both the need for a script (R, awk, Python, Ruby et cetera) and
having to load the entire data set into memory.
I use it in conjunction with UNIX tools such as `comm`, `join`, `sort` and `datamash` to simplify file-based computational workflows
and make them more robust and understandable by promoting the use of column names as handles
(as opposed to column indexes as used with `cut` and `awk`).

`pick` is **robust** and **intuitive** by supporting column names as handles.
It is **lightweight** as it processes data per-line without the need to load the table into memory.
It is **expressive** in that short command lines are sufficient to get at the data.
You can

- Use column names or column indexes to
- Select columns
- Change columns (using computation and string operations)
- Combine columns into new columns (using computation and string operations)
- Filter rows on boolean clauses computed on columns
- Select multiple columns using ranges or regular expressions
- Take the same action on multiple columns using a lambda expression

There is no downside, except, as ever, it comes with its own syntax for
computation. For plain column selection and row filtering this syntax is not needed though;
pick command lines look pleasant enough for common use cases.

Computation syntax is minimalist and terse, employing a stack language with just three types.
In order to work as a command line tool, the `pick` computation language **does away with whitespace entirely.**
On first sight it might look arcane or terrifying, requiring a long second look.
Compensating for the terse stack language, `pick`'s inner computation loop is simple and dependable.

[Pick one or more columns](#pick-one-or-more-columns)  
[Pick columns and filter or select rows](#pick-columns-and-filter-or-select-rows)  
[Selecting based on numerical proximity](#selecting-based-on-numerical-proximity)  
[Syntax for computing derived values](#syntax-for-computing-derived-values)  
[Examples of computing derived values](#examples-of-computing-derived-values)  
[Selecting and manipulating multiple columns with regular expressions, lists and ranges](#selecting-and-manipulating-multiple-columns-with-regular-expressions-lists-and-ranges)  
[Map column values using a dictionary](#map-column-values-using-a-dictionary)  
[Ragged input](#ragged-input)  
[SAM and CIGAR support](#sam-and-cigar-support)  
[Miscellaneous](#miscellaneous)  
[Option processing](#option-processing)  
[Useful regular expression features](#useful-regular-expression-features)  
[Pick options](#pick-options)  
[Pick operators](#pick-operators)  
[Implementation notes](#implementation-notes)  


## Pick one or more columns

Pick columns `foo` and `bar` from the file `data.txt`. Order is as specified.

```
pick foo bar < data.txt
```

Pick columns `bar` and `foo` from `data.txt`, in that order (1). With `-h`
the column names themselves are dropped.
Pick all columns excluding `bar` and `foo` (2).
With `-A` all columns are selected (3); this
is useful when the goal is just to filter rows.


```
(1)   pick -h bar foo < data.txt

(2)   pick -x bar foo < data.txt

(3)   pick -A < data.txt
```

Pick columns using indexes and an index range (1). The output order is as specified.
`-k` implies the first row has no special meaning (as column names) and handles are 1-based indexes.
Pick columns using a regular expression for column names (2). This can be helpful for large tables. Quotes
are needed to prevent shell interpretation of characters that are special to the shell.

```
(1)   pick -k 5 3 7-9 < data.txt

(2)   pick '^foo\d+$' < data.txt
```


## Pick columns and filter or select rows

Pick columns `foo` and `bar`, only taking rows where `tim` fields are larger than zero.
multiple `@` selections are possible; default is `AND` of multiple clauses, use `-o` for `OR`.
`tim` can refer to a newly computed variable (see below).

```
pick foo bar @tim/gt/0 < data.txt
```

where `tim` is larger than the column value in `zut` (the leading colon in `:zut` indicates
that the value to compare to should be taken from column `zut`):
```
pick foo bar @tim/gt/:zut < data.txt
```
It is possible for `zut` to be [a newly computed value derived from other (existing or computed) columns](#examples-of-computing-derived-values).


where `tim` is the string `flub123`:
```
pick foo bar @tim=flub123 < data.txt
```

where `tim` is NOT the string `flub123`:
```
pick foo bar @tim/=flub123 < data.txt
```

where `tim` matches the string `flub123`:
```
pick foo bar @tim~flub123 < data.txt
```

where `tim` matches the string `flub` followed by zero or more digits:
```
pick foo bar @tim~flub'\d*' < data.txt
```

where `tim` matches the string `flub` followed by one or more digits:
```
pick foo bar @tim~flub'\d+' < data.txt
```

where the entirety of the `tim` column value matches the string `flub` followed by one or more digits,
and nothing else, by anchoring the regular expression:
```
pick foo bar @tim~^flub'\d+$' < data.txt
```

where `tim` _does not_ match the string `flub` followed by one or more digits:
```
pick foo bar @tim/~flub'\d+' < data.txt
```


The full list of comparison operators:

```
    = /=                            string identy select, avoid
    ~ /~                            string (Perl) regular expression select, avoid
    ~eq~ ~ne~ ~lt~ ~le~ ~ge~ ~gt~   string comparison
    /eq/ /ne/ /lt/ /le/ /ge/ /gt/   numerical comparison
    /ep/ /om/                       numerical proximity (additive, multiplicative)
    /all/ /any/ /none/              bit selection
```

`=` is for string identity, `/=` is for string _not equal to_. These are shorthand
for `~eq~` and `~ne~`, respectively. `~` tests against
a perl regular expression, accepting matches, `/~` tests against a perl regular
expression, discarding matches. `/ep/` (epsilon) and `/om/` (order of magnitude)
are described [here](#selecting-based-on-numerical-proximity).
By default comparison is to a constant value; in order to compare to a column
its name or index is used, preceded by a colon:

```
pick foo bar @tim/gt/:bob < data.txt

pick -k 3 5 @8/gt/:6 < data.txt
```

## Selecting based on numerical proximity

### Using epsilon and selecting within additive range

Select all rows where `tim` is approximately 1.0. The default epsilon (maximum allowed
deviation) for this is 0.0001 but can be changed (see below).

```
pick -A @tim/ep/1.0 < data.txt
```

As above, but make epsilon more stringent (one in a million).

```
pick -A @tim/ep/1.0/0.000001 < data.txt
```

In this case, select rows where columns `tim` and `pat` are no further than one apart.

```
pick -A @tim/ep/:pat/1 < data.txt
```


### Using order of magnitude and selecting within multiplicative range

The default order of magnitude is 2 but can be changed. Below selects rows
where column `tim` is no larger than twice column `pat` and column `pat` is
no larger than twice column `tim`, ignoring signs.

```
pick -A @tim/om/:pat < data.txt
```

Add `@tim/gt/0` to additionally require the sign to be positive for example.
Change the order of magnitude by adding it as a parameter, in this case 1.01.

```
pick -A @tim/om/:pat/1.01 < data.txt
```



## Syntax for computing derived values

_Derived values_, also known as _computations_ can be
- output as a new column
- compared against with selection criteria
- used to break up computations into smaller parts


A computation is expressed in a stack language that has three types. These
are the _column handle_ type, the _constant value_ type
(a number or a string) and the _operator_ type.
A column handle is either a column name or a column index if `-k` is used.
Each of the three types is designated by and introduced by a specific character.
These are

- colon `:` for a column handle
- caret `^` for a constant value (number or string)
- comma `,` for an operator

Constant values and column handles are url-decoded, hence the escape mechanism
for including any of the characters `^:,%` in a constant value or column handle is to url-encode them.
The following is an example of a computation:

```
:foo^144,add
```

is an expression that indicates the column named `foo`, the number 144 and the `add` operator.
The result of it is the sum of the value in the `foo` column and 144.
Each computation needs a name. It can be thought of as a variable name. If the computation
is output as a new column the name will be used as the column name. The two forms are below,
where (1) `newname` will not be output as a new column (but is still available e.g. for other computations or comparison)
and (2) `newname2` will be output.

```
(1)   newname1:=<compute>

(2)   newname2::<compute>
```


## Examples of computing derived values

In the example below the `<compute>` part (with name `doodle`) is `yam:bob,sub^1,add`. It does not start with
either a colon, caret or comma.
**By default the first part is always assumed to be a column handle unless a constant value is found** - there is no useful scenario to start with an operator.

This particular compute puts two column values on the stack (for columns `yam` and `bob`), then subtracts
`bob` from `yam`, and adds 1 to the result. If the two columns denote inclusive bounds for an interval
then this will give the interval length.

In this example, the final output is the existing columns `foo`, `bar` and the new column `doodle`.

```
pick foo bar doodle::yam:bob,sub^1,add < data.txt
```

By default `pick` will refuse a compute for which the name clashes with an existing name.
Allowing such can be useful however if the goal is to update an existing column. This is facilitated by the `-i` (in-place) option.
The example below selects all columns (`-A`) and adds 1 to column `foo` in-place.

```
pick -Ai foo::foo^1,add < data.txt
```

Once all operators are exhausted pick will concatenate everything that is still on the stack. Thus below
simply concatenates columns `foo` and `bar`.
```
pick ::foo:bar < data.txt
```

In several places pick is happy to accept empty strings. One example is the compute name.
Each compute needs an associated name that is unique (the part before ::).
In the examples above and below the unique name is the empty string, offering the tiny
convenience that you don't need to expend energy on thinking up a variable name
if you just want to quickly compute a single value from each row.
In this example `pick` outputs the length of each field in the `foo` column.

```
pick -h ::foo,len < data.txt | hissyfit
```


The following example swaps two columns. This is mostly to illustrate how
columns and compute names interact.  Compute names are like normal
variables, so to swap two values a third name is needed.

```
pick -Aki foo:=1 1::2 2::foo < data.txt
```

-   -k implies no columns names are read, column handles are 1 2 3 ..
-   -A selects all columns for output.
-   -i is needed to allow overwriting existing columns 1 and 2.  
-   Assignments happen proceeding from left to right
-   := computes a value without outputting it,
-   :: computes a value and selects it for output.


## Selecting and manipulating multiple columns with regular expressions, lists and ranges

There are three modes of selecting/modifying multiple columns. Each is briefly
introduced below, followed by more examples and explanation.


-  Simply selecting multiple columns for output. Example usage
```
   pick 'num\d{2}$' < data.txt
```

-  Selecting multiple columns and reducing them to a single value by e.g. concatenation,
   taking the minimum or maximum, or adding all values. Example usage
```
   pick nummax::'num\d{2}$',maxall < data.txt
   pick 'num\d{2}$' nummax::'num\d{2}$',maxall < data.txt
   echo {1..20} | tr ' ' $'\t' | pick -k ::'.*',mulall         # compute 20 factorial
```

-  Selecting multiple columns and executing the same operation on each column using
   a lambda expression.  The parameter in pick lambda expressions is written
   `:__`. Each instance of it will be replaced by the column name, multiplexed
   over all selected columns.


   Multiple column selection and modification using a regular expression:
```
   pick -i '^num\d{2}$'::__^1,add < data.txt
```

   Multiple column selection and modification using a list:
```
   pick -i foo:bar:zut::__^1,add < data.txt
```

   Lists can take a mix of regular expressions and column names:
```
   pick -i foo:bar:zut:'num\d+':'yay\d+'::__^1,add < data.txt
```

   It is possible to rename the columns with a prefix and/or a suffix:
```
   pick pfx/foo:bar:zut:'num\d+':'yay\d+'/sfx::__^1,add < data.txt
   pick foo:bar:zut:'num\d+':'yay\d+'/sfx::__^1,add < data.txt
   pick pfx/foo:bar:zut:'num\d+':'yay\d+'/::__^1,add < data.txt
```

   With a regular expression, if parentheses are used then the outer group can
   be used to capture a single element to be used in renaming:
```
   pick newname_/'^num(\d{2})$'/::__^1,add < data.txt
```

   It can be useful to have two version for each in a set of columns, for example
   to present a column both as a percentage and as a count. If double slashes are
   used `pick` will include the original as well as the derived column:
```
   pick '^num(\d{2})$'//_pct::__:num01^1,pct < data.txt
```

### Lambda expressions with index selection rather than column names

   Lambda expressions work with `-k` as well:
```
   pick -k 3:5-8::__^1,add < data.txt
```

### Regular expressions

A pattern that contains any of `[({\*?^$`
is assumed to be a regular expression rather than just a column name.
Use `-F` (fixed) to prevent regular expressions being used.


Be careful with patterns in the compute part (as above). If the pattern starts with `^`
(for start of string), it must be url-encoded as `%5E`; otherwise it will be
interpreted as the `pick` token introducing a constant value.  The characters
`^ : ,` have special meaning in the `pick` stack language (see above) and must
be url-encoded.



## Map column values using a dictionary

Dictionaries can be specified in different ways:

```
--fdict-NAME=/path/to/dictfile      (key,value) = (col1, col2) (rows with two fields)
                                               or (col1, 1)    (rows with one field)

--cdict-NAME=foo:bar,zut:tim        comma-separated key:value pairs
--cdict-NAME=foo,zut                comma-separated keys, all set to value 1
```

`NAME` is the name of the dictionary. Multiple dictionaries can be imported.
A dictionary is specified by its name for use with the map operator as seen below.
Multiple `fdict` and `cdict` specifications can be used for the same `NAME`.

```
echo -e "a\t3\nb\t4\nc\t8" | pick -Aik --cdict-foo=a:Alpha,b:Beta 1::1^foo,map
```

By default if no key is found in the dictionary the value is left alone. It is possible
to specify a not-found string using this syntax:

```
--fdict-NAME/STRING=/path/to/dictfile
--cdict-NAME/STRING=foo:bar,zut:tim
```

For example
```
echo -e "a\t3\nb\t4\nc\t8" | pick -Aik --cdict-foo/FOONOTFOUND=a:Alpha,b:Beta 1::1^foo,map
```

gives as output
```
Alpha 3
Beta  4
FOONOTFOUND 8
```


You could grep that value, or use pick itself to select or filter such columns, e.g. below
- the `-i` (in-place) option is dropped
- the mapped values in column 1 are put in variable `x`
- `x` is not output (`:=` instead of `::`)
- unmappable values are set to `FOONOTFOUND`
- Those rows are selected where `x` has the `FOONOTFOUND` value

```
echo -e "a\t3\nb\t4\nc\t8" | pick -Ak --cdict-foo/FOONOTFOUND=a:1,b:1 x:=1^foo,map @x=FOONOTFOUND
c  8
```

The empty string can be used as the special unmappable value:

```
echo -e "a\t3\nb\t4\nc\t8" | pick -Ak --cdict-foo/=a:1,b:1 x:=1^foo,map @x=
c  8
```

## Ragged input

Ragged input (rows with varying number of columns, such as possible with SAM format) can be processed by using the option `-O<NUM>`
and requires additionally the `-k` parameter. With this type of input column names are not supported.
At most `<NUM>` columns are consumed in each row. Excess fields in the row will be concatenated
onto the last consumed column. If the input row has fewer than `<NUM>` fields additional empty fields
will be added (and added e.g. if `-A` is used).


## SAM and CIGAR support

Pick has a few operators that support parsing of SAM files. For now this pertains specifically to the CIGAR
string in the sixth column. Below `<cigaritems>` is a user-defined subset of `MINDSHP=X`, the different
alignment types supported by CIGAR strings
(respectively *alignment match*, *insertion in reference*, *deletion from reference*, *skip from reference*,
*soft-clip*, *hard-clip*, *padding*, *sequence match*, *sequence mismatch*).
The operators are

`<cigarstring> <cigaritems> cgsum`  
Count the total number of bases covered by all alignment types in `<cigaritems>`.

`<cigarstring> <cigaritems> cgmax`  
Returns the size of the longest stretch of bases across all alignment types in `<cigaritems>`.

`<cigarstring> <cigaritems> cgcount`  
Returns the number of events across all alignment types in `<cigaritems>`.

`<cigarstring> cgqrycov`  
The number of bases in query covered by this alignment; the sum of all events in `MI=X`.

`<cigarstring> cgqryend`  
The end of the alignment in query (1-based).

`<cigarstring> cgqrylen`  
The length of query, the sum of all events in `MIS=X`.

`<cigarstring> cgqrystart`  
The start of the alignment in query (1-based).

`<cigarstring> cgrefcov`  
The number of bases in reference covered by this alignment; the sum of all events in `MDN=X`.


## Miscellaneous

Create fasta files with pick. In the example the identifier is in the first column with the sequence
in the second column.  Quotes needed as `>` is a shell meta character.
`%0A` is the url-encoding of a newline.

```
pick  -k '::^>:1^%0A:2' > out.fa
```


Using columns `foo` and `bar` instead. In this case `-h` is needed to avoid printing a header.

```
pick -h '::^>:foo^%0A:bar' > out.fa
```

As above, add column `zut` as further annotation. Optionally use `%20` for the space character.

```
pick -h '::^>:foo^ :zut^%0A:bar' > out.fa
```

## Useful regular expression features

-  Use `\K` (keep) to anchor a pattern but retain it with `ed  edg  del  delg`, e.g.

   `:HANDLE^'patx\Kpaty',delg` will retain pattern `patx` and only delete pattern `paty`.

-  Use `patx(?=paty)` to anchor `patx` to `paty` without including `paty` in the matched part.

   `:HANDLE^'patx(?=paty)',get` will just fetch `patx`.

-  Use `(?i)pat` to make a pattern case insensitive.

## Option processing

Single-letter options can be combined. The offset for `-O` (ragged input) and optional offset for `-A`
(insertion of new columns) are accommodated, so `-kA2O12` will be understood by pick.
The option for ignoring lines with a certain pattern `/<pat>` and the option for passing through
lines with a certain pattern `//<pat>` can be tagged on at the end, e.g. `-kA2/#`.

## Pick options

-  `-h` do not print header
-  `-k` headerless input, use 1 2 .. for input column names, `x-y` for range from `x` to `y`.
-  `-o` OR multiple select criteria (default is AND)
-  `-x` take complement of selected input column(s) (works with `-i`)
-  `-c` only output the count of rows that pass filtering
-  `-i` in-place: `<HANDLE>::<COMPUTE>` replaces `<HANDLE>` if it exists
-  `-/<pat>`  skip lines matching `<pat>`; use e.g. `-/^#` for commented lines, `-/^@` for sam files
-  `-//<pat>` pass through lines matching <pat> (allows perl regular expressions, e.g. `^ $ . [] * ? (|)` work.
-  `-v` verbose

-  `-A` print all input columns (selecting by colspec applies, -`T` accepted)
-  `-A<N>` `<N>` integer; insert new columns at position `<N>`. Negative `<N>` is relative to rightmost column.
-  `-O<N>` `<N>` integer; allow ragged input (e.g. SAM use `-O12`), merge all columns at/after position `<N>`
-  `-T` do not select, print tally column of count of matched row select criteria (name `T`)
-  `-P` protect against 'nan' and 'inf' results (see `-H` for environment variables `PICK_*_INF`)

-  `-K` headerless input as `-k` but use derived names to output column names
-  `-U` with `-k` and `-K` keep output columns unique and in original order

-  `-R` add `_` column variable if no row name field exists in the header. Note: an empty field is recognised and mapped to `_` automatically.
-  `-f` force processing (allows both identical input and output column names)
-  `-F` fixed names; do not interpret names as regular expressions. Default behaviour is to assume a regular expression if a name contains one of `[ { ( \ * ? ^ $` .
-  `-z  ARG+` print url-encoding of `ARG+` (no argument prints a few especially useful cases)
-  `-zz ARG+` print url-decoding of `ARG+`


## Pick operators

Pick supports a wide range of functionality. Standard arithmetic, bit
operations and a number of math functions are provided (see below).  It is also possible
to match and extract substrings using Perl regexes (as a derived value or new
column) with `get`, change an existing column using a regex with `ed` and
`edg`, compute md5 sums, URL-encode and decode, convert to and from binary,
octal and hex, reverse complement DNA/RNA, and extract statistics from cigar
strings. Display options include formatting of fractions and percentages
and zero padding of integers.

For an idea of the possibilities you could look at the [Makefile in the test directory](test/Makefile),
although it is more geared towards tests of selection of and operations on multiple columns.

The documentation is output when given `-H` - `-h` is the option to prevent
output of column names, or `-l` for a more concise summary of options and syntax.

Operators for compute:

Stack control:  `dup pop xch`

Input counters: `lineno rowno`

Stack devourers: `addall mulall minall maxall joinall`

Take 1: `abs binto ceil cgqrycov cgqryend cgqrylen cgqrystart cgrefcov cos exp exp10 floor hexto int lc len log log10 md5 octto rc rev rot13 sign sin sq sqrt tan tobin tohex tooct uc urldc urlec`

Take 2: `add and cat cgcount cgmax cgsum dd del delg div get idiv map max min mod mul or pow sub uie xor zp`

Take 3: `ed edg frac pct substr`

Select comparison operators: `~ /~ = /= /eq/ /ne/ /lt/ /le/ /ge/ /gt/ /ep/ /om/ ~eq~ ~ne~ ~lt~ ~le~ ~ge~ ~gt~ /all/ /any/ /none/`


## Implementation notes

Pick is currently implemented in Perl, a language not as popular as it once was. Nonetheless for data munging and
manipulation Perl is a formidable competitor. In particular pick benefits from the
power of perl regular expressions; these can be used as pick selection and modification operators on the command line.

Pick additionally benefits from Perl's mechanisms for number/string and string/number conversion.

This implementation compiles all references to column names into array
offsets.  It has no hash lookups during the core computation and output loop. Each computation
is stored as a stack with code references where needed.  I see no drastic
improvements available in pure perl, but I'd love to be wrong about this
(unwrapping the code references may lead to some speed-up but code modularity would suffer).

It is tempting to implement pick in C to get a speed boost.  However,
reinventing an integer/float/string equivalence system (with its many niggling
corner cases) from scratch does not seem right (where's the C library for that?).
Below gives a rough indication of pick speed relative to baseline perl speed;
the latter is measured as a skeleton loop over lines of input with each line split into fields.
The timings can be recreated by running `make time` and `make time2` in the test directory.


### Timings of comparisons and compute, no output
```
----                                                              perl one comparison
----                                                              perl two comparisons

-----------                                                       pick one comparison
--------------                                                    pick two comparisons

--------------------                                              pick one compute (addition)
-----------------------------                                     pick two computes (addition)
--------------------------------------                            pick three computes (addition)
--------------------------------------------------                pick four computes (addition)
---------------------------------------------------------         pick five computes (addition)
--------------------------------------------------------------    pick five computes (multiplication)

----------------------------------------                          pick one compute (five add operators)
```

### Timings of output and compute
```
---                                                               perl print none
----                                                              perl print one
----                                                              perl print all
------                                                            perl print all, add column (addition)

-------                                                           pick print none
-----------                                                       pick print one
-------------                                                     pick print all
-------------------------------                                   pick print all, add column (addition)

----------------------------                                      pick print all plus compute
-------------------------------------------                       pick print all plus long compute
-------------------------------------                             pick print all plus long compute shortcut
```
