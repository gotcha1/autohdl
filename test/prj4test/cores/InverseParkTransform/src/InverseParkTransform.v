//************************************������ ������� ��������� ������������� �����**********************************
//������ ��������� �������� �������������� �����
//��� ������ ������ ��������� ���������� mult16 ��� ����������� ���������� ���������� ���� ����� (16-���, �������� 
//� ������������� ������, 0-��� ����� �����, 15 ��� ������� �����)
//
//�����:
//	rst		- ����������� �����
//	clk		- �������� ���������
//	start	- ����� ������ �������
//	Vd		- ���������� d ������� ���������� � �������������� ����� (16-��� ��������)
//	Vq		- ���������� q ������� ���������� � �������������� ����� (16-��� ��������)
//	sin		- ����� ���� ������� ��������� �������� ���� ������, ������������ ���� ������� 
//			  (16-��� ��������, � ����. ������ 0-��� ����� �����, 15 ��� ������� �����)
//	cos		- ������� ���� ������� ��������� �������� ���� ������, ������������ ���� ������� 
//			  (16-��� ��������, � ����. ������ 0-��� ����� �����, 15 ��� ������� �����)
//	mulc	- ���� � �������� ���������� mult16 
//
//������:
//	mula	- ����� �� ������� ���������� mult16
//	mulb	- ����� �� ������� ���������� mult16				  
//  mul_busy- ���� ����, ��� ���������� �����
//	Va		- ���������� ����� ������� ���������� � �������������� ������ (16-��� ��������)
//	Vb		- ���������� ���� ������� ���������� � �������������� ������ (16-��� ��������)
//	rdy		- ���� ��������� ����������
//
//�����: ������� �.�.
//		 ������� "������� ����������" �����(��) 2009 �.
//***********************************************************************************************************************

module InverseParkTransform(
	input  rst,                  //����������� �����
	input  clk,					 //�������� ���������
	input  start,				 //����� ������ �������
	input  [15:0]Vd,			 //���������� d ������� ���� � �������������� ����� (16-��� ��������)
	input  [15:0]Vq,			 //���������� q ������� ���� � �������������� ����� (16-��� ��������)
	input  [15:0]sin,			 //����� ���� ������� ��������� �������� ���� ������, ������������ ���� �������
	input  [15:0]cos,			 //������� ���� ������� ��������� �������� ���� ������, ������������ ���� �������
	output reg [15:0]mula,		 //����� �� ������� ���������� mult16
	output reg [15:0]mulb,		 //����� �� ������� ���������� mult16
	input  [15:0]mulc,			 //���� � �������� ���������� mult16
	output mul_busy,			 //���� ����, ��� ���������� �����
	output reg [15:0]Va,		 //���������� ����� ������� ���� � �������������� ������
	output reg [15:0]Vb,         //���������� ���� ������� ���� � �������������� ������	
	output reg rdy);             //���� ��������� ����������

//typedef enum logic[4:0] {
parameter
	st_idle			= 5'b00001,
	st_muldcs		= 5'b00010,
	st_muldsn		= 5'b00100,
	st_mulqsn		= 5'b01000,
	st_mulqcs		= 5'b10000
	;//} IPState;					 
	
	reg [4:0] /*IPState*/ state;		
	
reg [15:0]s_Vq;
reg [16:0]t_Va;	
reg [15:0]t_Vb;	  
wire [16:0]t_Vb_sum;

assign t_Vb_sum = {t_Vb[15],t_Vb}+{mulc[15],mulc}; 

wire [18:0]Va_mul_3;
wire [18:0]Vb_mul_3;

assign Va_mul_3 = {t_Va[16],t_Va,1'b0}+{t_Va[16],t_Va[16],t_Va};                        //�������� Va * 3;
assign Vb_mul_3 = {t_Vb_sum[16],t_Vb_sum,1'b0}+{t_Vb_sum[16],t_Vb_sum[16],t_Vb_sum};	//�������� Vb * 3; 

reg [15:0]Va_sat;   //������������ �������� Va*3/4	   
reg [15:0]Vb_sat;	//������������ �������� Va*3/4	   

always @(*)
	begin 
		if(t_Va[16])
			begin 
				if(t_Va[15])
					Va_sat <= t_Va[15:0];
				else 
					Va_sat <= 16'h8000;
			end	else	
			begin 
				if(t_Va[15])
					Va_sat <= 16'h7FFF;
				else
					Va_sat <= t_Va[15:0];					
			end				
	end	

always @(*)
	begin 
		if(t_Vb_sum[16])
			begin 
				if(t_Vb_sum[15])
					Vb_sat <= t_Vb_sum[15:0];
				else 
					Vb_sat <= 16'h8000;
			end	else	
			begin 
				if(t_Vb_sum[15])
					Vb_sat <= 16'h7FFF;
				else
					Vb_sat <= t_Vb_sum[15:0];					
			end				
	end	
	
//always @(*)			//����������� Va � ������� �� 4
//	begin 
//		if(Va_mul_3[18])
//			begin 
//				if(Va_mul_3[17])
//					Va_sat <= Va_mul_3[17:2];
//				else
//					Va_sat <= 16'h8001;
//			end else
//			begin  
//				if(Va_mul_3[17])
//					Va_sat <= 16'h7FFF;		
//				else
//					Va_sat <= Va_mul_3[17:2];  					
//			end	
//	end				 
//	
//always @(*)			//����������� Vb � ������� �� 4
//	begin 
//		if(Vb_mul_3[18])
//			begin 
//				if(Vb_mul_3[17])
//					Vb_sat <= Vb_mul_3[17:2];
//				else
//					Vb_sat <= 16'h8001;
//			end else
//			begin  
//				if(Vb_mul_3[17])
//					Vb_sat <= 16'h7FFF;		
//				else
//					Vb_sat <= Vb_mul_3[17:2];  					
//			end	
//	end			



always @(posedge rst, posedge clk)
	if(rst)
		begin
			Va<=16'd0;
			Vb<=16'd0;
			rdy<=1'b0;	   
			mula<=16'd0;
			mulb<=16'd0;
			s_Vq<=16'd0;
			t_Va<=16'd0;
			t_Vb<=16'd0;	
			state<=st_idle;
		end else
		case (state)
		st_idle:
			begin
				if(start)
					begin
						s_Vq<=Vq;		   //��������� �������� Vq �� ����� ����������
						mula<=Vd;
						mulb<=cos;
						state<=st_muldcs;
					end
				if(rdy) rdy<=~rdy;		   //������� ���� rdy, ���� �� �����
			end 
		st_muldcs:
			begin		   
				t_Va<={mulc[15],mulc};				   //��������� Vd*cos, ��� ����� Va
				mulb<=sin;				   //�������� Vd*sin
				state<=st_muldsn;
			end
		st_muldsn:
			begin		   
				t_Vb<=mulc;				  //��������� Vd*sin, ��� ����� Vb
				mula<=s_Vq;		 		  //�������� Vq*sin
				state<=st_mulqsn;
			end		   
		st_mulqsn:
			begin
				t_Va<=t_Va-{mulc[15],mulc};		  //��������� Va=Vd*cos-Vq*sin
				mulb<=cos;				  //�������� Vq*cos
				state<=st_mulqcs;
			end		   
		st_mulqcs:
			begin	  
				Va<=Va_sat;				  //������� Va �� �����
				Vb<=Vb_sat;			      //��������� Vb=Vd*sin+Vq*cos
				rdy<=1'b1;
				state<=st_idle;
			end
		endcase	
		
assign mul_busy=(state!=st_idle);
		
endmodule	
