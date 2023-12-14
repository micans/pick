

# Robust handling of tables and scientific data using the Unix command line

The first part of this is a high-level overview of and thoughts about the subject.
The second part is a listing of useful programs and techniques, currently under construction.

## The space in between scientific programming and workflow orchestration

   Over the past twenty years I have worked in data processing
   environments with large data sets and fast evolving requirements.
   An order of magnitude reduction of keystrokes benefits both development and prototyping
   as well as maintenance of stable systems.
   As ever, the right abstraction layer or DSL (domain specific language) allows this.
   The UNIX shell itself is such an abstraction layer that is often overlooked or
   feared, and the subject of this section.

   R and Python interfaces such as Jupyter and Rstudio are well known.
   They offer a full programming environment, rich sets of packages (statistics, machine learning and other),
   as well as immediate visualisation, again supported by powerful libraries.
   Complementary to this Nextflow and other workflow orchestrators (e.g. Snakemake) offer a framework to
   express pipelines connecting many different programs and their outputs. Such a
   framework provides aspects such as workflow definition, file (dependency)
   management, caching, parallelisation, farm/cloud orchestration and many more.

   Within a single Nextflow process, or whilst developing and exploring, it can still be highly
   useful to deal with table files on the command line.
   This is **the space in between scientific programming and workflow orchestration**.
   In bioinformatics, chains or successions of command
   lines invoking programs such as `grep`, `cut`, `sort` and `awk`  have long been a staple of the trade,
   but suffer from fragility in that they are not able to utilise column names or row names
   and are mostly not table-entry aware.
   The programs and shell functionality below are a much larger set of tools that allow
   more robust handling of tabular data on the command line.

   In this approach the file system is thought of as an object store of tables and
   data frames where various (but certainly not all) transformations and
   derivations among raw data and processed data can be achieved using relatively short command lines
   comprised of chains of standard or custom but often-used tools.
   This data-centric way of working can bring
   **clarity and improvements in the data structures and outputs committed to the file system**.
   The ability to monitor, inspect and debug a workflow,
   alongside the definitions of quality control measures and summary statistics
   naturally arise as part of the development process.
   The data-centric approach induces **rich, parsimonious and orthogonal outputs**.

   Where possible this approach goes beyond standard UNIX piped commands by using
   **tools and methods that use column names and row names as handles to specify desired transformation**.
   An additional benefit is often that **data can be streamed** rather than
   loaded in its entirety into memory, thus scaling to very large data sets.
   Even where this benefit does not apply, such as in the often-needed case of
   sorting large data, unix `sort` is a highly optimised tool, sorting data that does
   not fit into memory by splitting and merging data in temporary files.
   Importantly, unix `sort` does this behind the scenes and its user does not need to
   know whether the data fits into memory or not.

   Both disk-based transformations and repeated parsing of streamed data
   are very slow compared to in-memory transformations. The flip side of this is that
   in-memory transformations put limits on the data size that can be handled and lead to more opaque
   and less flexible workflows, inducing monolithic programs with intricate
   logic. **Streamed data is more condordant with a functional programming mindset**
   ([what functional programming and Unix philosophy can teach us about data streaming](https://mikulskibartosz.name/functional-programming-principles-vs-data-streaming)).
   Furthermore, the streaming aspect can be independently optimised.
   One example is the piping of commands, avoiding disk access between successive
   transformations. A second example, applicable in narrow cases, is that of binary formats that obviate
   the need for parsing. Such formats encode arrays that can be mapped directly into memory
   and can speed up streaming by orders of magnitude. [note mcl; arrow?]


## Useful command-line tools

   This is a work in progress. In particular, incorporation of the right selection
   of profitable shell (bash) features and syntax requires some thought and iteration.
   I've not yet taken great care to distinguish between different shell versions.
   The aim is that all shell features listed here are available in reasonably modern versions of
   both `bash` and `zsh`.  
   *Todo:* be more specific (e.g. Bash version before hash arrays were introduced).  
   *Todo:* incorporate more techniques to make examples bullet-proof against weird file names.

   I'm sure this list is far from complete.  I've strived to include only standard
   widely available softare, but I have added three tools I wrote that I use a lot.  The first,
   `transpose`, is a very fast memory-efficient tool to transpose tables.
   An alternative is offered by `datamash transpose`, but my version was quite a bit
   faster and more memory efficient when last tested - [*Todo:* measurements below]. The second,
   `hissyfit` is a single script to draw histograms in the terminal using Unicode
   bar characters to achieve acceptable resolution.
   Similar small-project solutions exist, I like `hissyfit`'s single-script
   simplicity and its list of features (e.g. custom annotation, axes ticks, super-bin counts).
   The last one is `pick`; in most cases `mlr` (miller) is a more capable
   alternative, although `pick` does offer some unique features and benefits in specific cases.

> [!NOTE]
> Tab-separated tables are the one true tabular data storage format. Comma-separated values are an abomination
> requiring quoting mechanisms for embedded commas. Contrasting this, there is no case for embedded tabs. Someone
> whose opinion I regard highly mentioned using embedded tabs in comma-separated data to induce line breaks in figure legends.
> This is highly perverse. As such I respect it but cannot condone it.


- [`miller`](https://miller.readthedocs.io/en/)  
  _Miller is a command-line tool for querying, shaping, and reformatting data files in various formats including CSV, TSV, JSON, and JSON Lines._
  It's probably easiest to visit the miller page to get an impression of all it can do. Below I will
  add `mlr` recipes where applicable (an ongoing process).


- [datamash](https://www.gnu.org/software/datamash/  
  _GNU datamash is a command-line program which performs basic numeric, textual and statistical operations on input textual data files._
  My main use for this is to compute data statistics, optionally grouped over a categorical second variable. `mlr` can do
  many of these things as well.

- [bioawk](https://github.com/lh3/bioawk)  
  _Bioawk is an extension to Brian Kernighan's awk, adding the support of several common biological data formats, including optionally gzip'ed BED, GFF, SAM, VCF, FASTA/Q and TAB-delimited formats with column names._
  Written by Heng Li, this is an extremely useful tool.


- `preserve_header` is a simple shell script that allows manipulation of tabular data
with standard unix command while preserving column names. In many cases the desired effect can also be achieved
by using `mlr`, but it is useful to be aware of this wafer-thin alternative.
```
#!/bin/bash
# See https://unix.stackexchange.com/questions/11856/sort-but-keep-header-line-at-the-top
IFS= read -r header
printf '%s\n' "$header"
"$@"
```
Example usages:
```
   preserve_header sort -nk 2 < data.txt

   preserve_header shuf -n 10 < data.txt
```
The above approach can be a useful option e.g. for very large inputs. Equally there can be some peace of mind
in consistently using widely-used, battle-tested and feature-rich Unix programs. As such `preserve_header` offers
a bit of a half-way house, because generally those programs use positional indexes as in the examples above.
Of note is that these examples can be achieved with `mlr --tsv sort` and `mlr --tsv sample`.
It is equally possible to ask `pick` for the right column indexes for a selection of columns, e.g.

```
 ▷  pick --idx-list fib fib2 num4 < data.txt
2	3	10
```
Thus if you want to sort on column `num4` the following works without using positional indexes.
```
   preserve_header sort -nk $(pick --idx-list num4 < data.txt) < data.txt
```
In interactive command lines this looks a bit unwieldy, but it can be a useful technique in scripts.


- `transpose` - flip a table so rows become columns and vice versa.
   [My own version](https://github.com/micans/reaper) is battle-tested and highly memory efficient, with useful features
   such as the ability to read gzip-compressed files directly.  Out of the datamash box it is available as `datamash transpose`.

- `join` - join two files on a common field.  
   Caveat; the columns to be compared need to be in `sort(1)` order just using the option `-b` (ignore leading
   blank character).  In small tests I carried out both regular sort and version sort seemed to work, but even just
   testing this is probably an extremely daft thing to do. [*Todo:* a short description of what happens when `join` is
   not happy about the sort order.]

- `sort` - versatile workhorse.  
   Use `sort -V` for "version sort".  
   *Todo:* syntax for multi-column sort

-  Count occurrences of items. Classically people used `uniq -c` for this but
```
datamash -H -g foo count foo      # if a header is present tally grouped items in column foo

datamash -g 1 count 1             # in the absence of a header tally grouped items in column 1.
```
   are much better and more powerful alternatives. This approach is more useful as it is possible to
   compute multiple statistics at the same time. For example, below counts items in column `num`,
   computes the mean across groups in column `fib`, and the sum across groups in column `fib2`.
   **As with the input for uniq, the input must be sorted on the column of interest.**
```
datamash -H -g num4 count num4 mean fib sum fib2
```
   `uniq -c` is one of the most irritating commands I know, as the first (count) field
   is right-justified without any option available to avoid this white-space padding. It is quite puzzling
   that Richard Stallman let this program loose on the world as it violates usual Unix well-behavedness
   of textual interfaces. Another option is to use a function such as this (Unix diehards may prefer an awk version):
```
unic ()
{
    uniq -c | perl -pe 's/^\s*(\d+)\s+/$1\t/'
}
```
   There are remnants of the `leading blank` issue in other Unix commands, for
   example `join` by default ignores leading blanks and requires input sorted with
   the sort `-b` option. Was it too tempting for
   the early Unix pioneers to pass up some default right justification, rather
   than separating presentation from computation?  Generations of programmers
   and bugs have suffered as a result.

   *Todo:* Miller equivalents.

- `hissyfit`  
   Visualisation is the hardest to come by on the command line. **Histograms are a useful workhorse**
   and for that purpose I use `hissyfit`. It allows quite reasonable quantitation using Unicode
   bar characters, providing eight levels per output line. As a very poor alternative alternative to scatterplots
   I occassionally resort to a histogram of ratios (poor alternative I must stress).

- `nl` - number lines. Use `nl -w 1 [-v 0] [-i 1]` (`-w 1` to avoid pretty printing with spaces, `-v 0` zero-based, `-i` increment).

- GNU `parallel`; parallel execution on a single multi-CPU machine. Caveat the right version of parallel. Insanely powerful.

- `comm` Not so often used. Requires sorted files and outputs part common to two input files.

- `echo -e`, `echo -n`, `echo -en`

- `seq <START> <INCREMENT> <END>` to generate a range of numbers

- `printf` (avoid shell quoting issues)

- `column -t -s$'\t'`

- `wc -l` (use with redirection to avoid file name; with `pick` use `pick -c` to count rows matching some requirements)

- `tr '\t' '\n'`

- `paste` `paste - -`

- `shuf -n`

- `split -l` (`csplit` for context split)

- `tee`

- `head`, `tail`, `tac`, `rev`, `gzip`

- `mkdir -p`, `env pwd -P`, `basename` `dirname` `realpath`

- `nproc`

- `env`

- `grep` - generally I use `pick`, e.g. `pick @foo=bar` (exact match) or `pick @foo~bar` (regular expression match)
   and the negated versions `pick @foo/=bar` (exclude exact match) and `pick @foo/~bar` (exclude regular expression match).
  `grep` is faster, but `pick` offers precise control. Still, there are many cases where `grep` is exceedingly useful.
  Some options I use a lot:

  `-i`   for case insensitive matching
  
  `-v`   output lines that do not match.

  `-F`   treat pattern as fixed - no meta patterns. This increases processing speed.

  `-w`   require matches to align on word boundaries.

  `-f fname`   search for any of the patterns listed in file `fname` (one on each line).

  `--color=auto`  output with matching parts highlighted in colour

  `-o`   only output matching parts (each part output on a separate line)

  `-m <num>`   output no more than `<num>` matches

  `q`    no output, exit states indicates match or match found. A use case is e.g. in an if statement.

- `bc -l <<< 'scale=4; 1/2'` (`s` for sine `c` for cosine `a` for atan `l` for log `e` for exp)

- `tsort` topological sort

- `jq` Command-line JSON processor

- `sqlite3` Lightweight no-server embedded SQL database engine

- various bash constructs

```
echo $((1+3**2+8/4))                         # simple integer arithmetic

echo $(( $(echo -e "a\nb" | wc -l) + 2))     # as above, with nested command substitution

echo -e "somefile.txt\t$(( $(wc -l < somefile.txt)/4 ))"    # as above, within quotes
```
   Arithmetic expansion `$(( .. ))` and command substitution `$( .. )` are useful tools
   to combine different outputs and results in a succinct manner.
   **Caveat:** division discards the remainder - use e.g. `bc` for a proper calculator.
   A useful feature is that these constructs can be nested and can be used within quotes,
   although beware that nested quoted constructs are best avoided if possible in order to avoid
   *shell quote hell*.

```
   <<<
   var=
   ${var%.txt}
   ${var#out.}
   <(some-command > myfile)
   >(some-command > myfile)
   for
   while
   set -euo pipefail (and caveats about)
```
   Caveats: variables in subshells are not accessible


-  `miller` *Todo:* add various verbs


## Notes

-  This is based on / learned from bioinformatic workflows. I wonder what we can learn from physics
   and other disciplines/ecosystems.

-  `awk` is cell table-entry aware, but otherwise not a DSL - it essentially requires writing scripts.
   `Bioawk` is a highly useful adaptation.

-   [Data flow - what functional programming and Unix philosophy can teach us about data streaming](https://mikulskibartosz.name/functional-programming-principles-vs-data-streaming)  
   _Functional programming is about focusing on what is relevant to the problem and expressing it as a series of data transformations. Jessica Kerr describes pure functions as “data-in data-out” functions. Those things are conceptually the same._


