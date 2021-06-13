interface mib_if
  #(ADDR_BITS=24,DATA_BITS=32)
  (output logic start,
   output logic rd_wr_n,
   inout wire  [15:0] addr_data,
   input logic slave_ack
   );

  localparam P_CMD_ACK_TIMEOUT_CLKS=32;
  
/*  logic start;
  logic rd_wr_n;
  logic [15:0] addr_data='z;
  logic        slave_ack;*/
  
  logic        clk;
  logic        disable_clk=0;
  int        timeout_count=0;
  logic        addr_data_high_z_reg=0;
  logic [15:0] addr_data_reg='z;

  assign addr_data=addr_data_high_z_reg?'z:addr_data_reg;
  
  task run_clk(time period=80ns);
    while(~disable_clk) begin
      clk=0;
      #(period/2);
      clk=1;
      #(period/2);
    end
  endtask

  task write (input [23:0] waddr, input [31:0] wdata, string str="write");
    
    @(posedge clk);
    
    timeout_count = 0;
    @(posedge clk);
    
    start             = 1;
    rd_wr_n           = 0;
    addr_data_high_z_reg = 0;
    addr_data_reg  = waddr[ADDR_BITS-1:16];
    
    @(posedge clk);
    
    start       = 0;
    addr_data_reg  = waddr[15:0];
    
    @(posedge clk);
    
    addr_data_reg  = wdata[DATA_BITS-1:16];
    
    @(posedge clk);
    
    addr_data_reg  = wdata[15:0];
    
    @(posedge clk);
    
    while (1) begin
      //addr_data_reg = 'z;
      addr_data_high_z_reg = 1;
      @(posedge clk);
      if (slave_ack) begin
	break;
      end
      else if (timeout_count== P_CMD_ACK_TIMEOUT_CLKS) begin
	$display("CMD BUS WRITE: ADDR = 0x%x WRITE TIMEOUT!", waddr);
	return;
      end
      timeout_count++;
    end
    
    $display("CMD BUS WRITE: ADDR = 0x%x, DATA = 0x%X: %s", waddr, wdata, str);
    
  endtask

  task read (input [23:0] raddr, string str="read");
    logic [DATA_BITS-1:0] rdata;
    timeout_count = 0;
    @(posedge clk);
    
    start             = 1;
    rd_wr_n           = 1;
    addr_data_high_z_reg = 0;
    addr_data_reg  = raddr[ADDR_BITS-1:16];
    
    @(posedge clk);
    
    start       = 0;
    addr_data_reg  = raddr[15:0];
    
    @(posedge clk);
    
    while (1) begin
      //addr_data='z;
      addr_data_high_z_reg = 1;
      @(posedge clk);
      if (slave_ack) begin
	rdata[31:16] = addr_data[DATA_BITS-1:16];
	break;
      end
      else if (timeout_count== P_CMD_ACK_TIMEOUT_CLKS) begin
	$display("CMD BUS READ: ADDR = 0x%x READ TIMEOUT!", raddr);
	return;
      end
      timeout_count++;
    end
    
    @(posedge clk);
    
    rdata = addr_data[15:0];
    
    $display("CMD BUS READ: ADDR = 0x%x, DATA = 0x%X: %s", raddr, rdata, str);
    
  endtask
endinterface
