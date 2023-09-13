
# Unix table column and row manipulation using column names

`pick` is an expressive low-memory **command-line** tool for manipulating text file tables.

It allows database-style queries (*select*) and filters (*where*)
on a single text file or stream using its column names (or indexes if no names are present).
Columns can be selected, transformed and combined and rows can be filtered using conditions.

In simple to middling cases pick can avoid both the need for a script (R, awk, Python, Ruby et cetera) and
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

Computation syntax is minimalist and terse, employing a stack language with just three types (variables, constants and operators).
In order to work as a command line tool, the `pick` computation language **does away with whitespace entirely.**
On first sight it might look arcane or terrifying, requiring a long second look.
Compensating for the terse stack language, `pick`'s inner computation loop is simple and dependable.

[Pick one or more columns](#pick-one-or-more-columns)  
[Pick columns and filter or select rows](#pick-columns-and-filter-or-select-rows)  
[Selecting based on numerical proximity](#selecting-based-on-numerical-proximity)  
[Syntax for computing new columns](#syntax-for-computing-new-columns)  
[Examples of computing new columns](#examples-of-computing-new-columns)  
[Selecting and manipulating multiple columns with regular expressions, lists and ranges](#selecting-and-manipulating-multiple-columns-with-regular-expressions-lists-and-ranges)  
[Map column values using a dictionary](#map-column-values-using-a-dictionary)  
[Ragged input](#ragged-input)  
[SAM and CIGAR support](#sam-and-cigar-support)  
[Useful regular expression features](#useful-regular-expression-features)  
[Option processing](#option-processing)  
[Pick options](#pick-options)  
[Pick operators](#pick-operators)  
[Miscellaneous](#miscellaneous)  
[Implementation notes](#implementation-notes)


## Pick one or more columns

Pick columns `foo` and `bar` from the file `data.txt`. Order is as specified, the output
will contain a header with column names `foo` and `bar`.


```
pick foo bar < data.txt
```

Below
(1) pick columns `bar` and `foo` from `data.txt`, in that order.
(2) Pick all columns excluding `bar` and `foo`; with `-h` the output header is dropped.
(3) With `-A` all columns are selected; this is useful when the goal is just to filter rows (see below).


```
(1)   pick -h bar foo < data.txt

(2)   pick -x bar foo < data.txt

(3)   pick -A < data.txt
```

If no header is present indexes and index ranges can be used.
`-k` implies the first row has no special meaning (as column names) and handles are 1-based indexes.
(1) The output order is as specified.
(2) Pick columns using a regular expression for column names. This can be helpful for large tables. Quotes
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

<details><summary>Further selection examples</summary>

where `tim` is larger than the column value in `zut` (the leading colon in `:zut` indicates
that the value to compare to should be taken from column `zut`):
```
pick foo bar @tim/gt/:zut < data.txt
```
It is possible for `zut` to be [a newly computed value derived from other (existing or computed) columns](#examples-of-computing-new-columns).


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

</details>

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



## Syntax for computing new columns

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


## Examples of computing new columns

In the example below the `<compute>` part (with name `doodle`) is `yam:bob,sub^1,add`. It does not start with
either a colon, caret or comma.
**By default the first part is always assumed to be a column handle unless a constant value or operator is found**.

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
pick -h ::foo:bar < data.txt
```

In several places pick is happy to accept empty strings. One example is the compute name.
Each compute needs an associated name that is unique (the part before ::).
If no compute name is specified pick will construct a unique name automatically, which
is useful if output column names are not required.
In this example `pick` outputs the length of each field in the `foo` column.

```
pick -h ::foo,len < data.txt | hissyfit
```

The automatic compute names are visible if neither `-h` (no output header) nor `-k` (additionally no input header) is specified.
Leaving out compute names is only sensible or useful in the presence of one of these two options.

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
   over all selected columns. Below is a list of examples;
   [another set can be found here](examples/multi-select.md).


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
   > echo -e "col01\tcol02\tcol03\n3\t4\t5" | pick x_/'^col(\d{2})$'/::__^1,add
   x_01	x_02	x_03
   4	5	6
```

   It can be useful to have two version for each in a set of columns, for example
   to present a column both as a percentage and as a count. If double slashes are
   used `pick` will include the original as well as the derived column:
```
   > echo -e "a\tb\tc\n3\t4\t5" | pick  '.*'//_pct::__:c^1,pct
   a       a_pct   b       b_pct   c       c_pct
   3       60.0    4       80.0    5       100.0
```

   It is possible to transform columns while keeping their old values around for
   other use (e.g. filtering or computation). In this example the column values
   are squared. The old columns are renamed by adding the suffix `o` but are
   withheld from output due to the use of `:=` rather than `::`.
```
   > echo -e "a\tb\tc\n3\t4\t5" | pick -i '.*'/o:=__ '.*'::__,sq oldsum::ao:bo:co,addall
   a  b  c  oldsum
   9  16 25 12
```
   Of note is that currently regular expression selection only works on the input columns
   and does not take into account newly computed columns. Hence it is **not possible**
   to specify the computation `oldsum::ao:bo:co,addall` with a regex as `'oldsum:.o$,addall'`
   (although this can be achieved easily by piping pick output to a second pick invocation).

   The order in which the above was specified is important. If the two computations are
   switched (with the column copy/rename coming last) then the copy
   will pick up the in-place-modified columns:

```
> echo -e "a\tb\tc\n3\t4\t5" | pick -i '.*'::__,sq '.*'/o:=__ oldsum::ao:bo:co,addall
a	b	c	oldsum
9	16	25	50
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
shows an idiomatic way to find rows where a column value is not part of a limited set
of prescribed values.

- the `-i` (in-place) option is dropped.
- dictionary values are not specified and thus set to 1 by pick.
- the dictionary is given the name `foo`, refered to later by the `map` operator.
- the mapped values in column 1 are put in variable `check`.
- `check` is set to zero if the field in `col1` is not found in the dictionary.
- `check` is not output (`:=` instead of `::`).
- Those rows are selected where `check` has value 0 (not found).

```
echo -e "col1\tcol2\na\t3\nb\t4\nc\t8" | pick -A --cdict-foo/0=a,b check:=col1^foo,map @check=0
col1 col2
c    8
```

Use `--fdict-dictNAME/STRING=FILENAME` if you want to read the dictionary values from file instead.


## Ragged input

Ragged input (rows with varying number of columns, such as possible with SAM format) can be processed by using the option `-O<NUM>`
and requires additionally the `-k` parameter. With this type of input column names are not supported.
At most `<NUM>` columns are consumed in each row. Excess fields in the row will be concatenated
onto the last consumed column. If the input row has fewer than `<NUM>` fields additional empty fields
will be added (and output e.g. if `-A` is used).


## SAM and CIGAR support


Use `--sam` or `--sam-h` if the input is SAM format. This will set the options `-k` (headerless input) and `-O11`
(overflow columns collated in column 11) and make the sequence lengths available in the `seqlen`
dictionary (if the sam header is found). If the output should still contain the SAM header, use `--sam-h`.

When using either of these options pick makes several new operators available that compute certain alignment-related
offsets and widths. The following table lists these shorthand operators, along with
a more verbose and obtuse/obsolete pick equivalent using older operators (still available).
Shown below are simple computes with just a single operator used. Obviously these
can be combined in various ways.

With these operators pick can be used to efficiently filter alignments, for example
removing those that do not start near expected primer sites (see below). Other applications
include the computation and extraction of quantities for quality control.

```
using --sam         without using --sam or --sam-h
   or --sam-h
---------------------------------------
qs::,qrystart       qs::6,cgqrystart         query start, 1-based
qe::,qryend         qe::6,cgqryend           query end 1-based, inclusive
qc::,qrycov         qc::6,cgqrycov           amount of bases covered by alignment in query
ql::,qrylen         qc::6,cgqrylen           query length

rs::,refstart       rs::4                    reference start, 1-based
re::,refend         re::4:6,cgrefcov,add     reference end, 1-based, inclusive
re::,refcov         rc::6,cgrefcov           amount of bases covered by alignment in reference
rl::,reflen         rl::3^seqlen,map         reference length

qcl::,qryclipl      (omitted)                Number of 5p trailing query bases [sam]
qcr::,qryclipr      (omitted)                Number of 3p trailing query bases [sam]
rcl::,refclipl      (omitted)                Number of 5p trailing reference bases [sam]
rcr::,refclipr      (omitted)                Number of 3p trailing reference bases [sam]
```

Make sure to use `samtools view -h` to include header information so that `reflen` is available.
Should a sequence name not be found in the `seqlen` dictionary the value `0` is returned for the sequence length.
In this case pick currently issues an error only if `reflen` is used (not in case `3^seqlen,map` is used).
To require alignment to be proximal within 20 bases to primer sites, use e.g.

```
mark5p=123     # your value here
mark3p=1234    # your value here
samtools view -h <bamfile> | pick --sam-h -A s:=,refstart^20,sub e:=,refend^20,add @s/le/$mark5p @e/ge/$mark3p
```

Pick has a few other/older operators that support parsing of SAM columns. For now this pertains specifically to the CIGAR
string in the sixth column. Below `<cigaritems>` is a user-defined subset of `MINDSHP=X`, the different
alignment types supported by CIGAR strings
(respectively *alignment match*, *insertion in reference*, *deletion from reference*, *skip from reference*,
*soft-clip*, *hard-clip*, *padding*, *sequence match*, *sequence mismatch*).
The operators are

`<cigarstring>` `<cigaritems>` **cgsum**  
Count the total number of bases covered by all alignment types in `<cigaritems>`.

`<cigarstring>` `<cigaritems>` **cgmax**  
Returns the size of the longest stretch of bases across all alignment types in `<cigaritems>`.

`<cigarstring>` `<cigaritems>` **cgcount**  
Returns the number of events across all alignment types in `<cigaritems>`.

`<cigarstring>` cgqrycov - still supported but **qrycov** operator prefered.  
The number of bases in query covered by this alignment; the sum of all events in `MI=X`.

`<cigarstring>` cgqryend - still supported but **qryend** operator prefered.  
The end of the alignment in query (1-based).

`<cigarstring>` cgqrylen - still supported but **qrylen** operator prefered.  
The length of query, the sum of all events in `MIS=X`.

`<cigarstring>` cgqrystart - still supported byut **qrystart** operator prefered.  
The start of the alignment in query (1-based).

`<cigarstring>` cgrefcov - still supported but **refcov** operator prefered.  
The number of bases in reference covered by this alignment; the sum of all events in `MDN=X`.

You can use the `get` operator (`<value> <regex> get`)
to retrieve information from the concatenated fields in picks last input column.


## Useful regular expression features

-  Use `\K` (keep) to anchor a pattern but retain it with `ed  edg  del  delg`, e.g.

   `:HANDLE^'patx\Kpaty',delg` will retain pattern `patx` and only delete pattern `paty`.

   Example:
```
> echo -e "a\nthequickbrownfox theslowbrownbear" | pick -h ::a^'quick\Kbrown',delg
thequickfox theslowbrownbear
```

-  Use `patx(?=paty)` to anchor `patx` to `paty` without including `paty` in the matched part.

   `:HANDLE^'patx(?=paty)',get` will just fetch `patx`.

   Example:

```
> echo -e "a\nthequickbrownfox theslowbrownbear" | pick -h ::a^'brown(?=bear)',delg
thequickbrownfox theslowbear
```

   Such patterns can be combined - here either of the two is considered match:
```
> echo -e "a\nthequickbrownfox theslowbrownbear" | pick -h ::a^'brown(?=bear)|quick\Kbrown',delg
thequickfox theslowbear
```

-  Use `(?i)pat` to make a pattern case insensitive.

## Option processing

Single-letter options can be combined or specified separately. The offset for `-O` (ragged input), optional offset for `-A`
(insertion of new columns) and `-E` expected result count are accommodated, so e.g. `-kA2O11` will be understood by pick.
The option for purging lines with a certain pattern `/<pat>` and the option for passing through
lines with a certain pattern `//<pat>` can be tagged on at the end, e.g. `-kA2/#`.

## Pick options

-  `-l` print a table of all pick operators.
-  `-l <str>` as above, limited to operators in sections matching `<str>`.  
   Available sections are `arithmetic bitop devour dictionary format input math output precision regex sam stack string`.
-  `-H` summary of pick syntax.

-  `--sam` / `--sam-h` Expect sam input, pass through sam header (`--sam-h`).  
   These options effectively set `-k -O11`, `-/^@` (`--sam`) or `-//^@` (`--sam-h`) and
   additionally store sequence lengths in the `seqlen` dictionary if the input contains a sam header.

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
-  `-O<N>` `<N>` integer; allow ragged input (e.g. SAM use `-O11`), merge all columns at/after position `<N>`
-  `-E<N>` `<N>` integer; expect <N> rows returned, exit with error if this is not the case.
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

The documentation is output when given `-H` (`-h` is the option to prevent
output of column names) or `-l` for a table of operators, also supplied below.


Arithmetic: `add addall decr div idiv incr max maxall min minall mod mul mulall pow sub`

Bit operators: `and or xor`

Stack devourers: `addall joinall maxall minall mulall`

Dictionary: `map`

Formating: `binto dd frac hexto md5 octto pct pml sn tobin tohex tooct urldc urlec`

Input: `binto hexto lineno md5 octto rowno urldc urlec`

Math: `abs ceil cos dd exp exp10 floor int log log10 sign sin sn sq sqrt tan`

Output: `md5 urldc urlec zp`

Precision: `dd frac pct pml sn`

Regular expressions: `del delg ed edg get`

Sam file support: `qrystart qryend  qrycov  qrylen refstart refend refcov reflen cgsum cgmax cgcount`  
Use `--sam` (sam input) or `--sam-h` (additionally copy/output sam header) to activate these operators
and set various pick options.

Stack control: `dup pop xch`

String manipulation: `cat del delg ed edg get joinall lc len map md5 rc rev substr uc uie urldc urlec`


Below is the table pick supplies when given `-l`.

```
Operator    Consumed    Produced            Description
--------------------------------------------------------------------------------
abs         x           abs(x)              Absolute value of x [math]
add         x y         x+y                 Add x and y, sum, addition [arithmetic]
addall      *           sum(Stack)          Sum of all entries in stack [arithmetic/devour]
and         x y         x and y             Bitwise and between x and y [bitop]
binto       x           x'                  Read binary representation x [input/format]
cat         x y         xy                  Concatenation of x and y [string]
ceil        x           ceil(x)             The ceil of x [math]
cgcount     c s         Count of s in c     Count of s items in cigar string c [string/sam]
cgmax       c s         Max of s in c       Max of lengths of s items in cigar string c [string/sam]
cgqrycov    c           qrycov              Count of query bases covered by cigar string c (MI=X events) [string/sam]
cgqryend    c           qryend              Last base considered aligned in query for cigar string c [string/sam]
cgqrylen    c           qrylen              Length of query (MIS=X events) in cigar string c [string/sam]
cgqrystart  c           qrystart            First base considered aligned in query for cigar string c [string/sam]
cgrefcov    c           refcov              Count of reference bases covered by cigar string c (MDN=X events) [string/sam]
cgsum       c s         Sum of s in c       Sum of lengths of s items in cigar string c [string/sam]
cos         x           cos(x)              Cosine of x [math]
dd          x N         x'                  Floating point x printed with N decimal digits [math/format/precision]
decr        x           x--                 x decremented by one [arithmetic]
del         x p         x =~ s/p//          Delete pattern p in x [string/regex]
delg        x p         x =~ s/p//          Globally delete pattern p in x [string/regex]
div         x y         x/y                 Division, fraction, (cf -P and PICK_DIV_INF) [arithmetic]
dup         x           x x                 Duplicate top entry x [stack]
ed          x p s       x =~ s/p/s/         Substitute pattern p by s in x [string/regex]
edg         x p s       x =~ s/p/s/g        Globally substitute pattern p by s in x [string/regex]
exp         x           e**x                Exponential function applied to x [math]
exp10       x           10^x                10 to the power of x [math]
floor       x           floor(x)            The floor of x [math]
frac        x y N       x/y                 Division, fraction x/y with N decimal digits (cf -P and PICK_DIV_INF) [precision/format]
get         x r         r-match-of-x        If x matches regex r take outer () group or entire match, empty string otherwise (cf uie) [string/regex]
hexto       x           x'                  Read hex representation x [input/format]
idiv        x y         x // y              Integer division, divide (cf -P and PICK_DIV_INF) [arithmetic]
incr        x           x++                 x incremented by one [arithmetic]
int         x           int(x)              x truncated towards zero (do not use for rounding) [math]
joinall     * s         Stack-joined-by-s   Stringified stack with s as separator [string/devour]
lc          x           uc(x)               Lower case of x [string]
len         x           len(x)              Length of string x [string]
lineno      -           x                   Push file line number x onto stack [input]
log         x           log(x)              Natural logarithm of x [math]
log10       x           log10(x)            Logarithm of x in base 10 [math]
map         x dname     map-of-x            Use map of x in dictionary dname (if found; cf --cdict-dname= --fdict-dname=) [string/dictionary]
max         x y         max(x,y)            Maximum of x and y [arithmetic]
maxall      *           max(Stack)          Max over all entries in stack [arithmetic/devour]
md5         x           md5(x)              MD5 sum of x [string/format/input/output]
min         x y         min(x,y)            Minimum of x and y [arithmetic]
minall      *           min(Stack)          Min over all entries in stack [arithmetic/devour]
mod         x y         x mod y             x modulo y, remainder [arithmetic]
mul         x y         x*y                 Multiply x and y, multiplication, product [arithmetic]
mulall      *           product(Stack)      Product of all entries in stack, multiplication [arithmetic/devour]
octto       x           x'                  Read octal representation x [input/format]
or          x y         x or y              Bitwise or between x and y [bitop]
pct         x y N       pct(x/y)            Percentage of x relative to y with N decimal digits (cf -P and PICK_DIV_INF) [precision/format]
pml         x y N       pct(x/y)            Promille of x relative to y with N decimal digits (cf -P and PICK_DIV_INF) [precision/format]
pop         x           -                   Remove top entry x from stack [stack]
pow         x y         x**y                x raised to power y [arithmetic]
rc          x           rc(x)               Reverse complement [string]
rev         x           rev(x)              String reverse of x [string]
rowno       -           x                   Push current table row number x onto stack [input]
sign        x           sign(x)             The sign of x (-1, 0 or 1) [math]
sin         x           sin(x)              Sine of x [math]
sn          x N         x'                  Floating point x in scientific notation with N decimal digits [math/format/precision]
sq          x           x^2                 Square of x [math]
sqrt        x           sqrt(x)             Square root of x [math]
sub         x y         x-y                 Subtract y from x, subtraction [arithmetic]
substr      x i k       x[i:i+k-1]          Substring of x starting at i (zero-based) of length k [string]
tan         x           tan(x)              Tangens of x [math]
tobin       x           x'                  Binary representation of x [format]
tohex       x           x'                  Hex representation of x [format]
tooct       x           x'                  Octal representation of x [format]
uc          x           uc(x)               Upper case of x [string]
uie         x y         x-or-y              Use x if not empty, otherwise use y [string]
urldc       x           urldc(x)            Url decoding of x [string/format/input/output]
urlec       x           urlec(x)            Url encoding of x [string/format/input/output]
xch         x y         y x                 Exchange x and y [stack]
xor         x y         x xor y             Bitwise exclusive or between x and y [bitop]
zp          x N         x'                  x left zero-padded to width of N [output]
```


These are additionally available if `--sam` is supplied:

```
Operator    Consumed    Produced            Description
--------------------------------------------------------------------------------
qrycov      -           qrycov              Amount of query covered by alignment [sam]
qryend      -           qryend              Last base in query covered by alignment [sam]
qrylen      -           qrylen              Length of query sequence [sam]
qrystart    -           qrystart            Start of alignment in query [sam]

refcov      -           refcov              Amount of reference covered by alignment [sam]
refend      -           refend              Last base in reference covered by alignment [sam]
reflen      -           reflen              Length of reference sequence (requires samtools view -h) [sam]
refstart    -           refstart            Field 4 from sam format [sam]

qryclipl    -           qryclipl            Number of 5p trailing query bases [sam]
qryclipr    -           qryclipr            Number of 3p trailing query bases [sam]

refclipl    -           refclipl            Number of 5p trailing reference bases [sam]
refclipr    -           refclipr            Number of 3p trailing reference bases [sam]
```


## Miscellaneous


### Retrieving unique values and asserting the number of rows found

If the input is queried for a value that should be present and unique, you can do pick let the checking
by passing `-E1`. More generally `-E<NUM>` will exit with an error if the number of rows found is
different from `<NUM>`.


### Creating fasta files

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

It is tempting to implement pick in C or Rust to get a speed boost.  However,
reinventing an integer/float/string equivalence system (with its many niggling
corner cases) from scratch does not seem right (where's the C library for that?).
Below gives a rough indication of pick speed relative to baseline perl speed;
the latter is measured as a skeleton loop over lines of input with each line split into fields.
The timings can be perfomed by running `make time` and `make time2` in the test directory.


### Timings of comparisons and compute, no output
```
███▋                                                        87 perl one comparison
███▊                                                        92 perl two comparisons

█████████▌                                                 230 pick one comparison
████████████▉                                              309 pick two comparisons

████████████████▌                                          398 pick one compute (addition)
███████████████████████████                                649 pick two computes (addition)
██████████████████████████████████▎                        824 pick three computes (addition)
███████████████████████████████████████████▏              1036 pick four computes (addition)
█████████████████████████████████████████████████████▍    1283 pick five computes (addition)
████████████████████████████████████████████████████▏     1251 pick five computes (multiplication)
███████████████████████████████████▌                       853 pick one compute, (five add operators)

```

### Timings of output and compute
```
███▋                                                        87 perl print none
███▌                                                        85 perl print one
█████                                                      121 perl print all
█████▌                                                     134 perl print all, add column (addition)

██████                                                     146 pick print none
████████▊                                                  210 pick print one
████████████                                               288 pick print all
█████████████████████████▋                                 617 pick print all, twice
███████████████████████████████████████▉                   958 pick print all, thrice

████████████████████████▌                                  589 pick print all, add column (addition)
█████████████████████████▌                                 613 pick print all plus compute
████████████████████████████████████                       864 pick print all plus long compute
███████████████████████████████▊                           764 pick print all plus long compute shortcut

```
