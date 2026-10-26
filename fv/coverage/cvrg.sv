import tb_params::*;

covergroup cg_dma(virtual tb_intf intf, virtual wishbone_interface wb_cfg) @(posedge intf.clk);
  option.per_instance = 1;
  option.goal = 90;

  reset_cp: coverpoint intf.rst {
    bins reset_asserted = {1'b1};
    bins reset_deasserted = {1'b0};
  }

  intr_cp: coverpoint intf.intr {
    bins irq_asserted = {1'b1};
    bins irq_idle     = {1'b0};
  }

  reg_write_cp: coverpoint wb_cfg.we iff (wb_cfg.cyc && wb_cfg.stb) {
    bins write = {1'b1};
    bins read  = {1'b0};
  }

  channel_cp: coverpoint wb_cfg.adr[5:3] iff (wb_cfg.cyc && wb_cfg.stb && wb_cfg.adr >= START_ADDRESS && wb_cfg.adr < (START_ADDRESS + SIZE)) {
    bins ch0 = {3'd0};
    bins ch1 = {3'd1};
    bins ch2 = {3'd2};
    bins ch3 = {3'd3};
    bins ch4 = {3'd4};
    bins ch5 = {3'd5};
    bins ch6 = {3'd6};
    bins ch7 = {3'd7};
  }

  priority_cp: coverpoint wb_cfg.dat_mosi[2:0] iff (wb_cfg.cyc && wb_cfg.stb && wb_cfg.we && wb_cfg.adr >= START_ADDRESS && wb_cfg.adr < (START_ADDRESS + SIZE) && ((wb_cfg.adr - START_ADDRESS) % 8 == REG_PRIORITY)) {
    bins prio_0 = {3'd0};
    bins prio_1 = {3'd1};
    bins prio_2 = {3'd2};
    bins prio_3 = {3'd3};
    bins prio_4 = {3'd4};
    bins prio_5 = {3'd5};
    bins prio_6 = {3'd6};
    bins prio_7 = {3'd7};
  }

  length_cp: coverpoint wb_cfg.dat_mosi iff (wb_cfg.cyc && wb_cfg.stb && wb_cfg.we && wb_cfg.adr >= START_ADDRESS && wb_cfg.adr < (START_ADDRESS + SIZE) && ((wb_cfg.adr - START_ADDRESS) % 8 == REG_LEN)) {
    bins len_0  = {32'd0};
    bins len_1  = {32'd1};
    bins len_2  = {32'd2};
    bins len_4  = {32'd4};
    bins len_8  = {32'd8};
    bins len_16 = {32'd16};
  }

  ctrl_cp: coverpoint wb_cfg.dat_mosi[3:0] iff (wb_cfg.cyc && wb_cfg.stb && wb_cfg.we && wb_cfg.adr >= START_ADDRESS && wb_cfg.adr < (START_ADDRESS + SIZE) && ((wb_cfg.adr - START_ADDRESS) % 8 == REG_CTRL)) {
    bins ctrl_idle = {4'd0};
    bins ctrl_run  = {4'd1};
    bins ctrl_irq  = {4'd9};
  }

endgroup : cg_dma

class cvrg;

  virtual tb_intf intf;
  virtual wishbone_interface wb_cfg;
  cg_dma cg;

  function new(virtual tb_intf intf, virtual wishbone_interface wb_cfg);
    this.intf = intf;
    this.wb_cfg = wb_cfg;
    cg = new(intf, wb_cfg);
  endfunction

endclass : cvrg
