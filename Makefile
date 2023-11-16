
# Pick's improvised versioning.

.PHONY: vger v

vger:
	./versify

v:
	diff riskybusiness.txt pick || true
	cp -i riskybusiness.txt pick

