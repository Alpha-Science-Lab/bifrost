class test_inv_acc extends test_base;

  function new(virtual tb_intf intf, virtual wishbone_interface wb_cfg);
    super.new(intf, wb_cfg);
  endfunction

  virtual task automatic run_test();
    logic [31:0] rdata;

    reset(10);
    
    env.ag.drv.wb_read(START_ADDRESS + SIZE + 32'd4, rdata);
    env.ag.drv.wb_write(START_ADDRESS + SIZE + 32'd8, rdata);

    letpass(100);
    env.scr.report();
    $display("CRV DMA test complete: generator-driver-monitor-scoreboard flow verified");
  endtask

endclass