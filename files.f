# common sources
common/wishbone_interface.sv

# rtl sources
rtl/bifrost_wb_dma.sv

# verif packages
fv/params/tb_params.sv
fv/params/tb_pkg.sv

# verif components
fv/interfaces/tb_intf.sv
fv/objects/trnxt.sv
fv/components/driver.sv
fv/components/mntr.sv
fv/components/gnrtr.sv
fv/components/agnt.sv
fv/components/scrbd.sv
fv/components/envr.sv
fv/coverage/cvrg.sv
fv/tests/test_base.sv
fv/tests/test_reg_acc.sv
fv/tests/test_inv_acc.sv

# simulation top
fv/tb_top.sv
