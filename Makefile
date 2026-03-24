diagram: diagram.asm
	xa -c -C  diagram.asm  -o diagram
	
diagvec: diagvec.asm
	xa -c -C  diagvec.asm  -o diagvec

eprom-dram: diagram
	rm -f eprom-dram
	cat diagram rand_rst >> eprom-dram

eprom-dvec: diagvec
	rm -f eprom-dvec
	cat diagvec >> eprom-dvec
