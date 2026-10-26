/* 
 * File: bifrost_wb_dma.sv
 *
 * Wishbone DMA controller with 8 independent channels, per-channel
 * priority control, and round-robin arbitration among equal-priority
 * requests.
 *
 * The block presents a configuration window to the host through a Wishbone
 * slave interface and issues transfer traffic over a dedicated Wishbone master
 * interface. Each channel owns its own source address, destination address,
 * transfer length, interrupt enable, and completion status.
 *
 * Register access is word-addressed and starts at START_ADDRESS over a window
 * of SIZE 32-bit registers.
 */

module bifrost_wb_dma #(
  parameter bit [31:0] START_ADDRESS = 32'h0012_0300,
  parameter bit [31:0] SIZE          = 32'd64
)(
  input logic clk,
  input logic rst,
  output logic intr,

  wishbone_interface.slave wb,
  wishbone_interface.master dma
);

  localparam int NUM_CHANNELS = 8;
  localparam int PRIORITY_WIDTH = 3;

  localparam logic [31:0] REG_CTRL     = 32'd0;
  localparam logic [31:0] REG_SRC_ADDR = 32'd1;
  localparam logic [31:0] REG_DST_ADDR = 32'd2;
  localparam logic [31:0] REG_LEN      = 32'd3;
  localparam logic [31:0] REG_STATUS   = 32'd4;
  localparam logic [31:0] REG_PRIORITY = 32'd5;

  typedef enum logic [2:0] {
    DMA_IDLE,
    DMA_READ,
    DMA_WRITE,
    DMA_DONE
  } dma_state_t;

  logic [31:0] addr;
  logic err;
  logic wr_en;
  logic [2:0] channel_sel;
  logic [2:0] reg_sel;

  logic [31:0] reg_src_addr [0:NUM_CHANNELS-1];
  logic [31:0] reg_dst_addr [0:NUM_CHANNELS-1];
  logic [31:0] reg_len [0:NUM_CHANNELS-1];
  logic [31:0] reg_status [0:NUM_CHANNELS-1];
  logic [2:0] channel_priority [0:NUM_CHANNELS-1];

  logic [31:0] src_ptr [0:NUM_CHANNELS-1];
  logic [31:0] dst_ptr [0:NUM_CHANNELS-1];
  logic [31:0] remaining [0:NUM_CHANNELS-1];
  logic [31:0] dma_data;

  logic [NUM_CHANNELS-1:0] start_req;
  logic [NUM_CHANNELS-1:0] irq_en;
  logic [NUM_CHANNELS-1:0] dma_busy;
  logic [NUM_CHANNELS-1:0] dma_done;
  logic [NUM_CHANNELS-1:0] dma_error;

  logic [2:0] rr_cursor;
  logic [2:0] active_channel;
  logic active_valid;
  dma_state_t state;

  // Address decode for the local register window.
  assign addr = wb.adr - START_ADDRESS;
  assign err = (wb.adr < START_ADDRESS) || (wb.adr >= (START_ADDRESS + SIZE));
  assign wr_en = wb.cyc & wb.stb & wb.we & ~err;

  always_comb begin
    // Aggregate per-channel completion interrupts into one CPU-visible signal.
    intr = 1'b0;
    for (int i = 0; i < NUM_CHANNELS; i++) begin
      intr |= (irq_en[i] & dma_done[i]);
    end

    wb.dat_miso = 32'h0;
    channel_sel = '0;
    reg_sel     = '0;

    // Decode the channel number and the register offset inside that channel.
    if (wb.cyc && wb.stb && !wb.we && !err) begin
      channel_sel = addr[5:3];
      reg_sel     = addr[2:0];

      case (reg_sel)
        REG_CTRL:     wb.dat_miso = {28'b0, irq_en[channel_sel], dma_done[channel_sel], dma_busy[channel_sel], 1'b0};
        REG_SRC_ADDR: wb.dat_miso = reg_src_addr[channel_sel];
        REG_DST_ADDR: wb.dat_miso = reg_dst_addr[channel_sel];
        REG_LEN:      wb.dat_miso = reg_len[channel_sel];
        REG_STATUS:   wb.dat_miso = reg_status[channel_sel];
        REG_PRIORITY: wb.dat_miso = {29'b0, channel_priority[channel_sel]};
        default:      wb.dat_miso = 32'h0;
      endcase
    end
  end

  always_comb begin
    // Choose which channel is allowed to run next:
    // 1) highest priority among requests
    // 2) round-robin ordering within the same priority level
    active_valid = 1'b0;
    active_channel = '0;

    for (int pr = 7; pr >= 0; pr--) begin
      for (int i = 0; i < NUM_CHANNELS; i++) begin
        logic [3:0] rr_index;
        logic [2:0] idx;

        rr_index = rr_cursor + i;
        if (rr_index >= 4'd8) begin
          rr_index = rr_index - 4'd8;
        end
        idx = rr_index[2:0];

        if (start_req[idx] && !dma_busy[idx] && (channel_priority[idx] == pr[2:0])) begin
          active_valid   = 1'b1;
          active_channel = idx;
          break;
        end
      end

      if (active_valid) begin
        break;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      wb.ack      <= 1'b0;
      wb.err      <= 1'b0;
      dma.adr     <= '0;
      dma.sel     <= 4'hF;
      dma.dat_mosi <= '0;
      dma.cyc     <= 1'b0;
      dma.stb     <= 1'b0;
      dma.we      <= 1'b0;

      for (int i = 0; i < NUM_CHANNELS; i++) begin
        reg_src_addr[i]     <= '0;
        reg_dst_addr[i]     <= '0;
        reg_len[i]          <= '0;
        reg_status[i]       <= '0;
        channel_priority[i] <= 3'd3;
        src_ptr[i]          <= '0;
        dst_ptr[i]          <= '0;
        remaining[i]        <= '0;
        start_req[i]        <= 1'b0;
        irq_en[i]           <= 1'b0;
        dma_busy[i]         <= 1'b0;
        dma_done[i]         <= 1'b0;
        dma_error[i]        <= 1'b0;
      end

      dma_data    <= '0;
      rr_cursor   <= '0;
      state       <= DMA_IDLE;
    end else begin
      wb.ack <= wb.cyc && wb.stb && !wb.ack;
      wb.err <= wb.cyc && wb.stb && err && !wb.err;

      for (int i = 0; i < NUM_CHANNELS; i++) begin
        reg_status[i][0] <= dma_busy[i];
        reg_status[i][1] <= dma_done[i];
        reg_status[i][2] <= dma_error[i];
        reg_status[i][3] <= irq_en[i];
      end

      if (wr_en) begin
        case (reg_sel)
          REG_CTRL: begin
            irq_en[channel_sel] <= wb.dat_mosi[3];
            if (wb.dat_mosi[0]) begin
              start_req[channel_sel] <= 1'b1;
              dma_done[channel_sel] <= 1'b0;
            end
          end
          REG_SRC_ADDR: reg_src_addr[channel_sel] <= wb.dat_mosi;
          REG_DST_ADDR: reg_dst_addr[channel_sel] <= wb.dat_mosi;
          REG_LEN:      reg_len[channel_sel] <= wb.dat_mosi;
          REG_PRIORITY: channel_priority[channel_sel] <= wb.dat_mosi[2:0];
          default: ;
        endcase
      end

      case (state)
        DMA_IDLE: begin
          // The arbiter has selected a channel. Load its source/destination
          // pointers and begin the transfer sequence.
          dma.adr     <= '0;
          dma.sel     <= 4'hF;
          dma.dat_mosi <= '0;
          dma.cyc     <= 1'b0;
          dma.stb     <= 1'b0;
          dma.we      <= 1'b0;

          if (active_valid) begin
            logic [3:0] rr_after;
            rr_after = active_channel + 4'd1;
            if (rr_after >= 4'd8) begin
              rr_after = '0;
            end

            if (reg_len[active_channel] == 32'd0) begin
              dma_done[active_channel]  <= 1'b1;
              dma_busy[active_channel]  <= 1'b0;
              dma_error[active_channel] <= 1'b0;
              start_req[active_channel]  <= 1'b0;
              rr_cursor                 <= rr_after[2:0];
              state                     <= DMA_DONE;
            end else begin
              src_ptr[active_channel]    <= reg_src_addr[active_channel];
              dst_ptr[active_channel]    <= reg_dst_addr[active_channel];
              remaining[active_channel]  <= reg_len[active_channel];
              dma_busy[active_channel]   <= 1'b1;
              dma_done[active_channel]   <= 1'b0;
              dma_error[active_channel]  <= 1'b0;
              start_req[active_channel]  <= 1'b0;
              rr_cursor                 <= rr_after[2:0];
              state                     <= DMA_READ;
            end
          end
        end

        DMA_READ: begin
          // Read one word from the source address and hold it for the write
          // phase of the same transfer.
          dma.adr     <= src_ptr[active_channel];
          dma.sel     <= 4'hF;
          dma.dat_mosi <= '0;
          dma.cyc     <= 1'b1;
          dma.stb     <= 1'b1;
          dma.we      <= 1'b0;

          if (dma.ack) begin
            dma_data <= dma.dat_miso;
            state    <= DMA_WRITE;
          end else if (dma.err) begin
            dma_busy[active_channel]  <= 1'b0;
            dma_done[active_channel]  <= 1'b0;
            dma_error[active_channel] <= 1'b1;
            state                    <= DMA_DONE;
          end
        end

        DMA_WRITE: begin
          // Write the previously captured data to the destination address and
          // advance the source/destination pointers for the next beat.
          dma.adr     <= dst_ptr[active_channel];
          dma.sel     <= 4'hF;
          dma.dat_mosi <= dma_data;
          dma.cyc     <= 1'b1;
          dma.stb     <= 1'b1;
          dma.we      <= 1'b1;

          if (dma.ack) begin
            src_ptr[active_channel]   <= src_ptr[active_channel] + 1'b1;
            dst_ptr[active_channel]   <= dst_ptr[active_channel] + 1'b1;
            remaining[active_channel] <= remaining[active_channel] - 1'b1;

            if (remaining[active_channel] == 32'd1) begin
              dma_busy[active_channel]  <= 1'b0;
              dma_done[active_channel]  <= 1'b1;
              dma_error[active_channel] <= 1'b0;
              state                    <= DMA_DONE;
            end else begin
              state <= DMA_READ;
            end
          end else if (dma.err) begin
            dma_busy[active_channel]  <= 1'b0;
            dma_done[active_channel]  <= 1'b0;
            dma_error[active_channel] <= 1'b1;
            state                    <= DMA_DONE;
          end
        end

        DMA_DONE: begin
          dma.adr     <= '0;
          dma.sel     <= 4'hF;
          dma.dat_mosi <= '0;
          dma.cyc     <= 1'b0;
          dma.stb     <= 1'b0;
          dma.we      <= 1'b0;

          if (!start_req[active_channel]) begin
            logic [3:0] rr_after;
            dma_busy[active_channel] <= 1'b0;
            rr_after = active_channel + 4'd1;
            if (rr_after >= 4'd8) begin
              rr_after = '0;
            end
            rr_cursor <= rr_after[2:0];
            state     <= DMA_IDLE;
          end
        end

        default: begin
          state <= DMA_IDLE;
        end
      endcase
    end
  end
endmodule
