module cmi_packet_manager(
	input rst, 	//�����
	input clk,  //�������� ���������
	
	input [15:0]cmi_timeslot_len,		//������ ���������� �����
	input cmi_generator_mode,			//����� ������ ���������� 0 - ����������, 1 - �������
	
	output marker_st_out, 				//����� ������� �������
	
	//���������� �������� ������	
	input  rx_top,						//����� RX ��������� ����� ���
	input  rx_tech,	
	output reg tx_top,			     	//����� TX ��������� ����� ���	  
	//���������� �� ����� 0
	input  rx_0,						//����� RX ��������� ����� ���
	output reg tx_0,			     	//����� TX ��������� ����� ���
	//���������� �� ����� 1
	input  rx_1,						//����� RX ��������� ����� ���
	output reg tx_1,			     	//����� TX ��������� ����� ���
	output cmi_fault,   			// ������ ��� ������ ������ �� ����������� �������� ������
	
	input [15:0]cmi_data0_self,			//0  ����� ���������� (����������� �� marker_st)
	input [15:0]cmi_data1_self,			//1  ����� ���������� (����������� �� marker_st)
	input [15:0]cmi_data2_self,			//2  ����� ���������� (����������� �� marker_st)
	input [15:0]cmi_data3_self,			//3  ����� ���������� (����������� �� marker_st)

	input  cmi_top_out_enable,		    //���������� �� �������� ������� ����
	
	output [7:0] cmi_head_in,			//��������� ���������� ������
	output [15:0]cmi_data0_in,			//���� ������ 0 ���������� ������
	output [15:0]cmi_data1_in,			//���� ������ 1 ���������� ������
	output [15:0]cmi_data2_in,	    	//���� ������ 2 ���������� ������
	output [15:0]cmi_data3_in,			//���� ������ 3 ���������� ������
	output cmi_in_st,					//����� ������� ������

	output l0_ok,  					//����������� ����� 0
	output l1_ok					//����������� ����� 1	   	
	
	);
	
parameter link_speed = 54;  //�������� �������� �� ������: 434 - 115200, 54 - 921600

//*******************���������	�������**********************
//����� TOP
wire marker_st_0;
wire [1:0]marker_type_0;

wire rx_ena_top;
wire [7:0]rx_data_top;
wire rx_ena_tech;
wire [7:0]rx_data_tech;
wire rx_ena;
wire [7:0]rx_data;	

wire cmi_received;  //����� ������� ����������. ����������� � ��� ������, ����� ����� ������. � ������� �� ������ cmi_in_st, ������� �����������, ����� ���������� ���������������

assign rx_ena = rx_ena_top | rx_ena_tech;				 	
assign rx_data = (rx_ena_top) ? rx_data_top : rx_data_tech;

cmi_recv_packet Receiver_top (
	.clk(clk),
	.rst(rst),
	.rx_ena(rx_ena),
	.rx_data(rx_data),
	.cmi_head(cmi_head_in),
	.cmi_data0(cmi_data0_in),
	.cmi_data1(cmi_data1_in),
	.cmi_data2(cmi_data2_in),
	.cmi_data3(cmi_data3_in),
	.cmi_rdy(cmi_received),
	.cmi_fault(cmi_fault),
	.marker_st(marker_st_0),
	.marker_type(marker_type_0)
);		

reg rs232_rx_pin;	  
		
rs232_rx #(
	.pWORDw(8),
	.pBitCellCntw(link_speed))
rs232_rx_top (
	.Rst(rst),
	.Clk(clk),
	.iSerial(rs232_rx_pin),
	.oRxD(rx_data_top),
	.oRxDReady(rx_ena_top)
);							  

rs232_rx #(
	.pWORDw(8),
	.pBitCellCntw(link_speed))
rs232_rx_tech (
	.Rst(rst),
	.Clk(clk),
	.iSerial(rx_tech),
	.oRxD(rx_data_tech),
	.oRxDReady(rx_ena_tech)
);
//***********************��������� ����� ������********************************		
always @(*)
	if(cmi_generator_mode)     			//���� ����� ������ �� �������� ����������, �� �������� � �� ���� � �� 0, ����� ������ �� ����
		rs232_rx_pin <= rx_0;//rx_0;// rx_top&rx_0;
	else
		rs232_rx_pin <= rx_top;	 
		
		

//*******************���������� �������*********************
wire tx_pin;
wire  [7:0]tx_data;
wire  tx_enable;	
wire tx_rdy;
wire tx_busy;

rs232_tx #(
	.pWORDw(8),
	.pBitCellCnt(link_speed))
rs232_tx_core (
	.Rst(rst),
	.Clk(clk),
	.iCode(tx_data),
	.iCodeEn(tx_enable),
	.oTxD(tx_pin),
	.oTxDReady(tx_rdy)
);					  

assign tx_busy = ~tx_rdy; 

//******************���������� ���������********************
wire tsg_tx_rdy;
wire [7:0]tsg_tx_data;
wire tsg_tx_enable;
wire tsg_tx_control;

wire tsg_marker_st;
wire [1:0]tsg_marker_type;		 

assign tsg_tx_rdy = tx_rdy;		//����� ������� ������������ �� ����� �������� ������� �� 0 �����

wire tsg_enable;
assign tsg_enable = cmi_top_out_enable&(~cmi_generator_mode);  //������ ������������ ������ � ������ ������ � ���������� ����������� � ������, ����� ��������� �������� ������ ����

cmi_timeslot_generator #(
	.T_out(0))
TimeSlot_Generator (
	.rst(rst),
	.clk(clk),
	.enable(tsg_enable),
	.width(cmi_timeslot_len),
	.tx_rdy(tsg_tx_rdy),
	.tx_data(tsg_tx_data),
	.tx_enable(tsg_tx_enable),
	.marker_st(tsg_marker_st),
	.marker_type(tsg_marker_type),
	.tx_control(tsg_tx_control),
	.send_enable()
);			

//*****************������������ �������********************								
wire [1:0]marker_type;					//��� �������	 
wire marker_st;							//����� �������

wire send_marker_st;  //����� �� �������� �������������� ��������
wire resend_marker_st;  //����� �� �������� �������������� ������������ �������

wire zero_marker;
wire resend_marker;

assign zero_marker = (marker_type==2'b00); 
assign resend_marker = (marker_type==2'b11); 

assign marker_st   = (cmi_generator_mode) ?  marker_st_0   : tsg_marker_st;
assign marker_type = (cmi_generator_mode) ?  marker_type_0 : tsg_marker_type;
assign marker_st_out = marker_st&zero_marker;    //�������� ����� - ����� � ����� 0

assign send_marker_st = (tsg_marker_st&zero_marker)|(marker_st_0&(~zero_marker)); //�������� �������������� ��� ����� � �������� ����������� �� �������� �������, � ��� ��������� �� �� ��������)
assign resend_marker_st = (tsg_marker_st&resend_marker); //�������� �������������� ������ ������ � �������� ����������� ��  ������� 2'b11


//*******************����������� �������********************
reg tx_start;
reg [7:0]tx_cmi_head;

wire [7:0]tx_send_data;
reg  [15:0]cmi_data0_send;
reg  [15:0]cmi_data1_send;
reg  [15:0]cmi_data2_send;
reg  [15:0]cmi_data3_send;
wire tx_send_enable;		 


assign tx_data   = (tsg_tx_control) ? tsg_tx_data : tx_send_data;			//�������� ���������� ��� �������� �������
assign tx_enable = (tsg_tx_control) ? tsg_tx_enable : tx_send_enable;		//�������� ���������� ��� �������� �������

cmi_send_packet tx_top_core (
	.clk(clk),
	.rst(rst),
	.start(tx_start),
	.cmi_head(tx_cmi_head),
	.cmi_data0(cmi_data0_send),
	.cmi_data1(cmi_data1_send),
	.cmi_data2(cmi_data2_send),
	.cmi_data3(cmi_data3_send),
	.tx_busy(tx_busy),
	.tx_data(tx_send_data),
	.tx_enable(tx_send_enable),
	.rdy()
);

		
//**********************������ ���������� �� �������� ���������� ���� � ������������ �������*************************
reg  [5:0]seq;					//����� ������

reg  [1:0]tx_state;	 //����� ������ ����������� (��������/�������� ����������/������������)
reg  cmi2resend;     //���� ������� ���������� ��� ������������

reg  cmi_resend;     //�����, �����������, ����� ����� ��������������

always @(posedge rst, posedge clk)
	if(rst)	  
		begin 	 
			tx_cmi_head <= 0;
			cmi_data0_send <= 0;
			cmi_data1_send <= 0;
			cmi_data2_send <= 0;
			cmi_data3_send <= 0;
			tx_start <= 0;
			seq <=0;
			tx_state <= 0;	
			cmi2resend <=0;
			cmi_resend <=0;
		end	
	else
		begin 			
			if(cmi_resend)
				cmi_resend <=0;
			if(cmi_generator_mode)
				cmi2resend <=0;
			else	
				if(cmi_received)  //���� ��� ���-�� ������ � �� �������� �� ����������� ����������, ��� ����� ���������������
					cmi2resend <=1;	 
			if(send_marker_st)			//��� ������� ������ ��������
				tx_state <= 1;			//������� ������ �����(������� ��� ������������), ���� ��� 0 ������� ���������� ������ ���������������	
			if(cmi2resend)				//���� ���� ��� ���������������
				if((~cmi_top_out_enable)|(cmi_top_out_enable&resend_marker_st)) //���� �� � ������ ������ ����������� ����������, �� ����� ��������������� � �������� ������������, ����� - ����������.
					tx_state <= 2;		
			case(tx_state)  
				0: tx_start<=0;	  		//����� ��������
				1: begin				//����� �������� ����������
					if(~resend_marker)	//������ � �������� ������������ �������� ����������
					if((cmi_generator_mode)|(cmi_top_out_enable)) //�������� ��������������, ���� ���� ������� �������� �� �������� ����������, ���� ����� �������� ���������� ���������. ����� ��������� ��������, ��� ������ �� ����������� ���������� �������� �� ��������������, �.�. ������ ������������� ������������ �������������� �������.
						begin
							seq <= seq + 1;		//���������� ������ ������
							tx_start <= 1;		//����������� ������ ������ ��������
							tx_cmi_head <= {seq,marker_type};
							cmi_data0_send <= cmi_data0_self;
							cmi_data1_send <= cmi_data1_self;
							cmi_data2_send <= cmi_data2_self;
							cmi_data3_send <= cmi_data3_self;				
						end	
						tx_state <= 0;		//������ ��������� tx_state(������� �� ������������ ��� �������� ������ �����)
				   end			
				2: begin 				//����� ������������
						tx_start <= 1;		//����������� ������ ������ ��������
						tx_cmi_head <= cmi_head_in;
						cmi_data0_send <= cmi_data0_in;
						cmi_data1_send <= cmi_data1_in;
						cmi_data2_send <= cmi_data2_in;
						cmi_data3_send <= cmi_data3_in;						
						tx_state <= 0;	//������ ��������� tx_state(������� �� ������������ ��� �������� ������ �����)							
						cmi2resend <=0; //����� �������� ������ ���������� ��������� ���������� �����������������:) 
						cmi_resend <=1; //����������� ������, �� ����� ������������
				   end						
			endcase	
		end		
		
//������������ ������ ������� ������
assign cmi_in_st = (cmi_generator_mode) ? cmi_received : cmi_resend;
		
//***********************��������� ����� ��������********************************		
always @(posedge clk, posedge rst)
	if(rst)
		begin 
			tx_top<= 1;
			tx_0  <= 1;
			tx_1  <= 1;
		end else		  
		if(cmi_generator_mode)
			begin 
				tx_top<=tx_pin;			//� ������ �������� ���������� ����� TX ������ ���������� � �����������
				tx_0<=tx_pin;
				tx_1<=1;
			end else		
			begin	
				if(cmi_top_out_enable)	 
				begin 	
					case(marker_type)
						2'b00 : begin 		 
									tx_top <= tx_pin;			//���������� ��������� � ����. ���������� ������ � �����
									if(tsg_tx_control)			//�� ����� �������� ������� ���������� ��������� � ������ 0 � 1, � ��������� ����� �� ��� �������� 1
										begin 
											tx_0 <= tx_pin;
											tx_1 <= tx_pin;
										end	else
										begin 
											tx_0 <= 1;
											tx_1 <= 1;
										end	
								end		
						2'b01 : begin 
									if(tsg_tx_control)   	//�� ����� �������� ������
								    	begin
											tx_top <= rx_0;	    //����� ���� �������������� �� ����� 1, � ���������� �� �������� ������ �� ����� 1
											tx_0 <= tx_pin;
											tx_1 <= 1;
										end
									else begin
											tx_top <= rx_0;	    //� ��������� ����� ����� ���� �������������� �� ����� 0, � ����������� ����� 0 � 1 ��������������	�� ����������� ���������											
											tx_0 <= 1;
											tx_1 <= 1;
										 end														
								end	
						2'b10 : begin 
									if(tsg_tx_control)   	//�� ����� �������� ������
								    	begin
											tx_top <= rx_1;	    //����� ���� �������������� �� ����� 1, � ���������� �� �������� ������ �� ����� 1 											
											tx_1 <= tx_pin;
											tx_0 <= 1;
										end
									else begin
											tx_top <= rx_1;	    //� ��������� ����� ����� ���� �������������� �� ����� 1, � ����������� ����� 1 � 0 ��������������	�� ����������� ���������											
											tx_0 <= 1;
											tx_1 <= 1;
										 end														
								end	
						2'b11 : begin 
									tx_top <= 1;		//�������� � ������� ���������� ������������ �������� ����
									tx_0 <= tx_pin;
									tx_1 <= tx_pin;
								end 	
					endcase
				end	else
				begin 				   
					tx_top <= 1;
					tx_0 <= tx_pin;
					tx_1 <= tx_pin;
				end	
			end	



		
//***********************��������� �������� �����********************************
assign l0_ok =rx_0;   //��� 485 ����������, � ��� (� ��������� ��������), ����� ������ �������� ����� 0
assign l1_ok =rx_1;	  //��� 485 ����������, � ��� (� ��������� ��������), ����� ������ �������� ����� 0

endmodule	