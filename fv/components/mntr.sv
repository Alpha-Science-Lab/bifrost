import tb_params::*;

class mntr;

  virtual tb_intf intf;
  mailbox #(trnxt) mn_scb;
  int done_count;

  function new(virtual tb_intf intf, mailbox #(trnxt) mn_scb);
    this.intf = intf;
    this.mn_scb = mn_scb;
    this.done_count = 0;
  endfunction

  virtual task automatic run();
    trnxt t;
    forever begin
      @(posedge intf.clk);
      if (intf.intr) begin
        done_count++;
        t = new();
        t.intr_seen = 1'b1;
        t.observed_done_count = done_count;
        mn_scb.put(t);
      end
    end
  endtask

endclass : mntr
