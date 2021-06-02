module hw(clk,rst,w_q);
  input clk , rst;
  output reg [7:0] w_q;
  reg [10:0] pc , mar , adr_in , pc_in;
  reg [13:0] data,IR;
  wire [13:0] rom_out;
  reg [2:0] ps , ns ,sel_pc;
  wire [2:0] sel_bit;
  wire [7:0] ir_out,ram_out;
  reg [7:0] alu_q,mux1_out,databus,ram_mux,bcf_mux,bsf_mux,port_b_out; //Port_b_out????????
  reg[3:0] op,stk_ptr;
  reg load_pc,load_mar ,load_ir,load_w,ram_en,sel_alu,sel_bus,load_port_b,push,pop,reset_ir;
  reg [1:0] sel_ram_mux;
  wire btfsc_btfss_skip_bit,btfss_skip_bit,btfsc_skip_bit;
  wire [10:0] stack_out,stack_in;
  wire [3:0] stk_index;
  reg [10:0] stack [15:0];
  wire [10:0] w_change,k_change;
  single_port_ram_128x8 ram(.data(databus),.addr(ir_out[6:0]),.clk(clk),.q(ram_out),.en(ram_en)); //RAM
 
  always@(adr_in) //ROM??
  begin
  case(adr_in)
              11'h0 : data = 14'h0103;
                11'h1 : data = 14'h01A5;
                11'h2 : data = 14'h3003;
                11'h3 : data = 14'h00A5;
                11'h4 : data = 14'h3000;
                11'h5 : data = 14'h3E01;
                11'h6 : data = 14'h0BA5;
                11'h7 : data = 14'h2805;
                11'h8 : data = 14'h2808;
                11'h9 : data = 14'h3400;
                11'ha : data = 14'h3400;
                default: data = 14'h0;
endcase
end
 //?????bit
assign MOVLW = {IR[13:8]==6'b11_0000};
assign ADDLW = {IR[13:8]==6'b11_1110};
assign IORLW = {IR[13:8]==6'b11_1000};
assign ANDLW = {IR[13:8]==6'b11_1001};
assign SUBLW = {IR[13:8]==6'b11_1100};
assign XORLW = {IR[13:8]==6'b11_1010};
assign CLRF = {IR[13:7]==7'b00_00011};
assign CLRW = {IR[13:2]==12'b000001000000};
assign GOTO = {IR[13:11]==3'b101};
assign ADDWF = {IR[13:8]==6'b00_0111};
assign ANDWF = {IR[13:8]==6'b00_0101};
assign COMF = {IR[13:8]==6'b00_1001};
assign DECF = {IR[13:8]==6'b00_0011};

assign DECFSZ = {IR[13:8] == 6'b001011};
assign INCFSZ = {IR[13:8] == 6'b001111};

assign INCF = {IR[13:8]==6'b00_1010};
assign IORWF = {IR[13:8]==6'b00_0100};
assign MOVF = {IR[13:8]==6'b00_1000};
assign MOVWF = {IR[13:7]==7'b00_00001};
assign SUBWF = {IR[13:8]==6'b00_0010};
assign XORWF = {IR[13:8]==6'b00_0110};
assign alu_zero = (alu_q == 0) ? 1'b1 : 1'b0;
assign BCF = {IR[13:10]==4'b0100};
assign BSF = {IR[13:10]==4'b0101};
assign sel_bit = IR[9:7];
assign rom_out = data;
assign BTFSC = {IR[13:10] == 4'b0110};
assign BTFSS = {IR[13:10] == 4'b0111};
assign btfsc_skip_bit = ram_out[IR[9:7]] == 0;
assign btfss_skip_bit = ram_out[IR[9:7]] == 1;
assign btfsc_btfss_skip_bit = (BTFSC & btfsc_skip_bit) | (BTFSS & btfss_skip_bit);
assign addr_port_b = (IR[6:0] == 7'h0d);
assign ASRF = {IR[13:8]==6'b11_0111};
assign LSLF = {IR[13:8]==6'b11_0101};
assign LSRF = {IR[13:8]==6'b11_0110};
assign RLF = {IR[13:8]==6'b00_1101};
assign RRF = {IR[13:8]==6'b00_1100};
assign SWAPF = {IR[13:8]==6'b00_1110};
assign BRA = {IR[13:9]==5'b11_001};
assign BRW = {IR[13:0]==14'b00000000001011};

assign CALL = {IR[13:11] == 3'b100};
assign RETURN = {IR[13:0] == 14'b00000000001000};
assign NOP = {IR[13:0] == 14'b00000000000000};

assign stk_index = stk_ptr + 1;
assign stack_out = stack[stk_ptr[3:0]];
assign stack_in = pc;
assign w_change = {3'b0,w_q} - 1;
assign k_change = {IR[8],IR[8],IR[8:0]} - 1;

always@(posedge clk)
begin
  if(rst)
    stk_ptr = 4'b1111;
else if(push)
  begin
  stack[stk_index[3:0]] <= stack_in;
  stk_ptr <= stk_ptr + 1;  
  end
  else if(pop)
    stk_ptr <= stk_ptr - 1;
end

 

always@(posedge clk)
begin
  if(rst) port_b_out <= 0;
  else if(load_port_b) port_b_out <= databus;
end

always@(*) //ram_mux????
begin
  case(sel_ram_mux)
    0 : ram_mux  = ram_out;
    1 : ram_mux = bcf_mux;
    2 : ram_mux = bsf_mux;
    default : ram_mux = 8'bx;
  endcase
end

always@(*) //??bcf_mux???
begin
  case(sel_bit)
    3'b000 : bcf_mux  = ram_out & 8'hFE;
    3'b001 : bcf_mux  = ram_out & 8'hFD;
    3'b010 : bcf_mux  = ram_out & 8'hFB;
    3'b011 : bcf_mux  = ram_out & 8'hE7;
    3'b100 : bcf_mux  = ram_out & 8'hEF;
    3'b101 : bcf_mux  = ram_out & 8'hDF;
    3'b110 : bcf_mux  = ram_out & 8'hBF;
    3'b111 : bcf_mux  = ram_out & 8'h7F;
  
  endcase
end

always@(*) //??bsf_mux???
begin
  case(sel_bit)
    3'b000 : bsf_mux  = ram_out | 8'h01;
    3'b001 : bsf_mux  = ram_out | 8'h02;
    3'b010 : bsf_mux  = ram_out | 8'h04;
    3'b011 : bsf_mux  = ram_out | 8'h08;
    3'b100 : bsf_mux  = ram_out | 8'h10;
    3'b101 : bsf_mux  = ram_out | 8'h20;
    3'b110 : bsf_mux  = ram_out | 8'h40;
    3'b111 : bsf_mux  = ram_out | 8'h80;
  endcase
end


 
  always@(posedge clk) //?????ns
  begin
    if(rst) ps <= 3'b000;
    else ps <= ns;
end


always@(*)
begin
  if(sel_bus)
    databus = w_q;
  else
    databus = alu_q;
end


always@(*) //??
begin
  sel_pc = 0;
  ram_en = 0;
  load_pc = 0;
  load_mar = 0;
  load_ir = 0;
  load_w = 0;
  sel_alu = 0;
  sel_bus = 0;
  sel_ram_mux = 0;
  load_port_b = 0;
  push = 0;
  reset_ir = 0;
  pop = 0;
  case(ps)
    3'b000 : begin
      ns = 3'b001;
    end
    3'b001 : begin //T1
      ns = 3'b010;
      load_mar = 1;
    end
    3'b010 : begin //T2
      ns = 3'b011;
      load_pc = 1;
    end
    3'b011 : begin //T3
      ns = 3'b100;
      load_ir = 1;
    end
    3'b100 : begin //T4
    load_mar = 1;
    sel_pc = 2'b00;
    load_pc = 1;
      if(MOVLW | ADDLW | IORLW | ANDLW | SUBLW | XORLW)
        begin
      load_w = 1;
      if(MOVLW)
        op = 0;
   else if(ADDLW)
        op = 1;
   else if(IORLW)
        op = 4;
   else if(ANDLW)
        op = 3;
    else if(SUBLW)
        op = 2;
    else if(XORLW)
        op = 5;
   end
     if(ADDWF)
     begin
       op = 1;
       sel_alu = 1;
       if(ir_out[7])
         ram_en = 1;
       else
         load_w = 1;
     end
     if(ANDWF)
     begin
       op = 3;
       sel_alu = 1;
       if(ir_out[7])
         ram_en = 1;
       else
         load_w = 1;
     end
     if(CLRF)
       begin
         op = 8;
         sel_alu = 1;
         ram_en = 1;
       end
       if(CLRW)
       begin
         op = 8;
         sel_alu = 1;
         load_w = 1;
       end
        if(COMF)
       begin
         op = 9;
         sel_alu = 1;
         ram_en = 1;
       end
        if(DECF)
       begin
         op = 7;
         sel_alu = 1;
         ram_en = 1;
       end
       if(INCF)
         begin
           op = 6;
           sel_alu = 1;
           if(ir_out[7])
             ram_en = 1;
           else
             load_w = 1;
         end
         if(IORWF)
         begin
           op = 4;
           sel_alu = 1;
           if(ir_out[7])
             ram_en = 1;
           else
             load_w = 1;
         end
         
        if(MOVWF)
         begin
         sel_bus = 1;
         if(addr_port_b)
           load_port_b = 1;
         else
           ram_en = 1;
         end
         
         if(MOVF)
         begin
             op = 0;
           sel_alu = 1;
           if(ir_out[7])
             ram_en = 1;
           else
             load_w = 1;
         end
         if(XORWF)
         begin
           op = 5;
           sel_alu = 1;
             if(ir_out[7])
             ram_en = 1;
           else
             load_w = 1;
         end
         if(SUBWF)
         begin
           op = 2;
           sel_alu = 1;
             if(ir_out[7])
             ram_en = 1;
           else
             load_w = 1;
         end
         

            
            if(BCF)
            begin
              sel_alu= 1;
              sel_ram_mux = 1;
              op = 0;
              sel_bus= 0;
              ram_en= 1;
            end  
            
            if(BSF)
              begin
              sel_alu= 1;
              sel_ram_mux = 2;
              op = 0;
              sel_bus= 0;
              ram_en= 1;
              end
              
              
              if(ASRF)
                begin
                  sel_alu = 1;
                  sel_ram_mux = 0;
                  op = 4'hA;
                  if(ir_out[7])
                    begin
                      sel_bus = 0;
                      ram_en = 1;
                    end
                  else
                    load_w = 1;
                end
                
              if(LSLF)
                begin
                  sel_alu = 1;
                  sel_ram_mux = 0;
                  op = 4'hB;
                  if(ir_out[7])
                    begin
                      sel_bus = 0;
                      ram_en = 1;
                    end
                  else
                    load_w = 1;
                end
                
              if(LSRF)
                begin
                  sel_alu = 1;
                  sel_ram_mux = 0;
                  op = 4'hC;
                  if(ir_out[7])
                    begin
                      sel_bus = 0;
                      ram_en = 1;
                    end
                  else
                    load_w = 1;
                end
                
                if(RLF)
                begin
                  sel_alu = 1;
                  sel_ram_mux = 0;
                  op = 4'hD;
                  if(ir_out[7])
                    begin
                      sel_bus = 0;
                      ram_en = 1;
                    end
                  else
                    load_w = 1;
                end
                
                if(RRF)
                begin
                  sel_alu = 1;
                  sel_ram_mux = 0;
                  op = 4'hE;
                  if(ir_out[7])
                    begin
                      sel_bus = 0;
                      ram_en = 1;
                    end
                  else
                    load_w = 1;
                end
                
                if(SWAPF)
                begin
                  sel_alu = 1;
                  sel_ram_mux = 0;
                  op = 4'hF;
                  if(ir_out[7])
                    begin
                      sel_bus = 0;
                      ram_en = 1;
                    end
                  else
                    load_w = 1;
                end
                
                if(CALL)
                  begin
                    push = 1;
                  end
                  
                
                
                    
                    if(NOP)
                      begin
                      end
                
                
   ns = 3'b101;
    end
    
    3'b101 : begin
      if(BRW)
                    begin
                      load_pc = 1;
                      sel_pc = 3'b100;
                    end
         if(BRA)
                    begin
                      load_pc = 1;
                      sel_pc = 3'b011;
                    end
      if(GOTO)
        begin
          sel_pc = 2'b01;
          load_pc = 1;
        end
        if(CALL)
          begin
             sel_pc = 2'b01;
             load_pc = 1;
          end
            if(RETURN)
                  begin
                    sel_pc = 3'b010;
                    load_pc = 1;
                    pop = 1;
                  end
      ns = 3'b110;
    end
    
    
    
    3'b110 : begin 
      load_ir = 1;
      if(BRW)
                    begin
                      reset_ir = 1;
                    end
         if(BRA)
                    begin
                      reset_ir = 1;
                    end
      if(BTFSC | BTFSS)
              begin
                if(btfsc_btfss_skip_bit == 1)
                  begin
                   reset_ir = 1;
                  end
              end
      if(INCFSZ)
            begin
            op = 6;
            sel_alu = 1; 
             if(ir_out[7])
               begin
                 ram_en = 1;
                 sel_bus = 0;
               if(alu_zero)
               begin
               reset_ir = 1;
               end  
               end
             else
               begin
               load_w = 1;
               if(alu_zero)
                  begin
                  load_pc = 1;
                  sel_pc = 0;
                  end  
               end
            end    
      
      if(DECFSZ)
           begin
           op = 7;
           sel_alu = 1;
          if(alu_zero)
             begin
              reset_ir = 1;
             end
           if(ir_out[7])
               begin
                ram_en = 1;
                sel_bus = 0;  
             end
            else  
            begin
            load_w = 1;               
            end 
          end
          
      if(GOTO)
        begin
          reset_ir = 1;
        end
         if(CALL)
          begin
             reset_ir = 1;
          end
          if(RETURN)
                  begin
                    reset_ir = 1;
                  end
      ns = 3'b100;
    end
  endcase
end

assign ir_out = IR;


always@(posedge clk)
begin
  if(rst) pc <= 11'b0000000000;
    else if(load_pc) pc<= pc_in;
  end
 
  always@(posedge clk)
begin
  if(rst) mar <= 11'b0000000000;
    else if(load_mar) mar <= pc;
  end
 
  always@(posedge clk)
begin
  adr_in <= mar;
  end

always@(posedge clk)
begin
  if(reset_ir) IR <= 14'b0000000000000;
    else if(load_ir) IR<= rom_out;
  end
 
  always@(posedge clk)
begin
  if(load_w) w_q <= alu_q;
  end
 
 
  always@(*) //PC???
  begin
    if(sel_pc == 3'b001)
      pc_in = ir_out;
    else if(sel_pc == 3'b000)
      pc_in = pc + 1;
    else if(sel_pc == 3'b010)
      pc_in = stack_out;
    else if(sel_pc == 3'b011)
      pc_in = pc + k_change;
    else if(sel_pc == 3'b100)
      pc_in = pc + w_change; 
  end
 
  always@(*) //ALU???
  begin
    if(sel_alu)
      mux1_out = ram_mux;
    else
      mux1_out = ir_out;
  end
 
 
 
  always@(*) //ALU
  begin
    case(op)
      4'h0 : alu_q = mux1_out;
      4'h1 : alu_q = mux1_out + w_q;
      4'h2 : alu_q = mux1_out - w_q;
      4'h3 : alu_q = mux1_out & w_q;
      4'h4 : alu_q = mux1_out | w_q;
      4'h5 : alu_q = mux1_out ^ w_q;
      4'h6 : alu_q = mux1_out + 1;
      4'h7 : alu_q = mux1_out - 1;
      4'h8 : alu_q = 0;
      4'h9 : alu_q = ~mux1_out;
      4'hA : alu_q = {mux1_out[7], mux1_out[7:1]};
      4'hB : alu_q = {mux1_out[6:0], 1'b0};
      4'hC : alu_q = {1'b0, mux1_out[7:1]};
      4'hD : alu_q = {mux1_out[6:0],mux1_out[7]};
      4'hE : alu_q = {mux1_out[0],mux1_out[7:1]};
      4'hF : alu_q = {mux1_out[3:0],mux1_out[7:4]};
      default : alu_q = mux1_out + w_q;
      endcase
      end
   


endmodule



