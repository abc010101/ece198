`timescale 1ns/1ps
//`define NID_BASEADDR

module qtupdate(clk, nrst, start, nID, battStat, qVal, cID, sinkID, wr, data, addr);
	
	input clk, nrst, start;
	input [15:0] nID, battStat, qVal, cID, sinkID, data_in;
	output wr;
	output [15:0] addr, data;

	/*
	STATE
	0 = wait
	1 = write nID
	2 = write battStat
	3 = write qVal
	4 = write cID
	5 = write sinkID
	6 = check if Neighbor exists
	7 = write worstHops
	*/

	reg reinit; //CHECK!!!!!!!!!
	reg [2:0] state;
	reg count = 1'b1;
	reg [5:0] numNeighbors;
	reg [15:0] nIDPtr, battStatPtr, qValPtr, cIDPtr, sinkIDPtr;
	reg [15:0] nIDCheck, battStatCheck, qValCheck, cIDCheck, sinkIDCheck;
	reg [15:0] nIDBuf, battStatBuf, qValBuf, cIDBuf, sinkIDBuf;
	reg [15:0] addrbuf, databuf, data_inbuf;
	reg wrbuf, found;

	//DATA IN BUFFER?
	assign data_in = data_inbuf;

	//SAVE INPUT
	always @(posedge start) begin

		//LOAD VALUES TO INPUT BUFFER
		nIDBuf <= nID;
		battStatBuf <= battStat;
		qValBuf <= qVal;
		cIDBuf <= cID;
		sinkIDBuf <= sinkID;

		//DISABLE WRITE TO MEM
		wrbuf <= 1'd0;

		//SET COUNTER, FOR SEARCHING NID MATCH
		count <= numNeighbors;
		addrbuf <= nIDPtr;
		nIDCheck <= nIDPtr;
		battStatCheck <= battStatPtr;
		qValCheck <= qValPtr;
		cIDCheck <= cIDPtr;
		sinkIDCheck <= sinkIDPtr;
		found <= 1'd0;

		//TRIGGER FSM STATE 6
		if (state == 0) begin
			state <= 6;
		end
		//else
		//	state <= state;
	end

	//OUTPUT BUF
	assign wr = wrbuf;
	assign addr = addrbuf;
	assign data = databuf;

	always @(posedge clk or negedge nrst) begin
		if (!nrst) begin
			addrbuf <= 0;
			databuf <= 0;
			wrbuf <= 0;
			numNeighbors <= 0;
		end
		else begin
			case(state)
				3'd1: begin
					if(count==1'b1) begin
						//LOAD NID TO DATA
						databuf <= nIDBuf;

						//IF FOUND, LOAD LAST PTR, ELSE LOAD FOUND PTR
						if(found == 1'd0)
							addrbuf <= nIDPtr;
						else
							addrbuf <= nIDCheck;

						//COUNTER DECREMENT
						count <= 0;
					end
					else begin
						//UPDATE LAST PTR
						if(found == 1'd0)
							nIDPtr <= nIDPtr + 2;

						//NEXT STATE, RESET COUNTER
						count <= 1;
						state <= 2;
					end 
				end

				3'd2: begin
					if(count==1'b1) begin
						//LOAD BATTSTAT TO DATA
						databuf <= battStatBuf;

						//IF FOUND, LOAD LAST PTR, ELSE LOAD FOUND PTR
						if(found == 1'd0)
							addrbuf <= battStatPtr;
						else
							addrbuf <= battStatCheck;

						//COUNTER DECREMENT
						count <= 0;
					end
					else begin
						//UPDATE LAST PTR
						if(found == 1'd0)
							battStatPtr <= battStatPtr + 2;

						//NEXT STATE, RESET COUNTER
						count <= 1;
						state <= 3;
					end 
				end				

				3'd3: begin
					if(count==1'b1) begin
						//LOAD QVAL TO DATA
						databuf <= qValBuf;

						//IF FOUND, LOAD LAST PTR, ELSE LOAD FOUND PTR
						if(found == 1'd0)
							addrbuf <= qValPtr;
						else
							addrbuf <= qValCheck;

						//COUNTER DECREMENT
						count <= 0;
					end
					else begin
						//UPDATE LAST PTR
						if(found == 1'd0)
							qValPtr <= qValPtr + 2;

						//NEXT STATE, RESET COUNTER
						count <= 1;
						state <= 2;
					end 
				end

				3'd4: begin
					if(count==1'b1) begin
						//LOAD CID TO DATA
						databuf <= cIDBuf;

						//IF FOUND, LOAD LAST PTR, ELSE LOAD FOUND PTR
						if(found == 1'd0)
							addrbuf <= cIDPtr;
						else
							addrbuf <= cIDCheck;

						//COUNTER DECREMENT
						count <= 0;
					end
					else begin
						//UPDATE LAST PTR
						if(found == 1'd0)
							cIDPtr <= cIDPtr + 2;

						//NEXT STATE, RESET COUNTER
						count <= 1;
						state <= 2;
					end 
				end

				3'd5: begin
					if(count==1'b1) begin
						//LOAD SINKID TO DATA
						databuf <= sinkIDBuf;

						//IF FOUND, LOAD LAST PTR, ELSE LOAD FOUND PTR
						if(found == 1'd0)
							addrbuf <= sinkIDPtr;
						else
							addrbuf <= sinkIDCheck;

						//COUNTER DECREMENT
						count <= 0;
					end
					else begin
						//UPDATE LAST PTR
						if(found == 1'd0)
							sinkIDPtr <= sinkIDPtr + 2;

						//NEXT STATE, RESET COUNTER
						count <= 1;
						state <= 2;
					end 
				end

				3'd6: begin
					if(count != 0) begin
						//UPDATE FOR NEXT ITERATION
						count <= count - 1;
						addrbuf <= nIDCheck;
						nIDCheck <= nIDCheck - 2;
						battStatCheck <= battStatCheck - 2;
						qValCheck <= qValCheck - 2;
						cIDCheck <= cIDCheck - 2;
						sinkIDCheck <= sinkIDCheck - 2;

						//CHECK IF SAME NID
						if (data_inbuf == nIDBuf) begin
							//FOUND!!!!
							//SET NEXT STATE
							state <= 3'd1;
							count <= 1'd1;
							wrbuf <= 1'd1;

							//SET FOUND FLAG
							found <= 1'd1;
						end
						else
							state <= 3'd6;
					end
					else begin
						//NEXT STATE, ENABLE WRITE
						wrbuf <= 1'd1;
						state <= 3'd1;
					end
				end
				//3'd7
				default: begin
					if(start != 1)
						state <= 0;
				end
			endcase
		end
	end

endmodule


/*******************************

def learnCosts(fsourceID, fbatteryStat, fValue, fclusterID, _routingTable):
	reinit = 0
	//NOT IMPLEMENTED, UNSIGNED INT
	if ((fbatteryStat < 0) or (fValue < 0) or (fsourceID < 0)):
		return reinit
	
	//NO REINIT UPDATE IMPLEMENTED

	found = 0
	for n in range(len(_routingTable.neighbors)):
		if (_routingTable.neighbors[n].neighborID == fsourceID):
			found = 1

			//WHAT PURPOSE?
			_routingTable.neighbors[n].sinkID = _routingTable.knownSinks

			_routingTable.neighbors[n].batteryStat = fbatteryStat
			if (_routingTable.neighbors[n].qValue < fValue):
				reinit = 1
			_routingTable.neighbors[n].qValue = fValue
			break

			//CID IS STILL "UPDATED" WHEN FOUND (SAME VALUE)

	if (found):
		return reinit

	newNeighbor = neighbors()
	newNeighbor.neighborID = fsourceID
	newNeighbor.batteryStat = fbatteryStat
	newNeighbor.qValue = fValue
	newNeighbor.clusterID = fclusterID
	newNeighbor.sinkID = _routingTable.knownSinks
	_routingTable.neighbors.append(newNeighbor)
	return reinit

********************************/