//`default_nettype none

module ksa(
			input logic CLOCK_50,
			input logic [3:0] KEY,
			input logic [9:0] SW,
			output logic [9:0] LEDR,
			output logic [6:0] HEX0,
			output logic [6:0] HEX1,
			output logic [6:0] HEX2,
			output logic [6:0] HEX3,
			output logic [6:0] HEX4,
			output logic [6:0] HEX5
			);

logic [7:0] q, q_m, q_d, data, data_m, data_d, address;
logic [4:0] addr_d1, addr_d2, addr_d, addr_m;
logic wren,wren_d,enable_part2,end_2a,end_2b;
logic [6:0] ssOut;
logic [3:0] nIn;
logic reset_n;
logic [7:0] bam;
logic [6:0] hx0, hx1, hx2, hx3, hx4, hx5;

assign reset_n = KEY[3];

//assign LEDR = {2'b0, q};

			
SevenSegmentDisplayDecoder h0(
.ssOut(HEX0),
.nIn(hx0)
);
SevenSegmentDisplayDecoder h1(
.ssOut(HEX1),
.nIn(hx1)
);
SevenSegmentDisplayDecoder h2(
.ssOut(HEX2),
.nIn(hx2)
);
SevenSegmentDisplayDecoder h3(
.ssOut(HEX3),
.nIn(hx3)
);
SevenSegmentDisplayDecoder h4(
.ssOut(HEX4),
.nIn(hx4)
);
SevenSegmentDisplayDecoder h5(
.ssOut(HEX5),
.nIn(hx5)
);


logic[7:0] data1,address1,data2,data3,address2,address3;
logic wren1,wren2,wren3;
//assign data= data1 | data2 | data3;
//assign address = address1 | address2 | address3 ;
//assign wren= wren1 | wren2 | wren3;

assign address = end_2a ? address3 : (enable_part2 ? address2 : address1);
assign data = end_2a ? data3 : (enable_part2 ? data2 : data1);
assign wren = end_2a ? wren3 : (enable_part2 ? wren2 : wren1);
//assign addr_d = end_2b ? addr_d2 : (end_2a ? addr_d1 : 0);


/*			
task3 t3 (
.q_d(q_d),
.addr_d(addr_d2),
.end_2b(end_2b),
.secret_key(bam),
.led(LEDR[9:0]),
.hex_disp_0(hx0),
.hex_disp_1(hx1),
.hex_disp_2(hx2),
.hex_disp_3(hx3),
.hex_disp_4(hx4),
.hex_disp_5(hx5),
);
*/
newpart2b2 task2b(
.clk(CLOCK_50),
.rst(),
.q(q),
.q_m(q_m),
.end_2a(end_2a),
.wren(wren3),
.wren_d(wren_d),
.data(data3),
.addr(address3),
.data_m(data_m),
.data_d(data_d),
.addr_d(addr_d),
.addr_m(addr_m),
.end_2b(end_2b));



			
shuffle prt2(
.clk(CLOCK_50),
.init_fin(enable_part2),
.q(q),
.secret_key({14'b0,SW[9:0]}),
.wren(wren2),
.data(data2),
.addr(address2),
.end_2a(end_2a)
);

init_mem initmem(
.clk(CLOCK_50),
.q(),
.wren(wren1),
.data(data1),
.addr(address1),
.init_fin(enable_part2)
); 


decrypted_message dmemory(
.address(addr_d),
.clock(~CLOCK_50),
.data(data_d),
.wren(wren_d),
.q(q_d)
);

encrypted_message ememory(
.address(addr_m),
.clock(~CLOCK_50),
.q(q_m)
);

s_memory smem(
.address(address),
.clock(~CLOCK_50),
.data(data),
.wren(wren),
.q(q)
);

endmodule
