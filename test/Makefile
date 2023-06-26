
SHELL=/bin/bash

p=../pick

all: runpick rundiff

rundiff: $(wildcard *.ref)

runpick: data.txt
	$(p) -f       <  $<   > o.noselection.test
	$(p) sq fib   <  $<   > o.sq-fib.test
	$(p) -A       <  $<   > o.-A.test
	$(p) -x       <  $<   > o.-x.test
	$(p) Name::'%5Ena.*'          < $<  > o.caret1.test
	$(p) Name+dna::'na.*'         < $<  > o.caret2.test
	$(p) constant::'^na.*'        < $<  > o.caret3.test
	$(p) '.*\d{2,}'               < $<  > o.twodigits.test
	$(p) ud fx @ud/gt/0 @fx~a     < $<  > o.udfx-and.test
	$(p) -h ::'^>:fx^%0A:dna'     < $<  > o.fasta.test
	$(p) -o ud fx @ud/gt/0 @fx~a  < $< > o.udfx-or.test
	$(p) -A1ki foo:=1 1::2 2::foo x::^x                           <  $<  > o.switch.test
	$(p) -h y::name,uc x::foo11^_,delg,uc @y/=:x                  <  $<  > o.ucdelg.test
	$(p) --cdict-123/NOTFOUND=1:one,2:two,3:three x::num4^123,map <  $<  > o.123dict.test
	$(p) x::ms^7,mul y::x,ceil @ud/gt/0 @x/ep/:y                  <  $<  > o.eptest1.test
	$(p) x::ms^700,mul y::x,ceil @ud/gt/0 @x/ep/:y                <  $<  > o.eptest2.test
	$(p) x::ms^700,mul y::x,ceil @ud/gt/0 @x/ep/:y/0.01           <  $<  > o.eptest3.test
	$(p) -i ref:=sq fib:fib2:sq::__:ref^1,pct ref                 <  $<  > o.pct.test
	$(p) -i fib:fib2:sq/_pct::__:sq^1,pct fib fib2 sq             <  $<  > o.pct2.test
	$(p) -i fib:fib2:sq//_pct::__:sq^1,pct                        <  $<  > o.pct3.test
	$(p) -Pi fib:fib2:sq//_pct::__:fib2^1,pct                     <  $<  > o.pct4.test
	$(p) -x 'num\d+' foo_/'num\d+'/::__                           <  $<  > o.rename.test
	$(p) --fdict-star/---=dict.txt Starname::name^D,del^star,map  <  $<  > o.dictstarname.test
	export PICK_DIV_INF='😳'; $(p) -Pi fib:fib2:sq//_pct::__:fib2^1,pct  <  $<  > o.pct5.test
	$(p) -i numsum1::'num\d+',addall foo_/'num\d+'/_bar::__,sq numsum2::'num\d+',addall 'num\d+'  <  $<  > o.numsum.test
	$(p) x::name^'%5EG.*',get^-,uie                               <  $<  > o.re-caret.test
	$(p) x::name^'%5E[%5EG].*',get^-,uie                          <  $<  > o.re-caret2.test


%.ref : %.test
	diff $< $@

rrr.txt:
	{ echo one;   for i in {1..100000}; do echo $$RANDOM; done; } > r1
	{ echo two;   for i in {1..100000}; do echo $$RANDOM; done; } > r2
	{ echo three; for i in {1..100000}; do echo $$RANDOM; done; } > r3
	{ echo four;  for i in {1..100000}; do echo $$RANDOM; done; } > r4
	{ echo five;  for i in {1..100000}; do echo $$RANDOM; done; } > r5
	paste r[1-5] > rrr.txt

time: rrr.txt
	bash time.txt 2>&1  | $(p) -k 2 1 | ./bar.pl | tee out.txt

time2: rrr.txt
	bash time2.txt 2>&1 | $(p) -k 2 1 | ./bar.pl | tee out2.txt

hissyfit: rrr.txt
	command -v hissyfit && $(p) -h ::'.*',addall < rrr.txt | hissyfit || echo "No hissyfit"

