# Examples of selecting and changing multiple columns simultaneously

### Select all columns for output (normally achieved with -A)
```
> echo -e "a\tb\tc\n3\t4\t5" | pick '.*'

a       b       c
3       4       5
```


### Select all columns, apply the same computation (cannot be empty however)
```
> echo -e "a\tb\tc\n3\t4\t5" | pick '.*'::

Compute cannot be empty
```


### The -i in-place options is required to allow potential overwriting of existing columns
```
> echo -e "a\tb\tc\n3\t4\t5" | pick '.*'::^foo

Name a already defined (use -i for in-place change)
```


### Computation consisting of the constant value 'foo'
```
> echo -e "a\tb\tc\n3\t4\t5" | pick -i '.*'::^foo

a       b       c
foo     foo     foo
```


### Computation consisting of the column itself
```
> echo -e "a\tb\tc\n3\t4\t5" | pick -i '.*'::__

a       b       c
3       4       5
```


### Computation consisting of the column duplicated
```
> echo -e "a\tb\tc\n3\t4\t5" | pick -i '.*'::__:__

a       b       c
33      44      55
```


### Computation consisting of the column squared
```
> echo -e "a\tb\tc\n3\t4\t5" | pick -i '.*'::__,sq

a       b       c
9       16      25
```


### Create a new column name by adding 'x'; now -i is not needed, -A shows the original columns
```
> echo -e "a\tb\tc\n3\t4\t5" | pick -A '.*'/x::__,sq

a       b       c       ax      bx      cx
3       4       5       9       16      25
```


### Using the double slash has the same effect, but columns are grouped pairwise
```
> echo -e "a\tb\tc\n3\t4\t5" | pick  '.*'//x::__,sq

a       ax      b       bx      c       cx
3       9       4       16      5       25
```


### This can be useful when expressing as a percentage, here relative to column c
```
> echo -e "a\tb\tc\n3\t4\t5" | pick  '.*'//_pct::__:c^1,pct

a       a_pct   b       b_pct   c       c_pct
3       60.0    4       80.0    5       100.0
```


### Multiple computations are possible
```
> echo -e "a\tb\tc\n3\t4\t5" | pick -A '.*'/x::__,sq '.*'/y::__,sq,sq

a       b       c       ax      bx      cx      ay      by      cy
3       4       5       9       16      25      81      256     625
```


### A (not very useful) curiosity - the first column is a = (a=3)+(b=4)+(c=5)=12, then the second is b = (a=12)+(b=4)+(c=5)=21, the third is c = (a=12)+(b=21)+(c=5)
```
> echo -e "a\tb\tc\n3\t4\t5" | pick -i '.*'::'.*',addall

a       b       c
12      21      38
```


### (continued) this behaviour disappears if the values are stored in a new name
```
> echo -e "a\tb\tc\n3\t4\t5" | pick -Ai '.*'/x::'.*',addall

a       b       c       ax      bx      cx
3       4       5       12      12      12
```


