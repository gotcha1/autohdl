//***************************������ ��������� ������ � ����-�������������� ������������ ��������*********************
//�� ���� �������� width*3 ���. �� ������� ������� 3*width ��� ����� ���������						  
//
//������� �.�. ������� "�������� ����������" �����, 2010 �.
//*******************************************************************************************************************

module serial_neuron_core
	#(
	parameter N=2,			//����� ������
	parameter width=8,		//����� ��� ������� ��������
	parameter skip_width = log2(width),																		   
	parameter skip_size = width 	//���� ������������ �� ����� ������������� �������
	)(								//�� ��������� ���������� ������� width �����. �� ���� ��� ���-�� ��� ������� ����� + 1.
		input rst,				//����������� �����
		input clk,				//�������� ���������
		input start,			//���� ������ �������
		input [N-1:0]inp,		//������� ��������
		input [N-1:0]w,			//������������ �����
		output reg [2*width-skip_size-1:0]out, //�������� ��������
		output reg rdy				//���� ����, ��� ���������� ��������
	);		   

function integer log2;			//������� ��������� ��������� �� ��������� 2
  input integer value;
  begin
    for (log2=0; value>0; log2=log2+1)
      value = value>>1;
  end
endfunction	
	
	
wire [N-1:0]m_out;  //����� ����������� �� ��� ����� ���������	

//���������� ����������� �� ���
generate	
	genvar i;
	for (i = 0; i<N; i=i+1)
	begin: WeightMult
		serial_mult #(
			.N(width))
		WSerialMult (
			.rst(rst),
			.clk(clk),
			.start(start),
			.a(inp[i]),
			.b(w[i]),
			.c(m_out[i]),
			.process(),
			.rdy()
		);			 
	end		 
endgenerate	 		

reg start_sum;	 //����� ������ ��������� - ����������� �� ���� ����� ������ �����������. �.�. ������ ���
				 //�� ������ ����������� ��������� ����� 1 ���� ����� ������ ���������
always @(posedge rst, posedge clk)
	if(rst)
		start_sum <= 0;
	else
		start_sum <= start;
		
wire s_out;	//����� ���������
		
//���������� N ��������� ������������� ���������		
serial_summ_n #(  
	.N(N))
InputSum (
	.rst(rst),
	.clk(clk),
	.start(start_sum),
	.sumand(m_out),
	.result(s_out),
	.ovf()
);			   


wire x2_out; 	//����� x^2
wire  start_x2;  //����� ������� ���������� x^2
reg  [skip_width:0]skip_count;  //���-�� ����� ������� ���� ����������, ���� ���������� ������� ����� �����

always @(posedge rst, posedge clk) //���������� ����������� �� ��������� ����� ����� ���������(�.�. � ������ �������� ����� �����)
	if(rst)		
		skip_count <= -1;
	else	
		begin
			if(start_sum)				//���� ������ ����� �������, �� ������������� ����� ��� ������� ���� ����������
				skip_count <= skip_size;
			if(~skip_count[skip_width])	 //���� skip_count ������������� �� �������� 1	
				skip_count <= skip_count - 1; 	//�.�. ���� skip_size = 1, �� ��� ������� start_sum, skip_count ���������� ������ 1
		end										//����� 1 ���� �� ����� 1,(�.�. ���� ���� ����� ��������). ����� 2 ����� �� ����� ������ 0
												//� ����� ����������� ����� start_x2, ��� ��� ����������� �� ������ ����� �� ������ ���������
assign start_x2 = (skip_count == 0);		
		
serial_mult #(	//���������� x^2
	.N(width))
	x2_mult (
	.rst(rst),
	.clk(clk),
	.start(start_x2),
	.a(s_out),
	.b(s_out),
	.c(x2_out),
	.process(),
	.rdy()
);			 

wire x3_out; 	//����� x^2
reg  start_x3;  //����� ������� ���������� x^2
reg  z_x;		//�-����������� �� 1 ����

always @(posedge rst, posedge clk) //���������� ����������� �� ��������� ����� ����� ���������(�.�. � ������ �������� ����� �����)
	if(rst)
		start_x3 <= 0;
	else
		start_x3 <= start_x2;

always @(posedge rst, posedge clk)	//����������� x �� 1 ����
	if(rst)
		z_x <= 0;
	else
		z_x <= s_out;
		
serial_mult #(					     //���������� ���������� � x^3
	.N(width))
	x3_mult (
	.rst(rst),
	.clk(clk),
	.start(start_x3),
	.a(z_x),
	.b(x2_out),
	.c(x3_out),
	.process(),
	.rdy()
);			 

wire x15;

serial_summ one_and_half_x_sum (	//��������� ����������� 1.5x. �.�. �� ���������� �� ����� ��� ����� ������� ������ ������� width ��� 
	.rst(rst),						//����� �� ����������� �� ��� ������, ����� s_out ��� ����������,� z_x ��� ���. �.�. ���� � ������ 2 ��������
	.clk(clk),						//�� ����� �� ����� 2*width+1 ��� ��������� �� ���������
	.a(z_x),
	.b(s_out),
	.start(start_x3),
	.c(x15),
	.ovf(ovf)
);		 

reg z_x15;	//1.5 x ����������� �� 1 ����. �������� ��� ������, ��� x^3/2 �������� ������ �� ��������� ���� (�� �.�. 1 ��� x3 �� ������� ��������)
			//��� ���� � ����� � ���, ��� ���������� ����� 2*width ��� ������ ��� ��������� ���� - ���������, �� �������� �� ��, ��� ������� ���
			//x^3/2 ����� ������������ �����, ��� �� ����������:)
			
reg pr_start_subs; //�.�. start_subs �������� �� 2 ����� ������������ start_x3(���� ������ �������� �� ������� ���� x^2), �� ��� ����� �������������� �������� �� ����			
reg start_subs;    //����� ������� ��������� ����������

always @(posedge rst, posedge clk)
	if(rst)
		z_x15 <= 0;
	else
		z_x15 <= x15;
		
always @(posedge rst, posedge clk)
	if(rst)
		begin 
			pr_start_subs <= 0;
			start_subs <= 0;
		end else
		begin 				
			pr_start_subs <= start_x3;  		//������������ ������ ������� ���������� ��������� ������ startx3 �� ��� �����
			start_subs <= pr_start_subs;
		end	
		
wire non_sat_out;					  //����� �������, �� ������������ �� -1 �� 1		
		
serial_subs final_substract (	      //�������� ���������, ����������� 1.5x-0.5x^3
	.rst(rst),						
	.clk(clk),						
	.a(z_x15),
	.b(x3_out),
	.start(start_subs),
	.c(non_sat_out),
	.ovf()
);		 

//������������ ������	
parameter max_out_buf= 3*width-skip_size-1;	//������������ ������ ��������� �������

reg [max_out_buf:0]out_buf; //������ � ������� ������������ �����
reg out_rdy;			  //���� ����, ��� ��� ���� ��������� ����� ������

reg last_bit;			//���� ����, ��� ������ ��������� ���

always @(posedge rst, posedge clk)
	if(rst)		  
		begin 
			{out_buf,out_rdy} <= 1;
			last_bit <= 0;
		end	
	else
		if(start_subs)							   
			begin 
				{out_buf[max_out_buf-1:0],out_rdy} <= 0; //�������� ������� ������
				out_buf[max_out_buf] <= 1;			 //���������� � ������� ��� 1, ��� ����, ����� ����� ��� ��������� � out_rdy �� �����, ��� ���� ���������
				last_bit <= 0;
			end	
		else		 
			if(~out_rdy)
				begin 
        			{out_buf,out_rdy} <= {non_sat_out,out_buf};  //�� ������ ����� �������� ��������� ��� ������ ���������� � out_buf
															//��� ������ ���������� � ���� � ����� ������ ������� ��������� � out_rdy
															//����� ������� ��� ��� ���� ���������� ��������.						 
					if(out_buf[0])    	//�� ���� �� ����� ���������� ��������� ���. ��� ��������, ��� �� ���������� ������ out_buf �������� ���������
						last_bit <= 1;
					else
						last_bit <= 0;
				end else
					last_bit <= 0;
															

wire comp_1;  //����� ����������� ������ ��������  1
wire comp_m1; //����� ����������� ������ �������� -1

reg  gen_1;	  //��������� ��� ������� ��� �����������  1
reg  gen_m1;  //��������� ��� ������� ��� ����������� -1	

parameter gen_width = log2(3*width-skip_size)+1;  //������ �������� ��� ������������ �������� ������																		   
parameter gen_chng_bit = 2*width-skip_size+1;	//�������� �������� �� �������� �� ������ �������� gen_1 � gen_m1(�.�. ����� ���� �������� �������� �� ����� �������� ����)
												//�������� �����������
reg [gen_width:0]gen_counter; //C������ �����

always @(posedge rst, posedge clk)
	if(rst)
		  gen_counter <= -1;
	else begin 
			if(start_x2)                  		//���������� � �������� ����������� �������� �������� ������ �������� �����. ��� ���� � ������ start_x2 gen_1 � gen_m1 ������ �������� ���������� �� ������ ��� ����� ����������� ������������ �����(�� �������� �� ��������� 0))
				gen_counter <= 3*width-skip_size-2;	//�������� -2 �������� �����������. ������ ��������� �� �������� ������� ����, ���� � ������ ������������ ���������� ��� ������� ��� ����� 0
			if(~gen_counter[gen_width])			//���� ���� ���� ������� ����� �������� ������.
				gen_counter <= gen_counter - 1;
		 end	
		 
always @(posedge rst, posedge clk)
	if(rst)
		begin 
			gen_1 <= 1;							//�������������� ������� ��� +1
			gen_m1 <= 0;						//�������������� ������� ��� -1
		end	else
		begin		   
			if(~gen_counter[gen_width])        	//���� ������� �������
				begin 
					if(gen_counter[gen_width-1:0]==0) //���� ������� ����� 0, �� �������������� ���������� ���������� ������
						begin 						  //��� ��� ������ ��� �������� ����� � ������ ���������� ������� start_x2
							gen_1  <= 1;
							gen_m1 <= 0;
						end	else
					if(gen_counter[gen_width-1:0]==gen_chng_bit)	//����� ���� ��� �������� ��� ������� ���� �������� ���������� ��������
						begin 
							gen_1  <= 0;
							gen_m1 <= 1;
						end	
						
				end	
		end	
			

serial_subs x_comparator_1(	//���������� ������� x � 1      
	.rst(rst),						
	.clk(clk),						
	.a(s_out),
	.b(gen_1),
	.start(start_x2),
	.c(comp_1),
	.ovf()
);		 

serial_subs x_comparator_m1( //���������� ������� x � -1      
	.rst(rst),						
	.clk(clk),						
	.a(s_out),
	.b(gen_m1),
	.start(start_x2),
	.c(comp_m1),
	.ovf()
);		 

reg [1:0]x_sat_state;     //��������� �������� ����������� ������ ������� ����������� �� 1 ���� 																 																
reg [1:0]x_sat_state_z;   //��������� �������� ����������� ������ ������� ����������� �� 2 ����
reg [1:0]x_sat_state_2z;  //��������� �������� ����������� ������ ������� ����������� �� 3 ���� 																
//�������� ����� ��� ����, ����� ����������� � ��������� ����� �� ������ ������������� �������� �������� ����� � ������������(�.�. �� ����� ������ ���� �� ������������ �����)
//2'b10 ���� ���������� -1
//2'b00 �� ���� ������������
//2'b01 ���� ���������� +1	

always @(posedge rst, posedge clk)
	if(rst)
		x_sat_state <= 2'b00;
	else
		x_sat_state <= {comp_m1,~comp_1};  //���� comp_m1 = 1(��� ���������� �����) , ������ �������� x-(-1) ������������, ������ x <- 1. �.�. ����� ������� ������������ �� -1
		//���� comp_1  = 0(��� ���������� �����) , ������ �������� x-(1)  �������������, ������ x > 1. �.�. ����� ������� ������������ ��  1

always @(posedge rst, posedge clk)		//�������� x_sat_state �� ��a �����
	if(rst)
		begin 
			x_sat_state_z  <= 2'b00;
			x_sat_state_2z <= 2'b00;
		end	else
		begin 
			x_sat_state_z  <= x_sat_state;
			x_sat_state_2z <= x_sat_state_z;
		end										 
		
		
//����������� ��������� ��������		
always @(posedge rst, posedge clk)
	if(rst)
		out <= 0;
	else				 
		if(last_bit)
			case (x_sat_state_2z)	
				2'b00 : out <= out_buf[2*width-skip_size-1:0];	//���� x ��������� � ��������� [-1 1], �� ����� ����� ������ ������������� �������
				2'b01 : begin 									//���� x > 1 , �� ����� ����� 1
							out[2*width-skip_size-1:skip_size-1]   <=  0;	//�.� ������� ���� ����� 0
							out[skip_size-2:0] <= -1;						//� ��� ������� ����� 1
						end
				2'b10 : begin 									//���� x < -1 , �� ����� ����� -1
							out[2*width-skip_size-1:skip_size-1]   <= -1; //�.� ������� ���� ����� 1
							out[skip_size-2:0] <= 0;					  //� ��� ������� ����� 0
						end								   
				2'b11 :  out[2*width-skip_size-1:0] <= 0; //� ������ x<-1 � x>1 ����� ����� 0, �.�. ��� ���������� ���������������� ������ ������ �� ������
				default: out[2*width-skip_size-1:0] <= 0; //�� ���� ��������� ������� (���� x � z ��������� ����� ����� ����� 0)
		    endcase
			
//���� ���������� - �� ���� ���� last_bit ��������� �� ������� �� ����			
always @(posedge rst, posedge clk)
	if(rst)
		rdy <=0;
	else
		rdy <= last_bit;
		
endmodule