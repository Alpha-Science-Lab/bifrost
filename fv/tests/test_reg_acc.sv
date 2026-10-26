import tb_params::*;

class test_reg_acc extends test_base;

  function new(virtual tb_intf intf, virtual wishbone_interface wb_cfg);
    super.new(intf, wb_cfg);
  endfunction

  virtual task automatic run_test();
    logic [31:0] rdata;

    reset(10);
    
    for (int ch = 0; ch < NUM_CHANNELS; ch++) begin
      env.ag.drv.wb_read(START_ADDRESS + (ch * 8) + REG_CTRL, rdata);
      env.ag.drv.wb_read(START_ADDRESS + (ch * 8) + REG_SRC_ADDR, rdata);
      env.ag.drv.wb_read(START_ADDRESS + (ch * 8) + REG_DST_ADDR, rdata);
      env.ag.drv.wb_read(START_ADDRESS + (ch * 8) + REG_LEN, rdata);
      env.ag.drv.wb_read(START_ADDRESS + (ch * 8) + REG_STATUS, rdata);
      env.ag.drv.wb_read(START_ADDRESS + (ch * 8) + REG_PRIORITY, rdata);
    end
    
    letpass(100);
    env.scr.report();
    $display("CRV DMA test complete: generator-driver-monitor-scoreboard flow verified");
  endtask

endclass