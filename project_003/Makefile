########################################################
# === Ayarlar ===
########################################################

PKG_DIR     = pkg
RTL_DIR     = rtl
TB_DIR      = tb
WORK_DIR    = work
WAVEFORM    = wave.vcd
SYNTH_JSON  = synth.json

########################################################
# === Araclar ===
########################################################

VLIB        = vlib
VLOG        = vlog
VSIM        = vsim
YOSYS       = yosys
GTKWAVE     = gtkwave
VERIBLE_LINT= verible-verilog-lint

########################################################
# === Dosyalar ===
########################################################

PKG_FILES   := $(wildcard $(PKG_DIR)/*.sv)
RTL_FILES   := $(wildcard $(RTL_DIR)/*.sv)
TB_FILES    := $(wildcard $(TB_DIR)/*.sv)
ALL_FILES := $(PKG_FILES) $(RTL_FILES) $(TB_FILES)
TB ?= $(notdir $(firstword $(TB_FILES)))
TB_FILE := $(TB_DIR)/$(TB)
TB_TOP  := $(basename $(TB))



########################################################
# === Hedefler ===
########################################################

.PHONY: all compile sim sim_batch clean show view lint check-top setup

all: sim

########################################################
# COMPILE
# SIRALAMA:
#   1) PACKAGE
#   2) RTL
#   3) TESTBENCH
########################################################

compile:
	@echo "[] Creating work library"
	@mkdir -p $(WORK_DIR)
	$(VLIB) $(WORK_DIR)

	@if [ -n "$(PKG_FILES)" ]; then \
		echo "[] Compiling PACKAGES"; \
		$(VLOG) -work $(WORK_DIR) $(PKG_FILES); \
	else \
		echo "[i] No package files"; \
	fi

	@if [ -n "$(RTL_FILES)" ]; then \
		echo "[] Compiling RTL"; \
		$(VLOG) -work $(WORK_DIR) $(RTL_FILES); \
	else \
		echo "[i] No RTL files"; \
	fi

	@if [ -f "$(TB_FILE)" ]; then \
		echo "[] Compiling TB ($(TB))"; \
		$(VLOG) -work $(WORK_DIR) $(TB_FILE); \
	else \
		echo "[i] No TB file"; \
	fi

########################################################
# GUI SIM
########################################################

sim: compile
	@echo "[] Launching ModelSim GUI"
	$(VSIM) -work $(WORK_DIR) $(TB_TOP)

########################################################
# BATCH SIM + VCD
########################################################

sim_batch: compile
	@echo "[] Running ModelSim batch"
	$(VSIM) -c -work $(WORK_DIR) $(TB_TOP) -do "\
	vcd file $(WAVEFORM); \
	vcd add -r /*; \
	run -all; \
	quit"

########################################################
# CLEAN
########################################################

clean:
	rm -rf $(WORK_DIR) transcript vsim.wlf $(WAVEFORM)
	@echo "[✓] Clean done"
