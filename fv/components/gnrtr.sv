import tb_params::*;

class gnrtr;

  virtual tb_intf intf;
  mailbox #(trnxt) gnr_drv;

  function new(virtual tb_intf intf, mailbox #(trnxt) gnr_drv);
    this.intf = intf;
    this.gnr_drv = gnr_drv;
  endfunction

  virtual task gen(input int num_seq_gnr);
    trnxt t;
    repeat (num_seq_gnr) begin
      t = new();
      if (!t.randomize()) begin
        $error("Generator randomization failed at time %0t", $time);
      end
      gnr_drv.put(t);
      $display("Generator queued randomized transaction at time %0t", $time);
      @(posedge intf.clk);
    end
  endtask

endclass : gnrtr
