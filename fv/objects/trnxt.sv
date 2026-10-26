import tb_params::*;

class trnxt;

  rand int unsigned channel;
  rand logic [31:0] src;
  rand logic [31:0] dst;
  rand logic [31:0] len;
  rand logic [2:0] prio;
  rand bit irq_en;

  constraint c_channel {
    channel < NUM_CHANNELS;
  }

  constraint c_len {
    len inside {[1:16]};
  }

  constraint c_addr {
    src inside {[32'h0000_0000:32'h0000_00FF]};
    dst inside {[32'h0000_0040:32'h0000_00FF]};
  }

  constraint c_prio {
    prio inside {[3'd0:3'd7]};
  }

endclass : trnxt
