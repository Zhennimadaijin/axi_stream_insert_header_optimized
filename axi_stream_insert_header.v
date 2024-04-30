`timescale 1ns/1ps 

module axi_stream_insert_header#(
    parameter DATA_WD = 32,
    parameter DATA_BYTE_WD = DATA_WD / 8,
    parameter BYTE_CNT_WD = $ clog2(DATA_BYTE_WD)
)( 
    input                  		 clk,
    input                   	 rst_n,
    // AXI Stream input original data
    input                     	     valid_in,
    input [DATA_WD-1 : 0]     	     data_in,
    input [DATA_BYTE_WD-1 : 0] 	     keep_in,
    input                      	     last_in,
    output                     	     ready_in,
    // AXI Stream output with header inserted
    output                           valid_out,
    output [DATA_WD-1 : 0]       	   data_out,
    output [DATA_BYTE_WD-1 : 0]  	   keep_out,
    output                           last_out,
    input                            ready_out,
    // The header to be inserted to AXI Stream input
    input                            valid_insert,
    input [DATA_WD-1 : 0]            data_insert,
    input [DATA_BYTE_WD-1 : 0]       keep_insert,
    input [BYTE_CNT_WD-1 : 0]        byte_insert_cnt, 
    input [BYTE_CNT_WD-1 : 0]        ready_insert
);
    // Your code here
    reg                              hdr_valid_r1;
    reg                              hdr_data_r1;
    reg                              hdr_keep_r1;
    reg                              byte_insert_cnt_r1;
    reg                              last_out_r1;
    reg  [DATA_WD-1:0]               temp_data;
    reg  [DATA_BYTE_WD_1:0]          temp_keep;   



  
 always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
        hdr_valid_r1         <= 1'b0;
        hdr_data_r1          <=  'b0;
        hdr_keep_r1          <=  'b0;
        byte_insert_cnt_r1   <=  'b0;
    end else if (ready_insert & valid_insert) begin 
        hdr_valid_r1         <= 1'b1;
        hdr_data_r1          <= data_insert;
        hdr_keep_r1          <= keep_insert;
        byte_insert_cnt_r1   <= byte_insert_cnt;
    end else if (ready_out & last_out)  begin 
        hdr_valid_r1         <= 1'b0;
    end 
 end 


 assign ready_in = !hdr_valid_r1;

  always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
      temp_data   <= 'b0;
      temp_keep   <= 'b0;
    end else if (hdr_valid_r1 & ready_in & valid_in) begin 
      temp_data = (hdr_data_r1 << (8*(DATA_BYTE_WD - byte_insert_cnt_r1))) | data_in;
      temp_keep =(hdr_keep_r1 << (DATA_BYTE_WD -byte_insert_cnt_r1)) | keep_in;
    end else if (ready_in & valid_in) begin 
      temp_data = temp_in;
      temp_keep = keep_in;
    end 
  end 

  assign valid_out = hdr_valid_r1 ? valid_in : 1'b0;
  assign data_out  = temp_data;
  assign keep_out  = temp_keep;

  always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
      last_out_r1 <= 1'b0;
    end else if (ready_out) begin 
      last_out_r1 <= last_in;
    end 
  end 

  assign last_out = last_out_r1;

endmodule 
      
  

  














  
