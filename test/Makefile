
SHELL=/bin/bash

p=../pick

.PHONY: test runpick rundiff

test: runpick runbig runops rundiff
	@echo "--- All tests passed ---"

rundiff: $(wildcard *.ref)

   ## The column names are short, the rows do not reference meaningful entities,
   ## the operations are just to cover pick functionality.
   ## Hence below invocations are not quite self-explanatory.

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
	$(p) -o ud fx @ud/gt/0 @fx~a  < $<  > o.udfx-or.test
	$(p) fib @fib~le~5 @fib~gt~20 < $<  > o.strcmp.test
	$(p) -A1ki foo:=1 1::2 2::foo x::^x                           <  $<  > o.switch.test
	$(p) -h y::name,uc x::foo11^_,delg,uc @y/=:x                  <  $<  > o.ucdelg.test
	$(p) --cdict-123/NOTFOUND=1:one,2:two,3:three x::num4^123,map <  $<  > o.123dict.test
	$(p) -A --cdict-123/0=2,3 x:=num4^123,map @x=0                <  $<  > o.123dict2.test
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
	$(p)  -A --other=_.txt --demux-buffer=2 --demux=out @num4/=2 out:=num4^.txt  <  $<  ; cat {_,1,2,3,4}.txt > o.demux.test
	$(p) -hA --other=_.txt --demux-buffer=2 --demux=out @num4/=2 out:=num4^.txt  <  $<  ; cat {_,1,2,3,4}.txt > o.demux2.test
	$(p) -Ai --demux-buffer=2 --demux=bucket bucket:=^ms:ms^7,mul,int^5,div,int^1,min^.txt < $<  ; cat ms[01].txt > o.demux3.test
	yes | head -n 50 | $(p) -k --pstore/x:0,y:1 y::^x,pload x::y^y,pload,add > o.fibonacci.test
	bash ../utils/preserve_header sort -k $$($(p) --idx-list num4 < $<) < $< | $(p) -v --group-first-ref=num4 name num4 ::^name,pload  > o.groupfirst.test
	bash ../utils/preserve_header sort -k $$($(p) --idx-list num4 < $<) < $< | $(p) -v --group=num4 name num4 ::^name,pload  > o.group.test
	$(p) -h --table-dict-I/huh=info.txt ::name^I^info1,tmap ::name^I^info2,tmap ::fib2 < $< > o.tbdict.test
	$(p) -h --table-dict/huh=info.txt ::name^info1,map ::name^info2,map ::fib2 < $< > o.tbdict2.test
	$(p) -i '.*'::__^'(?i)(142857|[aeoiy02468])',npat < $< > o.npat.test
	$(p) -Ai --fdict-UPDATE/=update.txt fx::name^UPDATE,map:fx,uie < $< > o.update.test
	$(p) -Ai '.*'::__^1^~,test < $< > o.testallcells.test
	$(p) '.*'/_::__^'%5E%24'^--,ed cat::'.*',catall < empty.txt > o.empty.test
	seq 1 1023 1000000 | $(p) -k foo::1^7,div^7,mul^1.23456789,add^1.23456789,sub^2,pow^0.5,pow,sqrt,sq,log2^2,xch,pow,round,incr,decr^537381,mod:1^537381,idiv^537381,mul,add,neg,neg,rot13,rot13,tobin,binto,tooct,octto,tohex,hexto^foo,save^1048575,bitxor^bar,save^1048575,bitxor,rowno^1023,mul,sub^1022,add ::^foo,fetch ::^bar,fetch > o.idempotent.test
	seq 5 1 15 | $(p) -K \
                     \
     i::1             \
    lt::1^7^/lt/,test \
    le::1^7^/le/,test \
    eq::1^7^/eq/,test \
    ne::1^7^/ne/,test \
    ge::1^7^/ge/,test \
    gt::1^7^/gt/,test \
  all::1^7^/all/,test \
  any::1^7^/any/,test \
 none::1^7^/none/,test\
                     \
    LT::1^7^~lt~,test \
    LE::1^7^~le~,test \
    EQ::1^7^~eq~,test \
    IS::1^7^=,test    \
    ISNT::1^7^/=,test \
    NE::1^7^~ne~,test \
    GE::1^7^~ge~,test \
    GT::1^7^~gt~,test \
                     \
    EP::1^7^/ep/,test \
    OM::1^7^/om/,test > o.select.test
	echo {1..10} | tr ' ' '\t' | $(p) -qqq -k -i @6=5 @@6=6 x:=5 5::6 6::x ::1-10^-,joinall > o.56.test
	cat nums.txt | $(p) --pstore/f1:0,f2:1                             \
   F1::f1,incr,decr                                                  \
   add::f1:f2,add                                                    \
   mul::f1:f2,mul^f1,pload^f2,pload,mul,add                          \
   mod::f2:f1,mod                                                    \
   sub::f2:f1,sub                                                    \
   sqsq::f2,sq:f1,sq,sub:f1:f2,add,div > o.nums.test


   ## Tests on a larger table (100 rows, 20 columns) generated by makebig.pl.
   ## Reference outputs were produced independently with awk/perl, not by pick.

runbig: big.txt big.keep.txt
	$(p) -c @n1/gt/0 @grp=B                                       < big.txt > o.big-count.test
	$(p) -o id n1 f1 @n1/lt/-40 @f1/ge/0.95                       < big.txt > o.big-or.test
	$(p) -h id s::n1:n2,add^2,mul d::n4:n5,sub,abs                < big.txt > o.big-arith.test
	$(p) id sum::'%5En\d$$',addall mx::'%5En\d$$',maxall mn::'n[4-8]$$',minall < big.txt > o.big-regexall.test
	$(p) -i id 'f\d'::__^2,dd                                     < big.txt > o.big-lambda.test
	$(p) -h id q::n4:n3,div^3,dd @@n3/ne/0                        < big.txt > o.big-presel.test
	$(p) -h id ::s1,uc ::dna,rc ::dna,len ::s2^'\d+',get          < big.txt > o.big-string.test
	$(p) -x 'n\d' 'f\d' dna                                       < big.txt > o.big-excise.test
	tail -n +2 big.txt | $(p) -k 1 18- '2+1-3*4'                            > o.big-range.test
	$(p) -A --kdict-K=big.keep.txt @id~isin~K                     < big.txt > o.big-isin.test
	$(p) id s1 flag @s1~lt~m @flag/all/5                          < big.txt > o.big-strbit.test
	$(p) id f3 f4 @f3/ep/:f4/20                                   < big.txt > o.big-ep.test
	$(p) id n4 n5 @n4/om/:n5/1.5                                  < big.txt > o.big-om.test
	$(p) -h --pstore/cum:0 id cum::n1^cum,pload,add ::,rowno      < big.txt > o.big-pstore.test
	{ head -1 big.txt; tail -n +2 big.txt | sort -s -t$$'\t' -k2,2; } | $(p) --group=grp id grp prev::^id,pload gi::,groupi > o.big-group.test
	{ head -1 big.txt; tail -n +2 big.txt | sort -s -t$$'\t' -k2,2; } | $(p) --group-first-ref=grp id first::^id,pload    > o.big-groupfirst.test
	rm -f big.demux.*.txt; $(p) -A --demux-buffer=7 --other=big.demux.other.txt --demux=out @n2/ge/0 out:=^big.demux.:grp^.txt < big.txt 2> /dev/null; cat big.demux.{A,B,C,D,E,other}.txt > o.big-demux.test
	{ $(p) -qq -c -E14 @tag=keep < big.txt > /dev/null 2>&1; e1=$$?; $(p) -qq -c -E99 @tag=keep < big.txt > /dev/null 2>&1; e2=$$?; echo "$$e1 $$e2"; } > o.big-expect.test

   ## Operator tests: short successions of operators applied to big.txt columns.
   ## Reference outputs were produced independently with perl, not by pick.

runops: big.txt
	$(p) -h id ::s1,uc^3,head:s2^2,tail^-,join ::dna^1^2,strim,rev ::s2^'\d+',del,len ::s1^a,nchar ::s1^8,ppr^%7C,cat ::s1^8,ppl^%7C,cat ::s1^2,skip^1,shed < big.txt > o.ops-string.test
	$(p) -h id ::n1,abs^3,ipow ::n1:n2,max:n4,min ::n4^7,mod^2,mul,incr ::n4^3,bitlsh^4,bitrsh ::flag^5,bitoff ::flag^5,bitxor^3,bitor ::flag^6,bitand,tobin ::n6^8,idiv,decr,tooct < big.txt > o.ops-intbit.test
	$(p) -h id ::f1,sin,sq:f1,cos,sq,add^6,dd ::f2,exp,log^6,dd ::f1^3,pow^1^3,div,pow^4,dd ::f3,abs,sqrt,sq^3,dd ::f3,floor:f3,ceil,sub ::f4,neg,sign ::n5^1,add,log2^3,sn ::f1^1000,mul,floor,tohex < big.txt > o.ops-float.test
	$(p) -h id ::^'#%3A#|#':id:grp:n4,fmtall ::^'#s-#.2f':s1:f3,sprintf ::n1:n2:n3,meanall^2,dd ::n5:n6^1,add,gmeanall^1,dd ::n7^1,add:n8^1,add,hmeanall^3,dd ::n3:x,mulall ::f1:f2^1,add^4,frac ::n4:n5^1,add^1,pml ::n4^6,zp < big.txt > o.ops-devour.test
	$(p) -h --cdict-G=A:1,B:2,C:3,D:4,E:5 --cdict-V/=A:vowel,E:vowel id ::n1^0^/gt/,test:s1:s2,ifelse ::grp^G,dord^10,mul:n3,add ::grp^V,map^cons,uie ::s1^%5E[a-m]^~,test:n4:n5,ifelse k:=n4^reg,save ::^reg,fetch:k,sub:n4,add ::f1:f2^/om/,test < big.txt > o.ops-branch.test
	$(p) -h id ::s2^'(\D+)(\d+)'^'$$2_$$1',edbr ::dna^'(A+)'^'[$$1]',edgbr ::dna^A^a,edg^'[CG]',npat ::s1^'%5E.'^X,ed ::^x.y:s1,cat^x.,reqm,del ::s2^'\d',get^0,uie ::dna^'(?i)t+',delg,lc < big.txt > o.ops-regex.test
	$(p) -h id ::dna,rc,todna ::dna^1,dnagc ::n3:dna,forward ::s1:s2^%20,join,urlec,urldc ::s1,md5 ::s1,rot13,rev,uc ::dna,len^3,mod^0^/eq/,test < big.txt > o.ops-bio.test
	{ head -1 big.txt; tail -n +2 big.txt | sort -s -t$$'\t' -k2,2; } | $(p) -/'^r0[0-4]' --group=grp id ::,lineno ::,rowno ::,r0wno ::,groupno ::,groupi > o.ops-rowno.test
	printf 'x\tdna\n2.5\tATGGCCTAA\n3.5\tATGGCCTA\n-2.5\tCATGGCC\n' | $(p) -h ::dna^0,dnatl ::dna^1,dnatl ::x,round ::x^2,ipow ::x:dna,xch,pop ::x,dup,mul ::x^1^2,pop,add ::dna^5,dnatl ::x^0,ipow ::x^-1,ipow > o.ops-misc.test
	printf 'id\tcigar\tseq\tqual\tx\nq1\t5S10M2I3M1D20M4S\tACGTACGT\tIIIIHHHH\t2\nq2\t*\tTTGA\tABCD\t15\nq3\t3M1I3M\tGGCCAAT\t#######\t93\n' | $(p) -qh --quant-Q=q10.txt ::cigar^MI,cgsum ::cigar^M,cgmax ::cigar^M,cgcount ::cigar^S,cgsum ::cigar^SID,cgcount ::seq^1^3,substr ::x^Q,qnl:x^Q,qnu^%2F,join ::x^2,div,exp10^1,sn ::x,log10^4,dd ::x^0.1,mul,tan^4,dd ::id:seq,fasta ::id:seq,fastq ::id:seq:qual,fastQ > o.ops-misc2.test

big.txt: makebig.pl
	perl makebig.pl > big.txt


%.ref : %.test
	diff $< $@

rrr.txt:
	{ echo $$'one\ttwo\tthree\tfour\tfive';  for i in {1..100000}; do echo -e "$$RANDOM\t$$RANDOM\t$$RANDOM\t$$RANDOM\t$$RANDOM"; done; } > rrr.txt

time: rrr.txt
	bash time.txt 2>&1  | $(p) -k 2 1 | ./bar.pl | tee out.txt

time2: rrr.txt
	bash time2.txt 2>&1 | $(p) -k 2 1 | ./bar.pl | tee out2.txt

hf: rrr.txt
	command -v hissyfit && $(p) -h ::'.*',addall < rrr.txt | hissyfit --cv=0/163835 --x=0%16384 || echo "No hissyfit"

