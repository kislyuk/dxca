P=wgs-8.3rc1-Linux_amd64.tar.bz2
SRC_URI=http://sourceforge.net/projects/wgs-assembler/files/wgs-assembler/wgs-8.3/$(P)

resources/usr/bin/runCA:
	curl -O -L $(SRC_URI)
	tar -C resources/usr --strip 2 -xjf $(P)
