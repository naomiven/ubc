module shuffle(
			input clk, rst, init_fin,
			input logic [7:0] q,
			input logic [23:0] secret_key,
			output logic wren, end_2a,
			output logic [7:0] data, addr
			);
			
logic [7:0] addr_i, addr_j, secret_key_set, data_i, data_j, init_data;
logic [15:0] state;
logic gen_addr, read1, read2, store1, store2, mix,write1,write2,swap_data;
logic task1, task2;

logic [1:0] k;
parameter [1:0] keylength = 3;
			
// states:
// TASK 2: shuffle and swap states
							//  15   11   7    3
parameter shuff_idle =		16'b0000_0100_0000_0000;
parameter read_i =			16'b0000_0000_0000_0100;
parameter stall_i =			16'b0000_0000_0001_0000;
parameter shuffle =			16'b0000_0000_0100_0000;
parameter read_j =			16'b0000_0000_0000_1000;
parameter stall_j =			16'b0000_0000_0010_0000;
parameter swap =			16'b0010_0010_0000_0000;
parameter en_wren_1 =		16'b0000_0000_0000_0010;
parameter write_data_i =	16'b0000_0000_1000_0010;
parameter stall_write =		16'b0100_0000_0000_0000;
parameter en_wren_2 =		16'b0000_0100_0000_0010;
parameter write_data_j =	16'b0000_0001_0000_0010;
parameter get_addr =		16'b0010_0000_0000_0001;
parameter shuffle_stall =	16'b1100_0000_0000_0000;
parameter shuffle_end =		16'b1001_0000_0000_0000;


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

assign end_2a = state[12];


logic clk_half;

always_ff @(posedge clk)
	clk_half <= !clk_half;


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
			
			// swap(s[i], s[j]);
		if (write1) begin
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
	else if (read1)    //read the address i
		addr <= addr_i;
	else if (store1)   //get the value and store it data_i
		data_i <= q;
	else if (read2)	 //read the address j
		addr <= addr_j; 
	else if (store2)	 //get the value and store at data_j
		data_j <= q;
		
	else if (end_2a)
		addr <= 0;
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
	addr_j <= addr_j + data_i + secret_key_set;			// j = j + s[i] + secret_key[i mod keylength];
end

	





// state machine
always_ff @(posedge clk_half, posedge rst) begin
	if (rst)
		state <= shuff_idle;
	else
		case (state)

			// ===== TASK 2: SHUFFLE DATA ===== //
			
			shuff_idle:		if (init_fin)
								state <= read_i;
							else
								state <= shuff_idle;
			
			read_i:			state <= stall_i;
			
			stall_i:		state <= shuffle;
			
			shuffle:		state <= read_j;
			
			read_j:			state <= stall_j;
			
			stall_j:		state <= swap;
			
			swap:			state <= en_wren_1;
			
			en_wren_1:		state <= write_data_i;
			
			write_data_i:	state <= stall_write;
			
			stall_write:	state <= en_wren_2;
			
			en_wren_2:		state <= write_data_j;
			
			write_data_j:	state <= get_addr;
			
			get_addr:		state <= shuffle_stall;
			
			shuffle_stall:	if (addr_i == 0)
								state <= shuffle_end;
							else
								state <= shuff_idle;
			
			shuffle_end:	state <= shuffle_end;
			
			default:		state <= shuff_idle;
		endcase
end

endmodule