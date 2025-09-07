TOPLEVEL = ATM
CM_TYPE = line+fsm+assert
RAND_SEED = 42
# Defines statement for vcs
# FWDALL
VERILOG_DEFINES := +SIM=1+TxPorts=4+RxPorts=4

# For linking the source files to the "sim" directory
SRC = ../src/
TB = ../tb/

# Default make is make vcs
.DEFAULT_GOAL := vcs

# 1.link files, move all the verilog files from the source directory over to this simulation directory
link_all:
	rm -f *.sv
	rm -f *.svh

	ln -s $(SRC)/*.sv .
	ln -s $(TB)/*.sv .
	ln -s $(TB)/*.svh .


# 2. generate .include
gen_inc: link_all
	printf "%s\n" $(notdir $(wildcard *.svh)) > $(TOPLEVEL).include
	printf "%s\n" $(notdir $(wildcard *.sv)) >> $(TOPLEVEL).include


# 3. generate the executable file and debug
# -cm_dir ... -cm_name ... to genearte database files
vcs: $(TOPLEVEL).include
	vcs -f $(TOPLEVEL).include +v2k -R \
		+lint=all -sverilog -full64 \
		-timescale=1ns/1ns \
		-debug_acc+pp+dmptf \
		-debug_region+cell+encrypt \
		-debug_access \
		-l $(TOPLEVEL).log \
		+vpdfile+./$(TOPLEVEL).vpd \
		+define+$(VERILOG_DEFINES) \
		+testname=$(TESTNAME) \
		+ntb_random_seed=$(RAND_SEED)


# 3. execute program
execute:
	./simv


# 4. visualize results
visualize:
	dve -full64 -vpd $(TOPLEVEL).vpd &


# 5. generate functional coverage reports in text format
urgtxt:
	urg -dir simv.vdb -format text -report $(REPORT_DIR)


# 6. clean generated files
clean:
	rm -rf DVEfiles
	rm -rf *.log
	rm -rf *.vpd
	rm -rf ucli.key
	rm -rf alib-52
	rm -rf $(TOPLEVEL)
	rm -rf simv.daidir
	rm -rf csrc
	rm -rf simv
	rm -rf simv.vdb
	rm -rf $(REPORT_DIR)
