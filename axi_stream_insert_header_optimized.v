`timescale 1ns/1ps 

module axi_stream_insert_header#(
    parameter DATA_WD          = 32,
    parameter DATA_BYTE_WD     = DATA_WD / 8,
    parameter BYTE_CNT_WD      = $ clog2(DATA_BYTE_WD)
)( 
    input                  		     clk,
    input                   	     rst_n,
    // AXI Stream input original data
    input                     	     valid_in,
    input [DATA_WD-1 : 0]     	     data_in,
    input [DATA_BYTE_WD-1 : 0] 	     keep_in,
    input                      	     last_in,
    output                     	     ready_in,
    // AXI Stream output with header inserted
    output                           valid_out,
    output [DATA_WD-1 : 0]       	 data_out,
    output [DATA_BYTE_WD-1 : 0]  	 keep_out,
    output                           last_out,
    input                            ready_out,
    // The header to be inserted to AXI Stream input
    input                            valid_insert,
    input [DATA_WD-1 : 0]            data_insert,
    input [DATA_BYTE_WD-1 : 0]       keep_insert,
    input [BYTE_CNT_WD-1 : 0]        byte_insert_cnt, 
    input                            ready_insert
);
    // Your code here

    reg  [DATA_WD-1:0]               hdr_data_r1;
    reg  [DATA_BYTE_WD-1:0]          hdr_keep_r1;
    reg  [BYTE_CNT_WD-1:0]           byte_insert_cnt_r1;
    reg                              last_out_r1;
    reg                              hdr_valid_r1;
    reg  [DATA_WD-1:0]               temp_data;
    reg  [DATA_BYTE_WD_1:0]          temp_keep;   


    
 function [DATA_WD-1:0] shift_left;
    input [DATA_WD-1:0] value;
        begin
            shift_left = value << 2;
        end
    endfunction


    
function [DATA_BYTE_WD-1:0] shift_keep_left;
     input [DATA_BYTE_WD-1:0] value;
        begin
            shift_keep_left = value << 2;
        end
    endfunction

    
 always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
        hdr_valid_r1         <= 1'b0;
        hdr_data_r1          <=  'b0;
        hdr_keep_r1          <=  'b0;
        byte_insert_cnt_r1   <=  'b0;
        last_out_r1          <= 1'b0;
        temp_data            <=  'b0;
        temp_keep            <=  'b0;
        ready_in             <= 1'b1;
    end else begin  
        if (ready_insert & valid_insert) begin 
        hdr_valid_r1         <= 1'b1;
        hdr_data_r1          <= data_insert;
        hdr_keep_r1          <= keep_insert;
        byte_insert_cnt_r1   <= byte_insert_cnt;
        ready_in             <= ready_out;
    end else if (ready_out & last_out)  begin 
        hdr_valid_r1         <= 1'b0;
        ready_in             <= ready_out;
    end else if (ready_out & valid_in & ~hdr_valid_r1) begin 
        temp_data            <= data_in;
        temp_keep            <= keep_in;
    if (last_in) begin 
        last_out_r1          <= 1'b1;
    end 
        ready_in             <= ready_out;
    end else if (ready_out & hdr_valid_r1 & valid_in) begin
    integer     shift_amt = DATA_BYTE_WD - byte_insert_cnt_r1;
                   
        temp_keep    <= shift_keep_left(hdr_keep_r1, shift_amt) | keep_in;
                    last_out_r1  <= last_in;
    end
        if (raady_out) begin 
                    last_out_r1      <= last_in;
        end
    end
 end 

  always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
      keep_out    <=  'b0; 
      data_out    <=  'b0;
      valid_out   <= 1'b0;  
      last_out    <= 1'b0;
    end else if (ready_out) begin
      valid_out   <= hdr_valid_r1 ? valid_in : 1'b1;
      data_out    <= hdr_valid_r1 ? hdr_data_r1 : data_in;
      keep_out    <= hdr_valid_r1 ? hdr_keep_r1 : keep_in;
      last_out    <= hdr_valid_r1 ? 1'b1        : last_out_r1;
    end
  end 
  
endmodule
  














  
