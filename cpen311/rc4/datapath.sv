module datapath(
			input clk, rst,
			input logic [7:0] q,
			input logic [23:0] secret_key,
			output logic wren,
			output logic [7:0] data, addr
			);
			
logic [7:0] init_data, addr_i, addr_j, secret_key_set, data_i, data_j, tmp_data;
logic [15:0] state;
logic gen_addr, read1, read2, store1, store2, mix;
logic task1, task2;

logic [1:0] k;
parameter [1:0] keylength = 3;
			
// states:
// TASK 1: init states are for initializing s memory
parameter init_idle = 		16'b0001_0000_0000_0000;
parameter init_stall =		16'b0011_0000_0000_0000;
parameter init_write =		16'b0001_0000_0000_0011;
parameter init_end =		16'b1001_0000_0000_0000;
// TASK 2: shuffle and swap states
parameter shuff_idle =		16'b0000_0100_0000_0000;
parameter read_i =			16'b0000_0000_0000_0100;
parameter stall_i =			16'b0000_0000_0001_0000;
parameter shuffle =			16'b0000_0000_0100_0000;
parameter read_j =			16'b0000_0000_0000_1000;
parameter stall_j =			16'b0000_0000_0010_0000;
parameter swap =			16'b0010_0010_0000_0000;
parameter write_data_i =	16'b0000_0000_1000_0010;
parameter stall_write =		16'b0100_0000_0000_0000;
parameter write_data_j =	16'b0000_0001_0000_0010;
parameter get_addr =		16'b0010_0000_0000_0001;
parameter shuffle_stall =	16'b1100_0000_0000_0000;
parameter shuffle_end =		16'b1000_0000_0000_0000;

assign gen_addr = state[0];
assign wren = state[1];
assign read1 = state[2];
assign read2 = state[3];
assign store1 = state[4];
assign store2 = state[5];
assign mix = state[6];
assign write1 = state[7];
assign write2 = state[8];
assign swap_data = state[9];

assign init = state[12];

// counter
always_ff @(posedge gen_addr) begin
	if (rst)
		addr_i <= 0;
	else
		addr_i <= addr_i + 1;
end

// s[i] = i: data matches its address
assign init_data = addr_i;


// output data and addr
always_ff @(posedge clk) begin
	if (wren) begin
		if (init) begin
			addr <= addr_i;
			data <= init_data;
			end
		else if (write1) begin
			addr <= addr_i;
			data <= data_j;
			end
		else if (write2) begin
			addr <= addr_j;
			data <= data_i;
			end
		else
			addr <= addr;
	end
	
	// for shuffle/swap states
	else if (read1)
		addr <= addr_i;
	else if(store1)
		data_i <= q;
	else if (read2)
		addr <= addr_j;
	else if (store2)
		data_j <= q;
	else
		addr <= addr;
end






// SHUFFLE STATE //
assign k = addr_i % keylength;

always_comb begin
	case (k)
		0:			secret_key_set = secret_key[23:16];
		1: 			secret_key_set = secret_key[15:8];
		2:			secret_key_set = secret_key[7:0];
		default: 	secret_key_set = 0;
	endcase
end

always_ff @(posedge mix) begin
	addr_j <= addr_j + data_i + secret_key_set;
end

	





// state machine
always_ff @(posedge clk, posedge rst) begin
	if (rst)
		state <= init_idle;
	else
		case (state)
			// ===== TASK 1: INITIALIZE S MEMORY ===== //
			
			init_idle:		state <= init_write;
			
			init_write:		state <= init_stall;
			
			init_stall:		if (addr == 0)
								state <= init_end;
							else
								state <= init_idle;
								
			init_end:		state <= shuff_idle;
								
			
			// ===== TASK 2: SHUFFLE DATA ===== //
			
			shuff_idle:		state <= read_i;
			
			read_i:			state <= stall_i;
			
			stall_i:		state <= shuffle;
			
			shuffle:		state <= read_j;
			
			read_j:			state <= stall_j;
			
			stall_j:		state <= swap;
			
			swap:			state <= write_data_i;
			
			write_data_i:	state <= stall_write;
			
			stall_write:	state <= write_data_j;
			
			write_data_j:	state <= get_addr;
			
			get_addr:		state <= shuffle_stall;
			
			shuffle_stall:	if (addr_i == 0)
								state <= shuffle_end;
							else
								state <= shuff_idle;
			
			shuffle_end:	state <= shuffle_end;
			
			default:		state <= init_idle;
		endcase
end

endmodule
