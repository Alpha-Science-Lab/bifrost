
.PHONY: all compile run sim \
	fv_compile fv_elaborate fv_run fv_gui clean

# Verilator directed test flow
VERILATOR   = verilator
TOP_MODULE  = sim_top
BUILD_DIR   = build
OBJ_DIR     = $(BUILD_DIR)/obj_dir
TARGET      = $(BUILD_DIR)/V$(TOP_MODULE)
SOURCES     = common/wishbone_interface.sv \
			  rtl/bifrost_wb_dma.sv \
			  sim/sim_top.sv

VERILATOR_FLAGS = --binary --top-module $(TOP_MODULE) \
			--Mdir $(OBJ_DIR) -O2 -Wall --trace -Wno-fatal \
			-o ../$(notdir $(TARGET))

# Vivado FV flow
XVLOG       = xvlog
XELAB       = xelab
XSIM        = xsim
XCRG        = xcrg
FV_FILELIST = files.f
FV_TOP      ?= tb_top
TESTNAME    ?=

ifneq ($(strip $(TESTNAME)),)
XSIM_PLUSARGS = --testplusarg TESTNAME=$(TESTNAME)
endif

FV_SNAPSHOT       = $(FV_TOP)
COV               ?= 0
COV_DB_DIR        ?= .
COV_DB_NAME       ?= $(FV_SNAPSHOT)
COV_REPORT_DIR    ?= coverage_report
COV_REPORT_FORMAT ?= all
CC_TYPE           ?= sbct

ifeq ($(COV),1)
ELAB_COV_FLAGS = --cov_db_dir $(COV_DB_DIR) --cov_db_name $(COV_DB_NAME) --cc_type $(CC_TYPE)
XSIM_COV_FLAGS = --cov_db_dir $(COV_DB_DIR) --cov_db_name $(COV_DB_NAME)
endif

all: run

compile: $(TARGET)

$(TARGET): $(SOURCES)
	@mkdir -p $(BUILD_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) $(SOURCES)

run: $(TARGET)
	./$(TARGET)

sim: run

fv_compile:
	$(XVLOG) -sv -f $(FV_FILELIST)

fv_elaborate: fv_compile
	$(XELAB) $(FV_TOP) -s $(FV_SNAPSHOT) $(ELAB_COV_FLAGS)

fv_run: fv_elaborate
	$(XSIM) $(FV_SNAPSHOT) -runall $(XSIM_COV_FLAGS) $(XSIM_PLUSARGS)
ifeq ($(COV),1)
	$(XCRG) -cov_db_dir $(COV_DB_DIR) -cov_db_name $(COV_DB_NAME) \
	 -report_dir $(COV_REPORT_DIR) -report_format $(COV_REPORT_FORMAT)
endif

fv_gui: fv_elaborate
	$(XSIM) $(FV_SNAPSHOT) -gui $(XSIM_COV_FLAGS) $(XSIM_PLUSARGS)

clean:
	rm -rf $(BUILD_DIR) xsim.dir xsim.codeCov xsim.covdb .Xil \
	 *.log *.pb *.jou *.wdb *.vcd
