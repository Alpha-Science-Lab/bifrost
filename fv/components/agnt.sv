import tb_params::*;

class agnt;

  driver drv;
  mntr mn;
  gnrtr gnr;

  function new(virtual tb_intf intf, virtual wishbone_interface wb_cfg,
               mailbox #(trnxt) gnr_drv, mailbox #(int) mn_scb);
    drv = new(intf, wb_cfg, gnr_drv);
    mn = new(intf, mn_scb);
    gnr = new(intf, gnr_drv);
  endfunction

endclass : agnt
