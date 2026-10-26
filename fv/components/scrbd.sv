class scoreboard;

  mailbox #(int) mon2scb;
  int expected_count;
  int observed_count;

  function new(mailbox #(int) mon2scb);
    this.mon2scb = mon2scb;
    expected_count = 0;
    observed_count = 0;
  endfunction

  task automatic check();
    int value;
    forever begin
      mon2scb.get(value);
      observed_count = value;
      if (observed_count != expected_count + 1) begin
        $error("DMA completion mismatch: got %0d, expected %0d", observed_count, expected_count + 1);
      end
      expected_count = observed_count;
    end
  endtask

  task automatic report();
    $display("scoreboard: observed %0d DMA completions", observed_count);
  endtask

endclass : scoreboard
