f8-diag: f8-diag.asm
	xa -c -C  f8-diag.asm  -o f8-diag
	
eprom: f8-diag
	rm -f eprom
	cat f8-diag rand_rst >> eprom
