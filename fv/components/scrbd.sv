class scrbd;

  mailbox #(trnxt) mn_scb;
  trnxt trn;
  int expected_count, observed_count;
  int err_cnt, total;

  function new(mailbox #(trnxt) mn_scb);
    this.mn_scb = mn_scb;
    expected_count = 0;
    observed_count = 0;
    err_cnt = 0;
    total = 0;
  endfunction

  virtual task automatic check();
    forever begin
      mn_scb.get(trn);
      total++;
      observed_count = trn.observed_done_count;
      if (!trn.intr_seen) begin
        err_cnt++;
        $error("Scoreboard got transaction without interrupt indication");
      end
      if (observed_count != expected_count + 1) begin
        err_cnt++;
        $error("DMA completion mismatch: got %0d, expected %0d", observed_count, expected_count + 1);
      end
      expected_count = observed_count;
    end
  endtask

  task automatic report();
    $display("scoreboard: total=%0d observed=%0d errors=%0d", total, observed_count, err_cnt);
  endtask

endclass : scrbd
