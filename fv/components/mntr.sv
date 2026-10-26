import tb_params::*;

class mntr;

  virtual tb_intf intf;
  mailbox #(int) mon2scb;
  int done_count;

  function new(virtual tb_intf intf, mailbox #(int) mon2scb);
    this.intf = intf;
    this.mon2scb = mon2scb;
    this.done_count = 0;
  endfunction

  task automatic run();
    forever begin
      @(posedge intf.clk);
      if (intf.intr) begin
        done_count++;
        mon2scb.put(done_count);
      end
    end
  endtask

endclass : mntr
