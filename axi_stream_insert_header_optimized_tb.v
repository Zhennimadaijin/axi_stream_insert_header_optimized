`timescale 1ns/1ns

module axi_stream_insert_header_tb(
    );
parameter DATA_WD = 32;
parameter DATA_BYTE_WD = DATA_WD / 8;
parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD);

reg                             clk;
reg                             rst_n;

reg                             valid_insert;
reg [DATA_WD-1 : 0]             data_insert;
reg [DATA_BYTE_WD-1 : 0]        keep_insert;
wire                            ready_insert;
reg [BYTE_CNT_WD-1 : 0]         byte_insert_cnt;

reg                             valid_in;
reg [DATA_WD-1 : 0]             data_in;
reg [DATA_BYTE_WD-1 : 0]        keep_in;
reg                             last_in;
wire                            ready_in;

wire                             valid_out;
wire [DATA_WD-1 : 0]             data_out;
wire [DATA_BYTE_WD-1 : 0]        keep_out;
wire                             last_out;
reg                              ready_out;

reg [DATA_WD-1:0]                 data_r1;
reg [DATA_BYTE_WD-1:0]            data_keep_r1;
reg                               hdr_valid_r1;
reg [DATA_WD-1:0]                 hdr_data_r1;
reg [DATA_BYTE_WD-1:0]            hdr_keep_r1;
reg [BYTE_CNT_WD-1:0]             byte_insert_cnt_r1;
reg [DATA_WD-1:0]                 temp_data;
reg [DATA_BYTE_WD-1:0]            temp_keep;

axi_stream_insert_header axi(
  .clk(clk),
  .rst_n(rst_n),
  .valid_in(valid_in),
  .data_in(data_in),
  .keep_in(keep_in),
  .last_in(last_in),
  .ready_in(ready_in),
  .valid_out(valid_out),
  .data_out(data_out),
  .keep_out(keep_out),
  .last_out(last_out),
  .ready_out(ready_out),
  .valid_insert(valid_insert),
  .data_insert(data_insert),
  .keep_insert(keep_insert),
  .byte_insert_cnt(byte_insert_cnt),
  .ready_insert(ready_insert)
);

always #10 clk = ~clk;

initial begin
    hdr_valid_r1 <= 1'b0;
    hdr_data_r1 <= 'b0;
    hdr_keep_r1 <= 'b0;
    ready_insert <= 'b0;
    data_r1 <= 'b0;
    data_keep_r1 <= 'b0;
    byte_insert_cnt_r1 <= 'b0;
    temp_data = 'b0;
    temp_keep = 'b0;
end

task hdr_axi_slave;
    integer shift_amt = DATA_BYTE_WD - byte_insert_cnt_r1;
    begin
        ready_insert = $random;
        valid_insert = $random;
        data_insert = $random;
        shift_amt = $urandom_range(0, DATA_BYTE_WD-1);
        keep_insert = $random >> shift_amt;
        byte_insert_cnt = DATA_BYTE_WD - shift_amt;
    end
endtask

task data_axi;
    begin
        valid_in = $random;
        data_in = $random;
        keep_in = $random;
        last_in = $random;
    end
endtask

task data_axi_last;
    reg [DATA_BYTE_WD-1:0] last_cnt;
    begin
        valid_in = $random;
        last_in = $random;
        data_in = $random;
        last_cnt = $urandom_range(0, DATA_BYTE_WD-1);
        keep_in = $random << last_cnt;
        @(posedge clk);
        valid_in = $random;
        last_in = $random;
    end
endtask

task data_axi_intp;
    begin
        valid_in = $random;
        last_in = $random;
        data_in = $random;
        keep_in = $random;
    end
endtask

task test1;
    begin
        data_axi;
        hdr_axi_slave;
        @(posedge clk)
        valid_insert = $random;
        repeat(15) begin
            data_axi;
            @(posedge clk);
        end
        data_axi_last;
    end
endtask

task test2;
    begin
        hdr_axi_slave;
        @(posedge clk)
        hdr_axi_slave;
        @(posedge clk)
        hdr_axi_slave;
        @(posedge clk)
        valid_insert = $random;
        repeat(15) begin
            data_axi;
            @(posedge clk);
        end
        data_axi_last;
    end
endtask

task test3;
    begin
        repeat(15) begin
            data_axi;
            @(posedge clk);
        end
        hdr_axi_slave;
        @(posedge clk);
        hdr_axi_slave;
        @(posedge clk)
        repeat(15) begin
            data_axi;
            @(posedge clk);
        end
        data_axi_last;
    end
endtask

initial begin
    clk = 'd0;
    rst_n = 'd0;
    ready_out = 1'b1;
    #12 rst_n = 1'b1;
    test1;
    @(posedge clk);
    test2;
    @(posedge clk);
    test3;
    #200;
    $finish;
end

endmodule
