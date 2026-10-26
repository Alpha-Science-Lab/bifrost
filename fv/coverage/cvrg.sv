import tb_params::*;

covergroup cg_dma(virtual tb_intf intf) @(posedge intf.clk);
  option.per_instance = 1;

  reset_cp: coverpoint intf.rst {
    bins reset_asserted = {1'b1};
    bins reset_deasserted = {1'b0};
  }

  intr_cp: coverpoint intf.intr {
    bins irq_asserted = {1'b1};
    bins irq_idle     = {1'b0};
  }

endgroup : cg_dma

class cvrg;

  virtual tb_intf intf;
  cg_dma cg;

  function new(virtual tb_intf intf);
    this.intf = intf;
    cg = new(intf);
  endfunction

endclass : cvrg
