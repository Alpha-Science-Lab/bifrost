import tb_params::*;

module tb_top;

  bit clk = 1'b0;
  tb_intf intf(clk);
  wishbone_interface wb_cfg();
  wishbone_interface dma_bus();

  bifrost_wb_dma #(
    .START_ADDRESS(32'h0000_1000),
    .SIZE(32'd64)
  ) dut (
    .clk(clk),
    .rst(intf.rst),
    .intr(intf.intr),
    .wb(wb_cfg),
    .dma(dma_bus)
  );

  wb_ram #(.DEPTH(256)) u_src_mem (
    .clk(clk),
    .rst(intf.rst),
    .wb(dma_bus)
  );

  initial begin
    intf.rst = 1'b1;
    repeat (2) @(posedge clk);
    intf.rst = 1'b0;
  end

  initial begin
    forever #(CLOCK_PERIOD / 2) clk = ~clk;
  end

  initial begin
    test_base test_dma_trn;
    test_reg_acc test_reg;
    test_inv_acc test_inv;
    test_dma_trn = new(intf, wb_cfg);
    test_reg = new(intf, wb_cfg);
    test_inv = new(intf, wb_cfg);
    test_reg.run_test();
    test_inv.run_test();
    test_dma_trn.run_test();
    #5000;
    $finish;
  end

endmodule : tb_top


/* Dummy wishbone ram to test DMA transaction on*/
module wb_ram #(
  parameter int DEPTH = 256
)(
  input logic clk,
  input logic rst,
  wishbone_interface.slave wb
);

  localparam int INDEX_WIDTH = $clog2(DEPTH);
  logic [31:0] mem [0:DEPTH-1];
  logic [31:0] word_idx;
  logic req_valid;

  initial begin
    for (int i = 0; i < DEPTH; i++) begin
      mem[i] = 32'd0;
    end
    mem[0] = 32'd101;
    mem[1] = 32'd202;
    mem[2] = 32'd303;
    mem[3] = 32'd404;
    mem[4] = 32'd505;
    mem[5] = 32'd606;
  end

  always_comb begin
    if (rst) begin
      wb.ack = 1'b0;
      wb.err = 1'b0;
      wb.dat_miso = '0;
    end else begin
      wb.ack = wb.cyc && wb.stb && req_valid;
      wb.err = wb.cyc && wb.stb && !req_valid;
      wb.dat_miso = (req_valid) ? mem[word_idx[INDEX_WIDTH-1:0]] : '0;
    end
  end

  always_comb begin
    word_idx = (wb.adr >> 2);
    req_valid = (word_idx < DEPTH);
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      // nothing
    end else if (wb.cyc && wb.stb && wb.we && req_valid) begin
      mem[word_idx[INDEX_WIDTH-1:0]] <= wb.dat_mosi;
    end
  end

endmodule : wb_ram
