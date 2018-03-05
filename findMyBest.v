`timescale 1ns/1ps
`define MEM_DEPTH  1024
`define MEM_WIDTH  8
`define WORD_WIDTH 16
`define HCM_LENGTH 11

/* States
 * 0: Find mybest
 * 1: Compute full mybest
 * 
 * NOte: Gagawin pang fixed-point yung mga values
 */

module findMyBest(clock, nrst, start, address, data_in, MY_BATTERY_STAT, mybest, done);
	input clock, nrst, start;
	input [`WORD_WIDTH-1:0] data_in, MY_BATTERY_STAT; //MY_BATTERY_STAT: fixed point 1./15
	output done;
	output [`WORD_WIDTH-1:0] address;
	output [`WORD_WIDTH-1:0] mybest; // fixed-point: 11./5

	// Registers
	reg done_buf;
	//reg [`WORD_WIDTH-1:0] address_count, k;
	reg [`WORD_WIDTH-1:0] address_count;
	reg [`WORD_WIDTH-1:0] mybest_buf, qValue; // fixed-point: mybest_buf (11./5), qValue (11./5)
	reg [1:0] state;
	reg [15:0] k;
	reg [31:0] kTemp; //MIKKO temp int
	reg [1:0] count; //MIKKO

	always @ (posedge clock) begin
		if (!nrst) begin
			done_buf <= 0;
			address_count <= 16'h1C8; // qValue address
			mybest_buf <= 16'hFFFE; // fixed-point
			state <= 0;
			k <= 0;
		end
		else begin
			case (state)
				0: begin
					if (start) begin
						state = 1;
						address_count <= 16'h1C8; // qValue address

						//MIKKO
						count <= 2'd3;
					end
					else state = 0;
				end

				1: begin
					qValue = data_in;
					if (qValue < mybest_buf) begin // fixed-point comparison (AS IS, since same radix point 11./5)
						mybest_buf = qValue;
					end

					if (address_count == 16'h246) begin
						//k = $ceil((`HCM_LENGTH-1) * MY_BATTERY_STAT); // fixed-point multiplication
						//MIKKO
						case(count)
							2'd3: begin
								//MULT
								kTemp = (`HCM_LENGTH - 1) * MY_BATTERY_STAT; //16./0 * 1./15 = 17./15
								count <= count - 1;
							end
							2'd2: begin
								//CEIL
								if(kTemp[14:0] != 15'd0) 
									k <= kTemp[30:15] + 1;
								else
									k <= kTemp[30:15];
								count <= count - 1;
							end
							2'd1: begin
								if (k >= `HCM_LENGTH)
									k = `HCM_LENGTH - 1;

								//NEXT STATE
								state = 2;
							end
						endcase

						address_count = 16'h648 + 2*k; // HCM address
					end
					else address_count = address_count + 2; // qValue address
				end

				2: begin
					//mybest_buf = mybest_buf * data_in; // fixed-point multiplication 11./5 * 11./5 = 11./5
					//MIKKO
					kTemp = mybest_buf * data_in;
					mybest_buf = kTemp[20:5];
					state = 3;
				end

				3: begin
					done_buf = 1;
				end

				default: state = 3;
			endcase
		end
	end

	assign done = done_buf;
	assign address = address_count;
	assign mybest = mybest_buf;
endmodule

/**

	TODO:
	- Check state 1 to state 2 transition, sa isang if-block lang nattrigger yung next state 
	- check blocking and non-blocking operators
	- Initial value, pakicheck if magiiba, idk bakit ganun values niyo

 */
