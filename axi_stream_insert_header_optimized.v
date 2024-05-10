`timescale 1ns/1ps 
module axi_stream_insert_header#(
    parameter DATA_WD          = 32,
    parameter DATA_BYTE_WD     = DATA_WD / 8,
    parameter BYTE_CNT_WD      = $ clog2(DATA_BYTE_WD)
)( 
    input                            clk,
    input                   	     rst_n,
    // AXI Stream input original data
    input                     	     valid_in,
    input [DATA_WD-1 : 0]     	     data_in,
    input [DATA_BYTE_WD-1 : 0] 	     keep_in,
    input                      	     last_in,
    output                     	     ready_in,
    // AXI Stream output with header inserted
    output                           valid_out,
    output [DATA_WD-1 : 0]           data_out,
    output [DATA_BYTE_WD-1 : 0]      keep_out,
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


    

function [DATA_BYTE_WD-1:0] shift_keep_left;
	input [DATA_BYTE_WD-1:0] value;
  	input integer shift_amt;
    	begin
        	shift_keep_left = value << shift_amt;
      	end
endfunction

    
always @(posedge clk or negedge rst_n) 
 begin 
	if (!rst_n) 
		begin                                                         //复位信号有效，初始化信号
        	hdr_valid_r1         <= 1'b0;
        	hdr_data_r1          <=  'b0;
        	hdr_keep_r1          <=  'b0;
        	byte_insert_cnt_r1   <=  'b0;
        	last_out_r1          <= 1'b0;
        	temp_data            <=  'b0;
        	temp_keep            <=  'b0;
        	ready_in             <= 1'b1;
       end 
  	 else 
		begin    
     		if (ready_insert & valid_insert) 
			 	begin                                 					//当成功握手时，进行数据传输
        	  		hdr_valid_r1         <= 1'b1;                       //当前有头部数据准备插入
       	  	  		hdr_data_r1          <= data_insert;                //将插入数据寄存   
        	  		hdr_keep_r1          <= keep_insert;                //插入选通信号寄存
        	  		byte_insert_cnt_r1   <= byte_insert_cnt;            //将插入的字节位数寄存
        	  		ready_in             <= ready_out;                  //当从设备准备好接收数据时，主设备才能准备发送数据
             	end
			else if (ready_out & valid_out & last_out)  
				begin                              			              //准备接收且为最后一个数据包时
        	  		hdr_valid_r1         <= 1'b0;                         //成功插入后，进行清零，为下一次传输做准备
        	  		ready_in             <= ready_out;                    //当从设备准备好接收数据时，主设备才能准备发送数据
        		end 
			else if (ready_in & valid_in & ~hdr_valid_r1) 	
				begin               							         //没有头部数据插入时，从设备准备接收数据，且数据成功到达
        			temp_data            <= data_in;                     //将当前输入数据寄存
        			temp_keep            <= keep_in;  				     //将当前数据保持信号寄存
				end
			if (last_in)
				begin                                                 	//如果当前是数据包最后一个数据
                	last_out_r1          <= 1'b1;                       //表示当前是最后一个数据 
                	ready_in             <= ready_out;    				//准备好接收数据时，主设备才能准备发送数据，可避免数据溢出
				end 
			else if (ready_in & valid_in & hdr_valid_r1)	            //有头部数据插入时，从设备准备接收数据，且数据成功到达
				begin            
                	integer     shift_amt = DATA_BYTE_WD - byte_insert_cnt_r1;                 	 //计算合并数据时需要左移数据的比特位
                                temp_keep <= shift_keep_left(hdr_keep_r1, shift_amt) | keep_in;  //更新数据选通的寄存器，并与输入保持信号进行或操作 
                                last_out_r1  <= last_in;                                      	 // 可以告知从设备接受结束
                end
			if (ready_out)																	 //从设备准备好接收数据		
				begin                                                   
                    last_out_r1      <= last_in;                               				 //如果接收方准备好接收数据，last_out_r1 将反映当前数据是否是事务的最后一个字节。
                end
     	end
 end 

always @(posedge clk or negedge rst_n) 
	begin 
		if (!rst_n) 
			begin 
      			keep_out    <=  'b0; 
      			data_out    <=  'b0;
      			valid_out   <= 1'b0;  
      			last_out    <= 1'b0;
    		 end 
		else if (ready_out ) 														   //接收方准备接收数据
			 begin                                           
      			valid_out   <= hdr_valid_r1 ? valid_in : 1'b1;                         //valid_out的值根据头部插入信号的状态更新
      			data_out    <= hdr_valid_r1 ? hdr_data_r1 : temp_data;                 //data_out的值根据头部插入信号的状态更新，如果有头部插入信号那么该值等于hdr_data_r1的值，否则直等于data_in的值
      			keep_out    <= hdr_valid_r1 ? hdr_keep_r1 : temp_keep;                 //keep_out的值根据又不插入信号的状态更新，如果有头部插入信号那么该值等于hdr_keep_r1的值，否则直接等于keep_in的值
      			last_out    <= hdr_valid_r1 ? 1'b1        : last_out_r1;               //last_out的值根据头部插入信号的状态更新，如果有头部插入信号那么该值等于1'b1指示头部插入数据作为最后一个数据项发送，否则为last_out_r1的值
    		 end
     end 
  
endmodule
  














  
