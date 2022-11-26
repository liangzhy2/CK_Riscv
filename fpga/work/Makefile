clean:
	rm -rf *.cache *.hw *.sim *.ip_user_files *.runs *.srcs  .Xil *.cache
	rm -f *.jou *.log *.txt *.xpr  *list vivado*
built:
	perl ./../script/gen_file.pl
	vivado -mode batch -source ../script/create_prj.tcl  

open:
	vivado -source open_project ./*.xpr &
