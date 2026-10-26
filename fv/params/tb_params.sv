package tb_params;

  localparam int NUM_CHANNELS = 8;
  localparam int CLOCK_PERIOD = 10;
  localparam int MEM_DEPTH = 256;
  localparam logic [31:0] START_ADDRESS = 32'h0000_1000;

  localparam logic [31:0] REG_CTRL     = 32'd0;
  localparam logic [31:0] REG_SRC_ADDR = 32'd1;
  localparam logic [31:0] REG_DST_ADDR = 32'd2;
  localparam logic [31:0] REG_LEN      = 32'd3;
  localparam logic [31:0] REG_STATUS   = 32'd4;
  localparam logic [31:0] REG_PRIORITY = 32'd5;

endpackage : tb_params
