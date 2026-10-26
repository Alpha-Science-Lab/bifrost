import tb_params::*;

class driver;

  virtual tb_intf intf;
  virtual wishbone_interface wb_cfg;
  mailbox #(trnxt) gnr_drv;
  semaphore sem;

  function new(virtual tb_intf intf, virtual wishbone_interface wb_cfg, mailbox #(trnxt) gnr_drv, semaphore sem);
    this.intf = intf;
    this.wb_cfg = wb_cfg;
    this.gnr_drv = gnr_drv;
    this.sem = sem;
  endfunction

  virtual task reset(input int cycles);
    intf.rst = 1'b1;
    repeat (cycles) @(posedge intf.clk);
    intf.rst = 1'b0;
    repeat (2) @(posedge intf.clk);
    sem.put(1);
  endtask

  virtual task wb_write(input logic [31:0] addr, input logic [31:0] data);
    begin
      wb_cfg.adr      = addr;
      wb_cfg.sel      = 4'hF;
      wb_cfg.dat_mosi = data;
      wb_cfg.we       = 1'b1;
      wb_cfg.cyc      = 1'b1;
      wb_cfg.stb      = 1'b1;

      while (!wb_cfg.ack && !wb_cfg.err) begin
        @(posedge intf.clk);
      end

      wb_cfg.cyc = 1'b0;
      wb_cfg.stb = 1'b0;
      wb_cfg.we  = 1'b0;
      @(posedge intf.clk);
    end
  endtask

  virtual task wb_read(input logic [31:0] addr, output logic [31:0] data);
    begin
      wb_cfg.adr      = addr;
      wb_cfg.sel      = 4'hF;
      wb_cfg.dat_mosi = '0;
      wb_cfg.we       = 1'b0;
      wb_cfg.cyc      = 1'b1;
      wb_cfg.stb      = 1'b1;

      while (!wb_cfg.ack && !wb_cfg.err) begin
        @(posedge intf.clk);
      end

      data = wb_cfg.dat_miso;
      wb_cfg.cyc = 1'b0;
      wb_cfg.stb = 1'b0;
      wb_cfg.we  = 1'b0;
      @(posedge intf.clk);
    end
  endtask

  virtual task automatic drive();
    trnxt t;
    forever begin
      gnr_drv.get(t);
      sem.get(1);
      @(posedge intf.clk);
      program_txn(t);
      sem.put(1);
    end
  endtask

  virtual task automatic program_txn(trnxt t);
    logic [31:0] base;
    logic [31:0] ctrl;

    base = START_ADDRESS + (t.channel * 8);
    ctrl = (t.irq_en) ? 32'd9 : 32'd1;

    wb_write(base + REG_SRC_ADDR, t.src);
    wb_write(base + REG_DST_ADDR, t.dst);
    wb_write(base + REG_LEN,      t.len);
    wb_write(base + REG_PRIORITY, {29'b0, t.prio});
    wb_write(base + REG_CTRL,     ctrl);
  endtask

endclass : driver
