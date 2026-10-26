import tb_params::*;

class test_base;

  envr env;
  mailbox #(trnxt) gnr_drv;

  function new(virtual tb_intf intf, virtual wishbone_interface wb_cfg);
    env = new(intf, wb_cfg);
    gnr_drv = env.gnr_drv;
  endfunction

  task automatic run_test();
    int count;

    env.run();
    env.ag.gnr.gen(4);
    repeat (50) @(posedge env.ag.drv.intf.clk);
    env.scr.report();
    $display("CRV DMA test complete: %0d generator transactions", 4);
  endtask

endclass : test_base
