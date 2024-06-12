
# Unix table column/row manipulation using column names

## Sam alignment format poly-wrangler


`pick` is an expressive low-memory **command-line** tool for manipulating text file tables.
Entire scripts can be replaced by concise command line invocations. Some examples:

```
pick foo bar                      < data.txt       # pick columns with names foo and bar (header included)

pick -A @tim/gt/0 qat::foo^-:bar  < data.txt       # pick all columns where the tim value is positive, add new column qat

pick -k 1 2 ::3:4,add             < data.txt       # no names, pick columns 1, 2 and the sum of 3 and 4

pick -h ::end:start,sub^1,add     < data.txt       # compute new column with inclusive interval length, omit header

pick -k ::3:4,sub^1,add           < data.txt       # as previous, in the absence of column headers

pick -h ::foo^'(\d+)',get         < data.txt       # extract a sequence of digits from the foo values

```

Pick is a standalone script that depends only on a standard perl installation - it should work on any standard Linux (or Unix) OS
and all Mac OS releases with developer tools installed.

```
wget https://raw.githubusercontent.com/micans/pick/main/pick
```

Pick allows database-style queries (*select*) and filters (*where*)
on a single text file or stream using its column names (or indexes if no names are present).
Columns can be selected, mapped, transformed and combined and rows can be filtered using conditions.
Output can be demuxed into different files and dictionaries can be loaded to map data.

`pick` is **robust** and **intuitive** by supporting column names as handles.
It is **lightweight** as it processes data per-line without the need to load the table into memory.
It is **expressive** in that short command lines are sufficient to get at the data.

Pick works very well as a pre-filter to [datamash](https://www.gnu.org/software/datamash/) -
a tool that can compute statistics over columns, optionally grouped over a second (column) variable.

Additionally `pick` has **extensive support for SAM format** such as printing alignments and
outputting alignment-derived quantities like coverage and base mismatch information.
A reference FASTA file can be specified, which is then used by pick to automatically slot in reference
sequences where needed.

> [!NOTE]
> For your benefit, [miller (unix command `mlr`)](https://miller.readthedocs.io/en/)
> is an amazing widely-used command-line tool for handling tables (using column names also), in an entirely
> different league than pick in terms of capabilities. It is available in most
> Linux distributions as a supported package.
>  
> Pick embodies, comparatively, an extremely minimalist approach with a different and
> greatly limited focus in the same problem space.  Within its narrow focus on
> column manipulation and row selection it is very concise,
> has **extensive support for SAM format and alignment-related queries**,
> and has miscellaneous features such as simultaneous transformations of
> multiple columns, demultiplexing rows to different files, and mapping values
> using dictionaries.  Think of it as one of these weirdly evolved deep-sea
> creatures (one that is pretty).

In simple to middling cases pick can avoid both the need for a script (R, awk, Python, Ruby et cetera) and
having to load the entire data set into memory.
I use it in conjunction with UNIX tools such as `comm`, `join`, `sort` and `datamash` to simplify file-based computational workflows
and make them more robust and understandable by promoting the use of column names as handles
(as opposed to column indexes as used with `cut` and `awk`). You can

- Use column names or column indexes to
- Select columns
- Change columns (using computation and string operations)
- Combine columns into new columns (using computation and string operations)
- Filter (or fork) rows on boolean clauses computed on columns
- Select multiple columns using ranges or regular expressions
- Take the same action on multiple columns using a lambda expression
- Split/demultiplex rows to different output files based on (computed) labels in columns


There is no downside, except, as ever, it comes with its own syntax for
computation. For plain column selection and row filtering this syntax is not needed though;
**pick command lines look pleasant enough for common use cases.**

Computation syntax is minimalist and terse, employing a stack language with just three types (variables, constants and operators).
In order to work as a command line tool, the `pick` computation language **does away with whitespace entirely.**
On first sight it might look arcane or terrifying, requiring a long second look.
Compensating for the terse stack language, `pick`'s inner computation loop is simple and dependable.

[Pick one or more columns](#pick-one-or-more-columns)  
[Pick columns and filter or select rows](#pick-columns-and-filter-or-select-rows)  
[Selecting based on numerical proximity](#selecting-based-on-numerical-proximity)  
[Syntax for computing new columns](#syntax-for-computing-new-columns)  
[Examples of computing new columns](#examples-of-computing-new-columns)  
[Choosing and finding from pick's arsenal of operators](#choosing-and-finding-from-picks-arsenal-of-operators)  
[Selecting and manipulating multiple columns with regular expressions, lists and ranges](#selecting-and-manipulating-multiple-columns-with-regular-expressions-lists-and-ranges)  
[Map column values using a dictionary](#map-column-values-using-a-dictionary)  
[Operators for testing and choice](#operators-for-testing-and-choice)  
[Ragged input](#ragged-input)  
[SAM format support](#sam-format-support)  
&emsp;&emsp;[Activating SAM support and loading reference sequences](#activating-SAM-support-and-loading-reference-sequences)  
&emsp;&emsp;[Operators to output alignments](#operators-to-output-alignments)  
&emsp;&emsp;[Operators to retrieve mismatch and indel positions and sequences](#operators-to-retrieve-mismatch-and-indel-positions-and-sequences)  
&emsp;&emsp;[Operators to retrieve query sequence parts](#operators-to-retrieve-query-sequence-parts)  
&emsp;&emsp;[Examples](#examples)  
&emsp;&emsp;[Operators returning offsets and lengths](#operators-returning-offsets-and-lengths)  
&emsp;&emsp;[Cigar string operators](#cigar-string-operators)  
[Splitting, demultiplexing and forking rows across different outputs](#splitting-demultiplexing-and-forking-rows-across-different-outputs)  
&emsp;&emsp;[Splitting a table into smaller tables for parallel processing](#splitting-a-table-into-smaller-tables-for-parallel-processing)  
&emsp;&emsp;[Combining demuxing and deselecting](#combining-demuxing-and-deselecting)  
&emsp;&emsp;[Taking a single indexed batch from a table](#taking-a-single-indexed-batch-from-a-table)  
[Retrieving unique values and asserting the number of rows found](#retrieving-unique-values-and-asserting-the-number-of-rows-found)  
[Miscellaneous](#miscellaneous)  
&emsp;&emsp;[Escaping special characters](#escaping-special-characters)  
&emsp;&emsp;[Maps can be useful to update (subsets of) data](#maps-can-be-useful-to-update-subsets-of-data)  
&emsp;&emsp;[Maps can be useful to select or filter out data](#maps-can-be-useful-to-select-or-filter-out-data)  
&emsp;&emsp;[Creating fasta and fastq files](#creating-fasta-and-fastq-files)  
&emsp;&emsp;[Useful regular expression features](#useful-regular-expression-features)  
&emsp;&emsp;[Applying the same action to each table entry](#applying-the-same-action-to-each-table-entry)  
&emsp;&emsp;[Loading data from the previous row](#loading-data-from-the-previous-row)  
&emsp;&emsp;[Loading a previous row within a group](#loading-a-previous-row-within-a-group)  
[Option processing](#option-processing)  
[Pick options](#pick-options)  
[Pick operators](#pick-operators)  
[Pick philosophy](#pick-philosophy)  
[Implementation notes](#implementation-notes)


## Pick one or more columns

Pick columns `foo` and `bar` from the file `data.txt`. Order is as specified, the output
will contain a header with column names `foo` and `bar`.


```
pick foo bar < data.txt
```

Below
(1) pick columns `bar` and `foo` from `data.txt`, in that order. With `-h` the output header is dropped.
(2) Pick all columns excluding `bar` and `foo`.
(3) With `-A` all columns are selected; this is useful when the goal is just to filter rows (see below).


```
(1)   pick -h bar foo < data.txt

(2)   pick -x bar foo < data.txt

(3)   pick -A < data.txt
```

Columns can be picked using a regular expression for column names. This can be helpful for large tables. Quotes
are needed to prevent shell interpretation of characters that are special to the shell.
The following examples selects column `zut`, columns with names that start with `foo` followed by a digits
and columns that start with `bar_`.

```
pick zut '^foo\d+$' '^bar_' < data.txt
```

A pattern that contains any of `[({\*?^$`
is assumed to be a regular expression rather than just a column name.
This can be turned off (across all column names) with the `-F` (fixed) option. For per-column avoidance
of interpretation as regular expression use url-encoding of its name.

[Pick allows use of regular expressions selection in various places.](#selecting-and-manipulating-multiple-columns-with-regular-expressions-lists-and-ranges)  
[Several pick column operators also use regular expressions.](#useful-regular-expression-features)


### Picking columns using indexes and index ranges

If no header is present indexes and index ranges can be used.
`-k` implies the first row has no special meaning (as column names) and handles are 1-based indexes.

```
pick -k 5 3 7-9 < data.txt
```

The following index expressions are supported:

```
x                    column x
x-y                  columns from x to y
x-                   column x and all onward
'o+x-y*m'            columns o+x to o+my with increments of m (quotes needed for *)
'x-y*m'              columns mx to my with increments of m (quotes needed for *)
o+x-y                columns o+x to o+y
```


## Pick columns and filter or select rows


- Strings starting with `@` or `@@` both indicate a selection on one or two column values.
- `@` selections can operate on computed columns and computed values that are not output (see further below).
- `@` selections are performed after all computations are finished and have access to all input columns and compute handles.
- `@@` selections are peformed *before* any computation happens and have access to input columns only. A row that is
  filtered this way will not trigger any computation.
- Selections can be placed anywhere, mixed in with column selections and computations as required.
  This can be used to make pick invocations more self-documenting.
  In some situations this is achieved by grouping selections together, in other situations
  a selection is best placed next to the column name or computation to which it refers.

Pick columns `foo` and `bar`, only taking rows where `tim` fields are larger than zero.
multiple `@` selections are possible; default is `AND` of multiple clauses, use `-o` for general selection `OR`
and `-s` for pre-selection `OR`.
`tim` can refer to a newly computed variable (see below).

```
pick foo bar @tim/gt/0 < data.txt
```

where `tim` is larger than the column value in `zut` (the leading colon in `:zut` indicates
that the value to compare to should be taken from column `zut`):
```
pick foo bar @tim/gt/:zut < data.txt
```
It is possible for `zut` to be [a newly computed value derived from other (existing or computed) columns](#examples-of-computing-new-columns).


The examples so far and the examples further below use `@` rather than `@@`
selections. The advantage of the latter form is that in some cases it can be be
wasteful and/or difficult to compute new values if they should be thrown away
anyway. One example is when a division is computed and rows where the
denominator is zero should be discarded. The following sequence of examples
shows the different ways `pick` can handle this situation:


```
   # example data:
> echo -e "foo\tbar\n5\t8\n1\t0" | pick -A
foo   bar
5     8
1     0

   # divide by zero (crash - not handled)
> echo -e "foo\tbar\n5\t8\n1\t0" | pick -h ::foo:bar,div
0.625
Illegal division by zero at pick line 221, <> line 3.

   # selection happens after computation, so this does not help (crash again)
> echo -e "foo\tbar\n5\t8\n1\t0" | pick -h ::foo:bar,div @bar/ne/0
0.625
Illegal division by zero at pick line 221, <> line 3.

   # protect against divide by zero, included in output ('inf' in output)
> echo -e "foo\tbar\n5\t8\n1\t0" | pick -hP ::foo:bar,div
0.625
inf
-- 1 items needed not-a-number protection (0 rows discarded)

   # protect against divide by zero, compute, exclude from output after compute (wasteful)
> echo -e "foo\tbar\n5\t8\n1\t0" | pick -hP ::foo:bar,div @bar/ne/0
0.625

   # @@ pre-select -- BEFORE computation (clean)
> echo -e "foo\tbar\n5\t8\n1\t0" | pick -h ::foo:bar,div @@bar/ne/0
0.625
```

<details><summary>Further selection examples</summary>

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

Constant values and column handles are URL-decoded, hence the escape mechanism
for including any of the characters `^:,%` in a constant value or column handle is to url-encode them.
The following is an example of a computation:
```
:foo^144,add
```
is an expression that indicates the column named `foo`, the number 144 and the `add` operator.
The result of it is the sum of the value in the `foo` column and 144.

Advantages of this notation are (1) whitespace is not needed (often avoiding
the need to quote computations) (2) the separation of types means there is no
list of reserved words (operators can be added freely) and (3) the stack syntax avoids
the need for grouping syntax such as braces or parentheses, again aiding brevity
and reducing the need to quote.

Each computation needs a name. It can be thought of as a variable name. If the computation
is output as a new column the name will be used as the column name. The two forms are below,
where (1) `newname` will not be output as a new column (but is still available e.g. for other computations or comparison)
and (2) `newname2` will be output.

```
(1)   newname1:=<compute>

(2)   newname2::<compute>
```

- It is possible to omit a new name if the output is not to contain column names and there is no need
  to reuse the computation later. The part `::` or `:=` still has to be specified.
- If the first element in `<compute>` is a column name, the leading `:` can be dropped.

Below illustrates the two aspects above. The second `pick` invocation shows the computation/column names that
are automatically generated if not specified and uses the full form `:foo` after the `::` name/compute separator.
```
> echo -e "foo\taa\n4\t5" | pick -h ::foo^144,add
148

> echo -e "foo\taa\n4\t5" | pick :::foo^144,add ::^wow
PICKAAAAA  PICKAAAAB
148        wow
```

## Examples of computing new columns

The following compute puts two column values on the stack (for columns `yam` and `bob`), then subtracts
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

The following example swaps two columns whilst retaining all other columns.
This is just to illustrate how
columns and compute names interact; a simpler way to do the same is shown after.
Compute names are like normal variables, so to swap two values a third name is needed.

```
pick -Aki foo:=1 1::2 2::foo < data.txt
```

-   -k implies no columns names are read, column handles are 1 2 3 ..
-   -A selects all columns for output.
-   -i is needed to allow overwriting existing columns 1 and 2.  
-   Assignments happen proceeding from left to right
-   := computes a value without outputting it,
-   :: computes a value and selects it for output.


A simpler way of doing the same is this:
```
pick -k 2 1 3- < data.txt
```

If you just want columns `2` and `1` in that order it only needs
```
pick -k 2 1 < data.txt
```

## Choosing and finding from pick's arsenal of operators

Pick has a lot of operators. You can list all of them (with a short description) by issuing
```
pick -l
```
At the end of that output pick gives a list of labels; currently these are
`arithmetic bio bitop branch demo devour dictionary format input math output precision regex sam stack state string test`
and `EXPERIMENTAL`. Most operators have been tagged by multiple labels.
You can list all operators with a label with `pick -l TAG` (in fact, `TAG` is treated as a regular expression).
Finally `--sam` makes available more operators that support querying SAM files. To list these use
```
pick --sam -l sam
```

## Selecting and manipulating multiple columns with regular expressions, lists and ranges

There are three modes of selecting/modifying multiple columns. Each is briefly
introduced below, followed by more examples and explanation.


-  Simply selecting multiple columns for output. Example usage
```
   pick 'num\d{2}$' < data.txt
```

-  Selecting multiple columns and reducing them to a single value by e.g. concatenation,
   taking the minimum or maximum, or adding all values. Examples of usage:
```
   pick nummax::'num\d+$',maxall < data.txt               # largest among all num[digit] columns

   echo {1..20} | tr ' ' $'\t' | pick -k ::'.*',mulall    # compute 20 factorial

   echo {1..9} | tr ' ' '\t' | pick  -iK sum-squared::'.*',addall,sq '.*':=__^3,pow sum-cubes::'.*',addall | column -t

                                                          # compute 1**3 + 2**3 + .. + 9**3 and
                                                          # (1+2+..+9)**2
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
   x_01  x_02  x_03
   4     5     6
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
a     b     c     oldsum
9     16    25    50
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
--kdict-NAME=/path/to/dictfile      (key,value) = (col1, 1)     only ever use col1

--cdict-NAME=foo:bar,zut:tim        comma-separated key:value pairs
--cdict-NAME=foo,zut                comma-separated keys, all set to value 1

--fasta-dict-NAME=/path/to/fastafile   read ID->sequence mapping from fasta file
--fastq-dict-NAME=/path/to/fastqfile   read ID->sequence mapping from fastq file
--table-dict-NAME=/path/to/tablefile   read ID->column->item mapping from table file with row names
```

`NAME` is the name of the dictionary. Multiple dictionaries can be imported.
A dictionary is specified by its name for use with the `map` operator or `tmap` operator for table dictionaries.
**A table dictionary uses the row names in the file as key,**
and associates for each row name its column values by using the column name as key.
`map` needs two keys; the first is the item to look up, the second is the `NAME` of the dictionary to use.
`tmap` needs a third key; the name of the column.
Multiple dictionary specifications can be used for the same `NAME`.

```
echo -e "a\t3\nb\t4\nc\t8" | pick -Aik --cdict-foo=a:Alpha,b:Beta 1::1^foo,map
```

By default if no key is found in the dictionary the value is left alone. It is possible
to specify a not-found string using this syntax:

```
--fdict-NAME/STRING=/path/to/dictfile
--cdict-NAME/STRING=foo:bar,zut:tim
--fasta-dict-NAME/STRING=/path/to/fastafile
--fastq-dict-NAME/STRING=/path/to/fastqfile
--table-dict-NAME/STRING=/path/to/tablefile
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

**For all fasta dictionaries if no not-found string is specified it will be set to `__EXIT__` and pick
will thus exit with an error if a sequence cannot be found** (see the section below). This behaviour can be made permissive
by explictly specifying a `not-found` value.


### Exiting when a column value cannot be mapped

By default `pick` leaves a value unchanged if it cannot be mapped. As shown above a `not-found`
value can be specified (for any of the dictionary loading options) using e.g.

```
--fdict-NAME/MiSSING=somefilename
```

Pick can be instructed to exit with an error by using the special value `__EXIT__`. Thus

```
--fdict-NAME/__EXIT__=somefilename
```

will cause `pick` to fail if a column value is mapped with dictionary `NAME` and the value
is not present as a key in the dictionary (loaded from file `somefilename`).



Other uses of the `not-found` syntax are to select or filter columns, e.g. below
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


## Operators for testing and choice


The `test` operator computes a test on two values and yields 1 if the test succeeds and 0 if the test fails.
It takes three arguments: The two values to compare and a constant value that must be a one of the
comparison operators below - these are [the same as can be used for row filtering](#pick-columns-and-filter-or-select-rows).

```
    = /=                            string identy select, avoid
    ~ /~                            string (Perl) regular expression select, avoid
    ~eq~ ~ne~ ~lt~ ~le~ ~ge~ ~gt~   string comparison
    /eq/ /ne/ /lt/ /le/ /ge/ /gt/   numerical comparison
    /ep/ /om/                       numerical proximity (additive, multiplicative)
    /all/ /any/ /none/              bit selection
```

Below is a test whether the value in column `foo` is greater than the value in column `bar`:

```
::foo:bar^/gt/,test
```

The next example replaces each entry in a table with the truth value whether the original
value was positive or not:

```
pick -Ai '.*'::__^0^/gt/,test < data.txt
```

Currently the epsilon and order-of-magnitude tests `/ep/` and `/om/`
are hardwired to their default values of `1.0001` and `2`, unlike their row selection counterparts
that allow an optional band argument.


The `ifelse` operator takes three argument. The first argument is tested. If it looks like a number
the test is whether it is nonzero. Otherwise the test fails only if the first argument is the empty string.
If the test succeeds `ifelse` yields the second argument, otherwise it yields the third argument.


The `uie` (use if empty) operator takes two arguments. It yields the first argument unless it is
the empty string, in which case it yields the second argument. This can be useful in conjunction with
a dictionary mapping where the default value is set to the empty string.



## Ragged input

Ragged input (rows with varying number of columns, such as possible with SAM format) can be processed by using the option `-O<NUM>`
and requires additionally the `-k` parameter. With this type of input column names are not supported.
At most `<NUM>` columns are consumed in each row. Excess fields in the row will be concatenated
onto the last consumed column. If the input row has fewer than `<NUM>` fields additional empty fields
will be added (and output e.g. if `-A` is used).

_For SAM input just use either_ `--sam` _or_ `--sam-h` (the latter will output the SAM header if present).

See below for more information about SAM format support.


## SAM format support

SAM support has seen a lot of recent development. This documentation section is not yet fully crystallised.

SAM support is currently entirely focused on single-end reads. Aspects of paired-end alignment that do not depend
on the paired-end / single-end dichotomy may be perfectly amenable to pick processing but none of it
has been tested by me.

Pick follows a streaming paradigm but has provisions for caching where SAM format requires it,
namely the query sequence field (column 10).
*Pick will ensure that the query sequence is made available in the reference orientation.*
To this end (if you invoke a pick operator
that needs the query sequence) it is necessary that input is sorted or collated by read name and additionally
that within the group of records/alignments for each read the primary alignment is sorted first.
Currently samtools does not guarantee this;
future versions will [since this was raised in an issue (March 2024) and then addressed](https://github.com/samtools/samtools/issues/2010).

An intermediate solution for now is to pipe the output of `samtools view` to `sort -k 1,1 -k 2,2n` before piping it to `pick`.
If interest is only in the primary alignment no sorting is necessary and you can use

```
samtools view -F 2308
```

Remember that bit 256 indicates a secondary alignment and bit 2048 indicates a supplementary alignment. It should be possible
to view such alignments and retrieve alignment-related quantities wit pick (see below for possibilities) by using

```
samtools view -F 4 | sort -k 1,1 -k 2,2,n
```

Finally, bit 4 indicates an unmapped read. If you invoke an operator that requires the reference sequence then `pick`
will assign the empty string to the reference sequence. For understandable output it is best not to cross these streams.



### Activating SAM support and loading reference sequences

Use `--sam` or `--sam-h` if the input is SAM format.
If the output should still contain the SAM header use `--sam-h` and use `samtool view -h` to ensure
pick is in a position to do so.
The following shorthands can be used to specify SAM format and a reference fasta file to be loaded.
The sequences will be stored in the dictionary called `SAMFA`.
```
   --sam/FILENAME                # short for     --sam --fa-dict-SAMFA/__EXIT__=FILENAME
   --sam-h/FILENAME              # short for   --sam-h --fa-dict-SAMFA/__EXIT__=FILENAME
```

Either of these options will
- set the options `-k` (headerless input) and `-O12` (overflow columns collated in column 12)
- make the sequence lengths available in the `seqlen` dictionary (if the sam header is found)
- make the reference sequences available to operators (if provided as a fasta dictionary)
- make the query sequence available to operators (in the reference orientation)

If a fasta file is specified then any reference ID that can not be retrieved from the fasta file
will cause pick to exit with an error. This can be avoided, if necessary, by using the longer form,
e.g. `--sam --fa-dict-SAMFA/=FILENAME` where the default `not-found` value is set to the empty string.

If sequence lengths are found in the header they will be compared to the fasta
sequences (if present) and a summary is written to diagnostic output.  With
this a reference sequence can be retrieved from the reference field (column 3
in SAM format) with
```
::3^SAMFA,map
```

In most cases operators that require the reference sequence will automatically load it.
These operators do not need to be supplied with the name of the sequence dictionary:
**the first fasta dictionary that is specified is taken to contain the sequences matching the SAM input**.

When using either of `--sam` or `--sam-h` pick makes several new operators
available that compute certain alignment-related quantities, offsets and
widths, listed in the two tables below.

With these operators pick can be used to efficiently filter alignments, for example
removing those that do not start near expected primer sites (see below). Other applications
include the computation and extraction of quantities for quality control.

### Operators to output alignments

```
(require the reference sequences to be loaded - see above)
---------------------------------------
aln_aln      -      alignment string between reference and query
aln_qry      -      alignment string for query
aln_ref      -      alignment string for reference
```

### Operators to retrieve mismatch and indel positions and sequences

```
(require the reference sequences to be loaded - see above)
---------------------------------------
alnedit      -      Edit distance excluding clipping - obtained from NM field
alnmatch     -      Amount of reference/query matched by alignment (ignoring indels and mismatches)
alnmatchx    -      Number of base mismatches
alnposx     <num>   Mismatch positions+change and indel sequence reported up to a length of <num>
```

### Operators to retrieve query sequence parts

The retrieved sequences are in **in reference orientation**.

```
(require the reference sequences to be loaded - see above)
---------------------------------------
qry_seq      -      query sequence in reference orientation
qry_matched  -      matched query sequence in reference orientation
qry_trail3p  -      3' unaligned query sequence in reference orientation
qry_trail5p  -      5' unaligned query sequence in reference orientation
```

### Examples

**Example 1**  
Below creates an intermediate tab-separated table with fields `edit-distance`, `reference ID`, `query ID` followed by three alignment strings;
it then sorts them by edit-distance and outputs them as paragraphs, resulting in correctly displayed alignments, sorted
from fewest edits to most edits.
```
cat some.sam | pick --sam/some.fa ::,alnedit:1:3,aln_ref,aln_aln,aln_qry^%09,joinall | sort -n | pick -k ::^:'.*'^%0A,joinall > some.align

...

7
z1xb1-read5
Z2W2rc
CTAGGGCGTTATTGCGCA--GTTTGTGGCTCC-TCAAATCTCGT-CCGACATGTCATCACA
||||||||||||||||||--||||||||||||-|||||---|||-||||||||||||||||
CTAGGGCGTTATTGCGCAGTGTTTGTGGCTCCATCAAA---CGTCCCGACATGTCATCACA


8
f1Xs1-read2
G1S1rc
AGGGCGTGCCGAGCTTC-C-TCCGATATTCATCGACATCCTTCA----AAGCTATTTGATTG
|||||||||||||||||-|-|||--|||||||||||||||||||----||||||||||||||
AGGGCGTGCCGAGCTTCACGTCC--TATTCATCGACATCCTTCATTGCAAGCTATTTGATTG

...
```
The script [utils/samordermatches.sh](utils/samordermatches.sh) wraps the above functionality. It is invoked as
```
cat some.sam | samordermatches.sh some.fa > some.align
```
and can easily be modified to change output format or add filtering modes.


**Example 2**  
```
cat some.sam | pick --sam/some.fa ::^10,alnposx
```
This outputs a description of all edit events, where indel sequences are reported up to a length of 10.
The output is a concatenation (separated by `:`) of items of the following types:
```
x=3,c=TC                # A mismatch at position 3, base change T to C
i=65,n=1,s=T            # An insertion at position 65 of size 1, sequence T
d=79,n=1,s=ATTA         # A deletion at position 79 of size 4, sequence ATTA
e=144,n=108             # An 'expected' deletion (intron/splice) event at position 144 of size 108
```

### Operators returning offsets and lengths

The following set of operators does not need sequences, but `reflen` does expect sequence length information
to be present in the SAM header information and thus needs for example input such as provided by `samtools view -h`.

```
---------------------------------------
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

qcl::,qryclipl      NA                       Number of 5p trailing query bases [sam]
qcr::,qryclipr      NA                       Number of 3p trailing query bases [sam]
rcl::,refclipl      NA                       Number of 5p trailing reference bases [sam]
rcr::,refclipr      NA                       Number of 3p trailing reference bases [sam]
```

Make sure to use `samtools view -h` to include header information so that `reflen` is available.
Should a sequence name not be found in the `seqlen` dictionary the value `0` is returned for the sequence length.
In this case pick currently issues an error only if `reflen` is used (not in case `3^seqlen,map` is used).
To require alignment to be proximal within 20 bases to primer sites, use e.g.

```
mark5p=123     # your value here
mark3p=1234    # your value here
samtools view -h <bamfile> | pick --sam-h -A delta5p:=,refstart^$mark5p,sub delta3p:=^$mark3p,refend,sub @delta5p/le/20 @delta3p/le/20
```


### Cigar string operators

Pick has a few older operators that support parsing of SAM columns.
For now this pertains specifically to the CIGAR string in the sixth column.
In most cases one of the higher-level
operators from the preceding sections can be used for more succinct and clear instruction.

Below `<cigaritems>` is a user-defined subset of `MINDSHP=X`, the different
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


## Splitting, demultiplexing and forking rows across different outputs

Pick can be used to split or demultiplex output into different files. Use e.g. this combination, where `NAME` is
of your choice:

```
--demux=NAME NAME:=sampleid^.txt
```

This tells pick to use a row's `NAME` column as the file name to write the row to, where
`NAME` can be any column (input or computed).
In this example `NAME` is a computed column that is not output, where the filename is
formed from the value in the `sampleid` column with a `.txt` suffix added to it.

_Pick will recognise file names ending in_ `.gz` _or_ `.gzip` _and in that case compress the output using gzip._

The next example splits the input into chunks of size `1000`, retaining the header for each,
with output names defined in the `S` column as `split<N>.txt`, where `<N>` are zero-padded batch numbers.


### Splitting a table into smaller tables for parallel processing

```
pick -A --demux=S S:=^split,r0wno^1000,idiv^4,zp^.txt < data.txt
File           Written  Filtered
split0001.txt  1000     0
split0003.txt  1000     0
split0002.txt  1000     0
split0000.txt   384     0
```

If `--demux` is used pick will output on `STDERR` a table of output files and tallies of
how many rows each file contains, as well as how many were deselected.
The set of all output files will always correspond to the full set of unique values accumulated
over the `<NAME>` column across all input rows, regardless of whether a row is deselected or not.
Hence, in the presence of selection, demux files may contain zero data rows.
Demux output files have or do not have a header line in line with the `-k` and `-h` options,
just like normal output.


### Combining demuxing and deselecting


A separate and compatible forking mechanism exists that allows sending of any de-selected row (i.e. one that
does not satisfy the `@` selection criteria) to a specified file name. This is achieved with

```
--other=<FILENAME>
```

These two mechanisms can be used simultaneously. Similar to demuxing, a file name ending in `.gz` or `.gzip`
causes the file to be compressed using `gzip`.


### Taking a single indexed batch from a table

If a parallel task receives an index `K`, a batchsize `N`, and the location of a master table `T`
then one way of coordinating batches between different tasks is the following:

```
pick -A @batch=$K batch:=,r0wno^$N,idiv < $T
```


## Retrieving unique values and asserting the number of rows found

If the input is queried for a value that should be present and unique, you can do pick let the checking
by passing `-E1`. More generally `-E<NUM>` will exit with an error if the number of rows found is
different from `<NUM>`.


## Miscellaneous


### Escaping special characters

Some uses of pick, especially involving computation, may require characters with special meaning
either to the shell or to pick to be escaped. For the shell aspect this is usually possible simply by using
single quotes. For pick the mechanism used is url-encoding, and this can equally be
used for characters with special meaning to the shell.

A url-encoded character is written as a percent sign followed by two hexadecimal digits (a hexadecimal
digit is one of `0123456789ABCDEF`), for example `%0A` for `<NEWLINE>`. A list of useful cases (note that
lower case versions of these are allowed too):

```
  ^   %5E     ;   %3B     (  %28     <TAB>      %09
  :   %3A     !   %21     )  %29     <NEWLINE>  %0A
  ,   %2C     /   %2F     <  %3C     <CR>       %0D     @   %40
  %   %25     \   %5C     >  %3E     <SPACE>    %20     =   %3D
```

Use `pick -z` to show this list, use `pick -z <string>` to url-encode string, and `pick -zz <string>`
to url-decode `<string>`.

The characters `= / , : ^` require url-encoding in certain contexts as they are used as pick syntax:

- `^`, `:`, `,` and `=` are used in computation syntax.
- `/`, `:` and `,` are used in map specifications using `--cdict-NAME=k1:v1,k2:v2`.

These will be URL-decoded:

- Column names specified on the command line, including regular expressions expanding to column names.
- For a computation `<name>::<compute>`, both `<name>` and any constants and names found in `<compute>`.
- In selection filters `@<name><op><:name|constant>` both `<name>` and `<:name|constant>`.
- In `--cdict-NAME/default=k1:v1,k2:v2` all keys (`k1` etc) and values (`v1` etc).

### Maps can be useful to update (subsets of) data

The following idiom updates (a subset of) rows in file `data.txt` using the mapping found in file `update.txt`.
The mapping dictionary `not-found` value is set to the empty string.
If no mapping exists the original value is reinstated via the `uie` (use if empty) operator.
```
pick -Ai --fdict-UPDATE/=update.txt fx::name^UPDATE,map:fx,uie < data.txt
```
This example can be run in the `test` directory in this repository.


### Maps can be useful to select or filter out data

Direct filtering of data based on information in the table is not always possible.
In some cases an external list has been computed that contains identifiers
for which the rows should be deleted or retained. This is generically done like this:

```
pick  -A --kdict-DEL/keep=delete-file.txt action:=myid^DEL,map @action=keep < data.txt > reduced-data.txt
```

Here a temporary column `action` is computed that contains the value in the `myid` column mapped
using the keys in the file `delete-file.txt`. If the value is not to be deleted it is set to the
default value `keep`. Finally those rows are chosen where `action` has that value `keep`.

Although the values `DEL` and `keep` are never seen in the output, it is useful to choose these
strings such that the command line is self-explanatory.
Note that for `--kdict` pick will set the value for each key to be deleted to `1`. It is necessary
to set the `not-found` value to something different, in this case `keep`.

The `pick` invocation if keys need to be retained is very similar, changing `action` to avoid `delete` values.

```
pick  -A --kdict-KEEP/delete=keep-file.txt action:=myid^KEEP,map @action/=delete < data.txt > reduced-data.txt
```

[More information about maps.](#map-column-values-using-a-dictionary)


### Creating FASTA and FASTQ files

Create FASTA files with pick. The operator `,fasta` makes this easy.
Previously one needed, assuming identifier and sequence are stored in `key` and `sequence`
(quotes needed as `>` is special to the shell),
```
pick  -h '::^>:key^%0A:sequence' > out.fa
```
This has now been simplified to
```
pick  -h ::key:sequence,fasta > out.fa
```
The `,fasta` operator requires two string values on the stack. To add further
annotation to the identifier line construct the required sequence of strings
and then apply for example `,catall`. The example below constructs a template
` (zut=#)` and then replaces the placeholder character `#` with the column/variable `zut`.
The template is quoted to avoid shell interpretation of parenthesis and hash sign.
```
pick  -h ::key^' (zut=#)^#':zut,ed,catall:sequence,fasta > out.fa
```

The `,fastq` operator works in exactly the same way as the `,fasta` operator.
The result is a FASTQ record, where the quality string is currently always set to `Z`
in every position.


### Useful regular expression features

-  Use `(?:...)` to group a pattern without creating a backreference - this can
   be relevant for `get` (see below).  **In pick computations** this has to be
   specified as `(?%3A...)` due to the special meaning of the colon.

-  Use `\K` (keep) to anchor a pattern but retain it with `ed  edg  del  delg`, e.g.

   `:HANDLE^'patx\Kpaty',delg` will retain pattern `patx` and only delete pattern `paty`.

   Example:
```
> echo -e "a\nthequickbrownfox theslowbrownbear" | pick -h ::a^'quick\Kbrown',delg
thequickfox theslowbrownbear
```

-  Use `\K` (keep) to anchor a pattern but *ignore* it with `get`. Consider the following
   examples.

(1) In the absence of parentheses, `get` will grab the matched pattern.
```
> echo -e "a\nquick fox" | pick -h ::a^'\S+\s+\S+',get
quick fox
```
(2) It is possible to anchor the pattern with `\K`; anything before `\K` will
   not be included in the matched part.
```
> echo -e "a\nquick fox" | pick -h ::a^'\S+\s+\K\S+',get
fox
```
(3) If parentheses are used, `get` will get the pattern within the leftmost pair of
   parentheses that is not neutralised by the `(?%3A..)` construct.
```
> echo -e "a\nquick fox" | pick -h ::a^'\S+\s+(\S+)',get
fox
```
(4) The leftmost group is used ..
```
> echo -e "a\nquick fox" | pick -h ::a^'(\S+)\s+(\S+)',get
quick
```
(5) from those groups that actually induce backreferences.
```
> echo -e "a\nquick fox" | pick -h ::a^'(?%3A\S+)\s+(\S+)',get
fox
```

-  Use `patx(?=paty)` to anchor `patx` to `paty` without including `paty` in the matched part.

   `:HANDLE^'patx(?=paty)',get` will just fetch `patx`.

   Example:

```
> echo -e "a\nthequickbrownfox\ntheslowbrownbear" | pick -h ::a^'brown(?=bear)',delg
thequickbrownfox
theslowbear
```

   Such patterns can be combined - here either of the two is considered match:
```
> echo -e "a\nthequickbrownfox\ntheslowbrownbear" | pick -h ::a^'brown(?=bear)|quick\Kbrown',delg
thequickfox
theslowbear
```

-  Use `(?i)pat` to make a pattern case insensitive.


### Applying the same action to each table entry

The recipes below can be limited to a set of columns by 
using [regular expressions, lists and ranges](#selecting-and-manipulating-multiple-columns-with-regular-expressions-lists-and-ranges).
In these examples all column names are selected with the regular expression `'.*'` that will match any string of at least one character.
The in-place option `-i` is needed as input columns are changed and output under the same name.

Increment each entry by one:
```
pick -i '.*'::__,incr < data.txt
```

Format each entry to have two digits behind the decimal comma:
```
pick -i '.*'::__^2,dd < data.txt
```

Format each entry in scientific notation with five significant digits:
```
pick -i '.*'::__^5,sn < data.txt
```

Remove leading and trailing whitespace (`%5E` url-encodes beginning of string `^`, here needed as `^` indicates
a constant in pick computations):

```
pick -i '.*'::__^'(%5E\s+|\s+$)',delg < data.txt
```


### Loading data from the previous row

   To cache/store the previous row use one of
```
--pstore
--pstore/<LIST>
--pstore/<LIST>/<DEFAULT>
--pstore//<DEFAULT>
```

   Fields from the previous row are then available to load with `^colname,pload`.
   If specified, `<LIST>` should be a comma-separated string of key-value pairs themselves
   separated by a colon; all keys and values will be URL-decoded. The keys should be column names;
   the values will be used to initialise the fields of the predecessor of the first row.
   If `<DEFAULT>` is specified it is used for all columns not yet named.
   Example (compute the first ten Fibonacci numbers):
```
yes | head | pick -k --pstore/x:1,y:0 x::^y,pload y::x^x,pload,add
```

### Loading a previous row within a group

This functionality is an extension of the general caching mechanism (`--pstore` in the previous section). With either of

```
--group=<COLNAME>
--group-first-ref=<COLNAME>
```

pick recognises groups of consecutive rows where column `<COLNAME>` has the same value.
The first row of such a group is always skipped (after computation, before output). Each subsequent row of the
group can load column values from a reference row using `pload`.
With `--group` the reference row is simply the previous row.
With `--group-first-ref` the first (skipped) row is the reference row.
If there are no consecutive rows in the input where `<COLNAME>` assumes the same value then all rows will be skipped.


Below groups based on the value found in column `gene`, then retrieves the previous exon end coordinate
and the current exon start coordinate, increments the former and decrements the latter, thus
outputting intron coordinates.
```
pick --group=gene intron_start::^exon_end,pload,incr intron_end::exon_start,decr < data.txt
```


## Option processing

Single-letter options can be combined or specified separately. The offset for `-O` (ragged input), optional offset for `-A`
(insertion of new columns) and `-E` expected result count are accommodated, so e.g. `-kA2O12` will be understood by pick.
The option for purging lines with a certain pattern `/<pat>` and the option for passing through
lines with a certain pattern `//<pat>` can be tagged on at the end, e.g. `-kA2/#`.


## Pick options

-  `-l` print a table of all pick operators.
-  `-l <str>` as above, limited to operators in sections matching `<str>`.  
   Available sections are `arithmetic bitop devour dictionary format input math output precision regex sam stack string`.
-  `-H` summary of pick syntax.

-  `--sam` / `--sam-h` Expect sam input, pass through sam header (`--sam-h`).  
   These options effectively set `-k -O12`, `-/^@` (`--sam`) or `-//^@` (`--sam-h`) and
   additionally store sequence lengths in the `seqlen` dictionary if the input contains a sam header.

-  `-h` do not print header
-  `-k` headerless input, use 1 2 .. for input column names, `x-y` for range from `x` to `y`.
-  `-o` OR multiple **select** criteria. Applies only to **post**-computation select, default is AND.
-  `-s` OR multiple **preselect** criteria. Applies only to **pre**-computation select, default is AND.
-  `-x` take complement of selected input column(s) (works with `-i`)
-  `-c` only output the count of rows that pass filtering
-  `-i` in-place: `<HANDLE>::<COMPUTE>` replaces `<HANDLE>` if it exists
-  `-/<pat>`  skip lines matching `<pat>`; use e.g. `-/^#` for commented lines, `-/^@` for sam files
-  `-//<pat>` pass through lines matching <pat> (allows perl regular expressions, e.g. `^ $ . [] * ? (|)` work.
-  `-v` verbose; this ups the level so `-vv` and `-vvv` will make pick even more verbose
-  `-q` quiet; this does the opposite of `-v`.
  
-  `-A` print all input columns (selecting by colspec applies, -`T` accepted)
-  `-A<N>` `<N>` integer; insert new columns at position `<N>`. Negative `<N>` is relative to rightmost column.
-  `-O<N>` `<N>` integer; allow ragged input (e.g. SAM use `-O12`), merge all columns at/after position `<N>`
-  `-E<N>` `<N>` integer; expect <N> rows returned, exit with error if this is not the case.
-  `-P` protect against 'nan' and 'inf' results (see `-H` for environment variables `PICK_*_INF`)
-  `-Z` as `-P`, discard rows that have items that need protecting
  
-  `-K` headerless input as `-k` but use derived names to output column names
-  `-U` with `-k` and `-K` keep output columns unique and in original order
  
-  `-R` add `_` column variable if no row name field exists in the header. Note: an empty field is recognised and mapped to `_` automatically.
-  `-f` force processing (allows both identical input and output column names)
-  `-F` fixed names; do not interpret names as regular expressions. Default behaviour is to assume a regular expression if a name contains one of `[ { ( \ * ? ^ $` .
-  `-z  ARG+` print url-encoding of `ARG+` (no argument prints a few especially useful cases)
-  `-zz ARG+` print url-decoding of `ARG+`
  
-  `--inf=<str>` Set divide-by-zero result to `<str>`
  
-  `--` This option is ignored, all further arguments are considered column names or regular expressions to retrieve column names.

-  `--add-inames=<csv>`, `--inames=<csv>`  
    comma-separated values to use as column names instead of actual column names.
    The list must cover all columns in the input. Names that are used
    in selection, compute and filter expressions must be picked from this list.
    Output names are from the list. If using `-k` then `--inames=CSV` provides temporary
    handles; use `--add-inames=CSV` to add them to the output.

-  `--onames=<csv>` Override output column names to be taken from comma-separated values.

-  `--idx-list`        Output list of selected indexes (on a single line).  
   `--name-list`       Output list of selected column name (on a single line).  
   `--idx-map`         Output pairs of selected `<index> <column name>`, one per line.  
   Pick will exit after any of them is used.

-  `--version` Output version number; outputs a corresponding git tag and date
   tag. The aim is for this to be the git tag `x` of commit `x` that is prior
   to commit `y` that inserted `x` into the pick version tag. I'm not quite
   sure how well this executes the idea of an informative and lazy version
   numbering system.


-  `--pstore`  
   `--pstore/<LIST>`  
   `--pstore/<LIST>/<DEFAULT>`  
   `--pstore//<DEFAULT>`  
   [Use one of these to load data from the previous row.](#loading-data-from-the-previous-row)


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


Arithmetic: `add addall catall decr div idiv incr max maxall min minall mod mul mulall pow sub`

Bit operators: `and or xor`

Stack devourers: `addall gmeanall hmeanall joinall maxall meanall minall mulall`

Dictionary: `map`

Formatting: `binto dd frac hexto md5 octto pct pml sn tobin tohex tooct urldc urlec`

Input: `binto hexto lineno md5 octto rowno r0wno urldc urlec`

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
F0          -           F[0]                First input column [demo]
abs         x           abs(x)              Absolute value of x [math]
add         x y         x+y                 Add x and y, sum, addition [arithmetic]
addall      *           sum(Stack)          Sum of all entries in stack [arithmetic/devour]
and         x y         x and y             Bitwise and between x and y [bitop]
binto       x           x'                  Read binary representation x [input/format]
cat         x y         xy                  Concatenation of x and y [string]
catall      *           Stack-joined        Stringified stack [string/devour]
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
fasta       i s         fasta format        ID and sequence in FASTA format [sam]
fastq       i s         fastq format        ID and sequence in FASTQ format [sam]
floor       x           floor(x)            The floor of x [math]
frac        x y N       x/y                 Division, fraction x/y with N decimal digits (cf -P and PICK_DIV_INF) [precision/format]
get         x r         r-match-of-x        If x matches regex r take outer () group or entire match, empty string otherwise (cf uie) [string/regex]
gmeanall    *           gmean(Stack)        Geometric mean of all entries in stack, multiplication [arithmetic/devour]
groupi      -           x                   Push within-group offset x onto stack [input]
groupno     -           x                   Push group number x onto stack [input]
hexto       x           x'                  Read hex representation x [input/format]
hmeanall    *           hmean(Stack)        Harmonic mean of all entries in stack [arithmetic/devour]
idiv        x y         x // y              Integer division, divide (cf -P and PICK_DIV_INF) [arithmetic]
incr        x           x++                 x incremented by one [arithmetic]
int         x           int(x)              x truncated towards zero (do not use for rounding) [math]
joinall     * s         Stack-joined-by-s   Stringified stack with s as separator [string/devour]
lc          x           lc(x)               Lower case of x [string]
len         x           len(x)              Length of string x [string]
lineno      -           x                   Push file line number x onto stack [input]
log         x           log(x)              Natural logarithm of x [math]
log10       x           log10(x)            Logarithm of x in base 10 [math]
log2        x           log2(x)             Logarithm of x in base 2 [math]
map         x dname     map-of-x            Use map of x in dictionary dname (if found; cf --cdict-dname= --fdict-dname=) [string/dictionary]
max         x y         max(x,y)            Maximum of x and y [arithmetic]
maxall      *           max(Stack)          Max over all entries in stack [arithmetic/devour]
md5         x           md5(x)              MD5 sum of x [string/format/input/output]
meanall     *           mean(Stack)         Mean of all entries in stack [arithmetic/devour]
min         x y         min(x,y)            Minimum of x and y [arithmetic]
minall      *           min(Stack)          Min over all entries in stack [arithmetic/devour]
mod         x y         x mod y             x modulo y, remainder [arithmetic]
mul         x y         x*y                 Multiply x and y, multiplication, product [arithmetic]
mulall      *           product(Stack)      Product of all entries in stack, multiplication [arithmetic/devour]
neg         x           -x                  The sign-reversed value of x [math]
octto       x           x'                  Read octal representation x [input/format]
or          x y         x or y              Bitwise or between x and y [bitop]
pct         x y N       pct(x/y)            Percentage of x relative to y with N decimal digits (cf -P and PICK_DIV_INF) [precision/format]
pload       c           prevrow[c]          Field of column c in the previous row [state]
pml         x y N       pct(x/y)            Promille of x relative to y with N decimal digits (cf -P and PICK_DIV_INF) [precision/format]
pop         x           -                   Remove top entry x from stack [stack]
pow         x y         x**y                x raised to power y [arithmetic]
r0wno       -           x                   Push current table (start zero) row number x onto stack [input]
rc          x           rc(x)               Reverse complement [string]
rev         x           rev(x)              String reverse of x [string]
rot13       x           rot13(x)            Rot13 encoding of x [crypto]
rowno       -           x                   Push current table (start one) row number x onto stack [input]
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
zp          x N         x'                  x left zero-padded to width of N [output/string/format]
```

These are additionally available if `--sam` is supplied:



```
Operator    Consumed    Produced            Description
--------------------------------------------------------------------------------
aln_aln     -           aln_aln             Alignment string between reference and query [sam]
aln_qry     -           aln_qry             Alignment string for query [sam]
aln_ref     -           aln_ref             Alignment string for reference [sam]
alnedit     -           alnedit             Edit distance excluding clipping [sam]
alnmatch    -           alnmatch            Amount of reference/query matched by alignment (ignoring indels and mismatches) [sam]
alnmatchx   -           alnmatchx           Number of base mismatches [sam]
alnposx     -           alnposx             Mismatch positions [sam]
cgcount     c s         Count of s in c     Count of s items in cigar string c [string/sam]
cgmax       c s         Max of s in c       Max of lengths of s items in cigar string c [string/sam]
cgqrycov    c           qrycov              Count of query bases covered by cigar string c (MI=X events) [string/sam]
cgqryend    c           qryend              Last base considered aligned in query for cigar string c [string/sam]
cgqrylen    c           qrylen              Length of query (MIS=X events) in cigar string c [string/sam]
cgqrystart  c           qrystart            First base considered aligned in query for cigar string c [string/sam]
cgrefcov    c           refcov              Count of reference bases covered by cigar string c (MDN=X events) [string/sam]
cgsum       c s         Sum of s in c       Sum of lengths of s items in cigar string c [string/sam]
qryclipl    -           qryclipl            Number of 5p trailing query bases [sam]
qryclipr    -           qryclipr            Number of 3p trailing query bases [sam]
qrycov      -           qrycov              Span of query covered by alignment [sam]
qryend      -           qryend              Last base in query covered by alignment [sam]
qrylen      -           qrylen              Length of query sequence [sam]
qrystart    -           qrystart            Start of alignment in query [sam]
refclipl    -           refclipl            Number of 5p trailing reference bases [sam]
refclipr    -           refclipr            Number of 3p trailing reference bases [sam]
refcov      -           refcov              Span of reference covered by alignment [sam]
refend      -           refend              Last base in reference covered by alignment [sam]
reflen      -           reflen              Length of reference sequence (requires samtools view -h) [sam]
refstart    -           refstart            Field 4 from sam format [sam]
```


## Pick philosophy

Pick enables `map` and `grep` (i.e. `filter`) type transformations of data tables, on the command line.
The main things I care about are stream (per-line) processing, the usage of column names as variables,
its interface (the domain-specific language), and the way computes are structured and executed.
The interface language was designed to be highly succinct, with a syntax that avoids shell special characters.
Computes embrace a minimalist stack approach, with only three different compute units (constants, variables, and operators).
These elements combine to allow data transformations of large streamed data
tables with the ethos of functional programming, specified in a succint manner.


## Implementation notes

Pick is currently implemented in Perl, a language not as popular as it once was. Nonetheless for data/record munging and
manipulation Perl is a formidable competitor. In particular pick benefits from the
power of perl regular expressions (regexes); these can be used as pick selection and modification operators on the command line.
Perl's support for regexes is built deeply into the language. I've been pleasantly surprised by the seamlessness
and ease of its treatment of command-line strings as regexes.
Some useful regex features are [described here](#useful-regular-expression-features).

Pick additionally benefits greatly from Perl's mechanisms for number/string and string/number conversion.
[Some interesting insights into Perl's data type conversions](https://medium.com/booking-com-development/how-we-spent-two-days-making-perl-faster-939457ef16a1).

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
