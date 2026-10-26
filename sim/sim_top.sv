/*
 * File: sim_top.sv
 * Directed test for the Wishbone DMA core
 * Covers multi-channel programming, priority arbitration, and interrupt signaling
 * No random stimulus, no coverage
*/

module sim_top;

  localparam int DMA_REG_CTRL     = 0;
  localparam int DMA_REG_SRC_ADDR = 1;
  localparam int DMA_REG_DST_ADDR = 2;
  localparam int DMA_REG_LEN      = 3;
  localparam int DMA_REG_STATUS   = 4;
  localparam int DMA_REG_PRIORITY = 5;

  logic clk = 1'b0;
  logic rst = 1'b1;
  logic intr;

  wishbone_interface wb_cfg();
  wishbone_interface dma_bus();

  bifrost_wb_dma #(
    .START_ADDRESS(32'h0000_1000),
    .SIZE(32'd64)
  ) u_dma (
    .clk(clk),
    .rst(rst),
    .intr(intr),
    .wb(wb_cfg),
    .dma(dma_bus)
  );

  wb_ram #(.DEPTH(256)) u_src_mem (
    .clk(clk),
    .rst(rst),
    .wb(dma_bus)
  );

  function automatic logic [31:0] channel_base(input int channel);
    begin
      channel_base = 32'h0000_1000 + (channel * 8);
    end
  endfunction

  // Write a 32-bit register in the DMA control window.
  task wb_write(input logic [31:0] addr, input logic [31:0] data);
    begin
      wb_cfg.adr      = addr;
      wb_cfg.sel      = 4'hF;
      wb_cfg.dat_mosi = data;
      wb_cfg.we       = 1'b1;
      wb_cfg.cyc      = 1'b1;
      wb_cfg.stb      = 1'b1;

      while (!wb_cfg.ack) begin
        @(posedge clk);
      end

      wb_cfg.cyc = 1'b0;
      wb_cfg.stb = 1'b0;
      wb_cfg.we  = 1'b0;
      @(posedge clk);
    end
  endtask

  // Read a 32-bit register from the DMA control window.
  task wb_read(input logic [31:0] addr, output logic [31:0] data);
    begin
      wb_cfg.adr      = addr;
      wb_cfg.sel      = 4'hF;
      wb_cfg.we       = 1'b0;
      wb_cfg.cyc      = 1'b1;
      wb_cfg.stb      = 1'b1;

      while (!wb_cfg.ack) begin
        @(posedge clk);
      end

      data = wb_cfg.dat_miso;
      wb_cfg.cyc = 1'b0;
      wb_cfg.stb = 1'b0;
      @(posedge clk);
    end
  endtask

  task automatic dma_program_channel(
    input int channel,
    input logic [31:0] src,
    input logic [31:0] dst,
    input logic [31:0] len,
    input logic [2:0] prio
  );
    begin
      wb_write(channel_base(channel) + DMA_REG_SRC_ADDR, src);
      wb_write(channel_base(channel) + DMA_REG_DST_ADDR, dst);
      wb_write(channel_base(channel) + DMA_REG_LEN,      len);
      wb_write(channel_base(channel) + DMA_REG_PRIORITY, {29'b0, prio});
    end
  endtask

  task automatic dma_start_channel(input int channel, input logic irq_en);
    begin
      logic [31:0] ctrl_word;
      ctrl_word = (irq_en) ? 32'd9 : 32'd1;
      wb_write(channel_base(channel) + DMA_REG_CTRL, ctrl_word);
    end
  endtask

  initial begin
    repeat (2) @(posedge clk);
    rst = 1'b0;

    // Exercise multiple channels at once to validate the new features:
    //  - channel 0 and 1 share the same priority, so round-robin decides order
    //  - channel 2 has a higher priority than channel 0/1, so it should win first
    //  - the aggregated intr output should go high when any enabled channel completes
    dma_program_channel(0, 32'd0,   32'd64,  32'd4, 3'd2);
    dma_program_channel(1, 32'd8,   32'd128, 32'd3, 3'd2);
    dma_program_channel(2, 32'd16,  32'd192, 32'd2, 3'd5);

    dma_start_channel(0, 1'b1);
    dma_start_channel(1, 1'b1);
    dma_start_channel(2, 1'b1);

    wait (intr);
    $display("DMA interrupt asserted after completion of an enabled channel");
    $display("ch0 status=%0d ch1 status=%0d ch2 status=%0d", u_dma.reg_status[0], u_dma.reg_status[1], u_dma.reg_status[2]);

    repeat (20) @(posedge clk);
    $display("DMA multi-channel test complete");
    $finish;
  end

  always #5 clk = ~clk;

endmodule


/* Dummy wishbone ram to test DMA transaction on*/
module wb_ram #(
  parameter int DEPTH = 256
)(
  input logic clk,
  input logic rst,
  wishbone_interface.slave wb
);

  logic [31:0] mem [0:DEPTH-1];

  initial begin
    mem[0] = 32'd101;
    mem[1] = 32'd202;
    mem[2] = 32'd303;
    mem[3] = 32'd404;
  end

  always_ff @(posedge clk) 
  begin

    if (rst) begin
      wb.ack <= 1'b0;
      wb.err <= 1'b0;
      wb.dat_miso <= '0;

    end else begin
      wb.ack <= 1'b0;
      wb.err <= 1'b0;

      if (wb.cyc && wb.stb wb.adr < DEPTH) begin
        wb.ack <= 1'b1;
        if (wb.we) begin
          mem[wb.adr[15:2]] <= wb.dat_mosi;
        end 
        else begin
          wb.dat_miso <= mem[wb.adr[15:2]];
        end
      end else begin
        wb.err <= 1'b1;
      end
    end

  end

endmodule
