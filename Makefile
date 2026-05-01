diagram: diagram.asm
	xa -c -C  diagram.asm  -o diagram
	
diagvec: diagvec.asm
	xa -c -C  diagvec.asm  -o diagvec

asterock: asterock1k.asm
	xa -c -C  asterock1k.asm  -o asterock

eprom-dram: diagram
	rm -f eprom-dram
	cat diagram rand_rst >> eprom-dram
