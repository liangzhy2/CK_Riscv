

#comp :
#	./gen_file.pl
#	spyglass -project spyglass.prj -designread -batch
	#spyglass -project spyglass.prj -designread -goals lint/lint_rtl -batch


run_lint:
	./scripts/gen_file.pl
	spyglass -project scripts/spy_lint.prj -designread -goals lint/lint_rtl -batch

open:
	spyglass -project scripts/spy_lint.prj &

showgoals:
	spyglass -project scripts/spy_lint.prj -showgoals

clean :
	rm -rf *.log spy_lint WORK
	rm -rf module_file_list modules_list
