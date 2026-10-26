import tb_params::*;

class envr;

  agnt ag;
  scoreboard scr;
  cvrg cvr;
  mailbox #(trnxt) gnr_drv;
  mailbox #(int) mn_scb;

  function new(virtual tb_intf intf, virtual wishbone_interface wb_cfg);
    gnr_drv = new();
    mn_scb = new();
    ag = new(intf, wb_cfg, gnr_drv, mn_scb);
    scr = new(mn_scb);
    cvr = new(intf);
  endfunction

  task automatic run();
    fork
      ag.drv.drive();
      ag.mn.run();
      scr.check();
    join_none
  endtask

endclass : envr
