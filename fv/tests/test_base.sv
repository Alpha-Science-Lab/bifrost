import tb_params::*;

class test_base;

  envr env;
  semaphore sem;
  int num_seq_gnr = 10;

  function new(virtual tb_intf intf, virtual wishbone_interface wb_cfg);
    sem = new(1);
    env = new(intf, wb_cfg, sem);

    fork
      env.ag.drv.drive();
      env.ag.mn.run();
      env.scr.check();
    join_none
  endfunction

  virtual task automatic reset(input int cycles);
    sem.get(1);
    env.ag.drv.reset(cycles);
  endtask

  virtual task automatic letpass(input int cycles);
    while (cycles > 0) begin
      @(posedge env.ag.drv.intf.clk);
      cycles--;
    end
  endtask

  virtual task automatic run_dma_sweep();
    num_seq_gnr = NUM_CHANNELS * 3;
    env.ag.gnr.gen(num_seq_gnr);
  endtask

  virtual task automatic run_test();
    reset(10);

    run_dma_sweep();
    
    letpass(100);
    env.scr.report();
    $display("CRV DMA test complete: generator-driver-monitor-scoreboard flow verified");
  endtask

endclass : test_base
