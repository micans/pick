
p=../pick

all: runpick rundiff

rundiff: $(wildcard *.ref)

runpick: data.txt
	$(p) -f     <  $<   > o.noselection.test
	$(p) sq fib <  $<   > o.sq-fib.test
	$(p) -A     <  $<   > o.-A.test
	$(p) -x     <  $<   > o.-x.test
	$(p) Name::'%5Ena.*'        < $<  > o.caret1.test
	$(p) Name+dna::'na.*'       < $<  > o.caret2.test
	$(p) constant::'^na.*'      < $<  > o.caret3.test
	$(p) '.*\d{2,}'             < $<  > o.twodigits.test
	$(p) ud fx @ud/gt/0 @fx~a   < $<  > o.udfx-and.test
	$(p) -h ::'^>:fx^%0A:dna'   < $<  > o.fasta.test
	$(p) -o ud fx @ud/gt/0 @fx~a < $< > o.udfx-or.test
	$(p) -h y::name,uc x::foo11^_,delg,uc @y/=:x                  <  $<  > o.ucdelg.test
	$(p) --cdict-123/NOTFOUND=1:one,2:two,3:three x::num4^123,map <  $<  > o.123dict.test
	$(p) x::ms^7,mul y::x,ceil @ud/gt/0 @x/ep/:y                  <  $<  > o.eptest1.test
	$(p) x::ms^700,mul y::x,ceil @ud/gt/0 @x/ep/:y                <  $<  > o.eptest2.test
	$(p) x::ms^700,mul y::x,ceil @ud/gt/0 @x/ep/:y/0.01           <  $<  > o.eptest3.test
	$(p) -i ref:=sq fib:fib2:sq::__:ref^1,pct ref                 <  $<  > o.pct.test
	$(p) -x 'num\d+' foo_/'num\d+'/::__                           <  $<  > o.rename.test
	$(p) -i numsum1::'num\d+',addall foo_/'num\d+'/_bar::__,sq numsum2::'num\d+',addall 'num\d+'  <  $<  > o.numsum.test


%.ref : %.test
	diff $< $@

