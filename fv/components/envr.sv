import tb_params::*;

class envr;

  agnt ag;
  scrbd scr;
  cvrg cvr;
  mailbox #(trnxt) gnr_drv;
  mailbox #(trnxt) mn_scb;

  function new(virtual tb_intf intf, virtual wishbone_interface wb_cfg, semaphore sem);
    gnr_drv = new();
    mn_scb = new();
    ag = new(intf, wb_cfg, gnr_drv, mn_scb, sem);
    scr = new(mn_scb);
    cvr = new(intf, wb_cfg);
  endfunction

endclass : envr
