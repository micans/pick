
# Unix table column/row manipulation using column names


`pick` is an expressive low-memory **command-line** tool for manipulating text file tables.
Entire scripts can be replaced by concise command line invocations.

Each line/row is treated as a list of variables identified by column names.  You can
- perform computations to make new variables
- filter rows based on boolean clauses operating on variables
- for output columns take any subset from existing and newly computed variables

Some examples:

```
pick -c < data.txt                  # Count rows and validate table file.

pick foo bar                        # Pick columns named foo and bar (header included)

pick -A @tim/gt/0                   # Pick all columns, subset to rows where tim > 0

pick -A qat::foo:bar,add            # Add new column qat, sum of columns foo and bar

pick -A @tim/gt/0 qat::foo:bar,addd # Pick all columns, subset rows, add new column qat

pick -h ::end:start,sub^1,add       # Compute new column with inclusive interval length, omit header

pick -k ::3:4,sub^1,add             # As above, in the absence of column headers

pick digits::foo^'(\d+)',get        # Extract digits from column foo, store in new column 'digits'

pick -A @foo/gt/1 foo:=bar,abs      # Select on foo = abs(bar) without outputting foo

pick --kdict-KEEP=dict.txt @tim~isin~KEEP  # subset rows using a dictionary
```

Pick is a standalone script that depends only on a standard perl installation - it should work on any standard Linux (or Unix) OS
and all Mac OS releases with developer tools installed.

```
wget https://raw.githubusercontent.com/micans/pick/main/pick
```

`pick` is **robust** and **intuitive** by supporting column names as handles.
It is **lightweight** as it processes data per-line without the need to load the table into memory.
It is **expressive** in that short command lines are sufficient to get at the data.

Pick works very well as a pre-filter to [datamash](https://www.gnu.org/software/datamash/) -
a tool that can compute statistics over columns, optionally grouped over a second (column) variable,
and tools such as [csvtk](https://github.com/shenwei356/csvtk), which can (among many more things)
sort tables using column names.

Additionally `pick` has **extensive support for SAM format** such as printing alignments and
outputting alignment-derived quantities like coverage and base mismatch information.
A reference FASTA file can be specified, which is then used by pick to automatically slot in reference
sequences where needed. Alignments can be queried and printed limited to an interval of interest (by reference coordinates).

In comparison to the tools below pick is more limited in scope in some/many ways, instead
complemented by tools such as datamash and sort. It is probably a lot slower than most tools mentioned below.
Distinct advantages are its powerful and concise compute and filter primitives.


> [!NOTE]
>
> For your benefit, [miller (unix command `mlr`)](https://miller.readthedocs.io/en/)
> is an amazing widely-used command-line tool for handling tables (using column names also).
> It is available in most Linux distributions as a supported package. Also on my watch-list are
> [csvtk](https://github.com/shenwei356/csvtk),
> [sq](https://github.com/neilotoole/sq),
> [qsv](https://github.com/dathere/qsv),
> [tsv-utils](https://github.com/eBay/tsv-utils) - all browsed from
> [this overview](https://github.com/toolleeo/awesome-cli-apps-in-a-csv?tab=readme-ov-file#data-management---tabular-data).
>
> I'm also looking at [polars](https://github.com/pola-rs/polars). Its ability to process streams,
> syntax, speed, efficiency and Rust implementation all look great, as is its elevation of the dataframe
> as a pivotal computable unit. I need to investigate whether pick command lines can be expressed as polars code.


In simple to middling cases pick can avoid both the need for a script (R, awk, Python, Ruby et cetera) and
having to load the entire data set into memory.
I use it in conjunction with UNIX tools such as `comm`, `join`, `sort` and `datamash` to simplify file-based computational workflows
and make them more robust and understandable by promoting the use of column names as handles
(as opposed to column indexes as used with `cut` and `awk`). You can **use column names or column indexes to**

- Select columns
- Change columns (using computation and string operations)
- Combine columns into new columns (using computation and string operations)
- Filter or fork rows on boolean clauses computed on old and new columns
- Split/demultiplex rows to different output files based on (computed) labels in columns
- Select multiple columns using ranges or regular expressions
- Take the same action on multiple columns using a lambda expression
- Import dictionaries to test membership or to map values


There is no downside, except, as ever, it comes with its own syntax for
computation. For plain column selection and row filtering this syntax is not needed though;
**pick command lines look pleasant enough for common use cases.**

Computation syntax is minimalist and terse, employing a stack language with just three types (variables, constants and operators).
Accordingly, there is almost nothing to learn.
In order to work efficiently as a command line tool, the `pick` computation language **does away with whitespace entirely** and
uses punctuation to distinguish the three types.

Full documentation is in the [Pick User Manual](doc/PICK-USER-MANUAL.md)


