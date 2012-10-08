`default_nettype none			 

module ctrl_drv_servo(
	input clk,					// Clock 50 Mhz
	input rst,					// Reset
	
	input sensA,				// Sensor channel A
	input sensB,				// Sensor channel B
	input sensR,				// Sensor channel R 
	
	output h1,					// PWM Phase U Hi
	output l1,					// PWM Phase U Low
	output h2,					// PWM Phase V Hi
	output l2,					// PWM Phase V Low
	output h3,					// PWM Phase W Hi
	output l3,					// PWM Phase W Low	
	output flt_clr,				// Fault clear inverter pin
	
	input  sdo0_in,  			// ADC 0 SDO
	input  sdo1_in,				// ADC 1 SDO
	output sdi_out,				// ADC 0,1 SDI
	output sclk_out,			// ADC 0,1 SCLK
	output convst,				// ADC 0,1 CONVST	
	
	input  sdo_in_adc, 			// 8-channel ADC SDO
	output sdi_out_adc,			// 8-channel ADC SDI
	output sclk_out_adc,		// 8-channel ADC SCLK
	output convst_adc,			// 8-channel ADC CONVST	
	
	output reg [15:0] cmi_data0,// CMI data
	output reg [15:0] cmi_data1,// CMI data
	output reg [15:0] cmi_data2,// CMI data	 
	output reg [15:0] cmi_data3,// CMI data	 
	output reg cmi_direction,   // ����������� ������ cmi (1 - ��������, 0 - �����)
	
	output reg cmi_strob,		// CMI Strob

	
	input [7:0] param_addr,		// Parameter Address
	input [15:0] param_data,	// Parameter Data
	input param_strob,			// Parameter Strob

	input [31:0] task_in,  		// �������� ������� ���������� �� RS485
	input task_strob,			// ����� ����, ��� ������� ������					 
	
	output reg [31:0] task_out0, // �������� ������� ������
	output reg [31:0] task_out1, // �������� ������� ������
	output reg task_out_strob,	// ����� ����, ��� ������� ���� ����������
		
	output [7:0] led_out,		// ������ ������������ �����������
								// 0 ��� - ������
								// 1 ��� - �����
								// 2 ��� - ������
								// 3 ��� - �����

	output dc_rly,				// ����, ���������� �������� �� DC_BUS		
	output brk_rly,				// ����, ���������� ��������
	output brk_res,             // ���������� ��������� ����������		  

	input cal_btn,				// ������ ����������
	input lft_btn,				// ������ �����
	input rt_btn,	    		// ������ ������	   
	
	input end0,					// ��������� �������� ������ 0
	input end1,					// ��������� �������� ������ 1
	
	input rx_endat,  			//���� � ������� Endat
	output clk_out_endat,		//�������� ��������� Endat
	output tx_endat,			//����� �� ������ Endat
	output en_transmit_endat	//���������� ������������ �������� EnDat
	);				
	
	//��������������� ���������
	reg cmi_start_strob;		// ����� ������ ����� ���������� (������������ ��� ������� ��������� 0
	reg [15:0]cmi_period;		// ������ �������, ����� ������� �������������� ���� ����� ���������� (1 = 5.12 ���). �������� ������ ����� �� 1 ������, ��� �������� cmi_period
	reg [15:0]TaskL;	  	 	// ������ ���� �������
	reg [15:0]TaskH;	  	 	// ������� ���� �������
	reg [15:0]tl;	 	 	 	// ������ ���� �������
	reg [15:0]th;	  		 	// ������� ���� �������
	reg [15:0]phi_bias_p;	  	// ���� �������� � ����� DFOC ��� �������� � ������������� �������
	reg [15:0]phi_bias_n;	  	// ���� �������� � ����� DFOC ��� �������� � ������������� �������
	reg [14:0]stepper_amp;		// ��������� � ������� ������
	reg [5:0] cmi_mode;			// ����� ������ ����������
	
	//����� ����������� ���
	wire [15:0]p1;         //���� U
	wire [15:0]p2;         //���� V
	wire [15:0]p3;         //���� W	  
	
	wire Drive_Direction; //��� ������ ����������� �������������� �������� ���������
	wire Drive_Error;     //��� ��������� ����� ��������� h1-3, l1-3 � 0 
	wire Boot_Done;       //��� ������������, ��� ��������� ��������� ���������

	//������������ ������
	wire [31:0]Qphi;
	wire [15:0]Qomega;
	

	//������ ����
	wire [31:0] phi;
	wire [15:0] omega;
	wire [15:0] pa;
	
	wire [31:0]delta;
	assign delta = Qphi-phi;
	
	//������ ��������
	reg  [31:0]speed;    //�������� �������� � ����������� �������� ������� ��������� �� ���� ������� ����������
	
	//���������� ����� ����
	wire [11:0] Analog0;
	wire [11:0] Analog1;			   
	
	//����������
	wire [15:0]u;	 			// ����� ����������
	wire [18:0]eps;	   			// ���� ���������������
	wire [18:0]eps_h;  			// ���� ���������������
	reg [15:0]Kp0;  			// ����������� K�-0 ���������� ��� ��������������� ����� esw
	reg [15:0]Kp1;				// ����������� K�-1 ���������� ��� ��������������� ����� esw
	reg [14:0]omega_p;			// ��������, ��� ������������ ��������������� (�����������)
	reg [14:0]omega_max;		// ������������ �������� (�����������)
	reg [18:0]b_0;
	reg [18:0]b_1;
	reg [18:0]b_2;
	reg [18:0]a_1;
	reg [18:0]a_2;
	
	reg [18:0] upper;
	
	wire reg_strob;	//����� ������� ����������
	
	//������ 8-�� ���������� ���
	wire [11:0]analog_ch_0;
	wire [11:0]analog_ch_1;	
	wire [11:0]analog_ch_2;
	wire [11:0]analog_ch_3;	
	wire [11:0]analog_ch_4;
	wire [11:0]analog_ch_5;	
	wire [11:0]analog_ch_6;
	wire [11:0]analog_ch_7;	

	//�������� ������ ���������� �����
	reg FStrob;						   	
	reg [1:0]FMode; 	

	//�������� ���������� ���� ����������� ����
 	wire [11:0]DC_BUS_Level;            //������� DC BUS � ���					 
	assign DC_BUS_Level = analog_ch_7-analog_ch_6;	
	
	//����������� ������� ������� �� ��������� ��������
	wire [31:0] e0_pos;  //������ �����������
	wire [31:0] e1_pos;	//������� �����������
	
	//��������� ��������������� �������
	wire [15:0]sin_out;																			   
	reg	 [15:0]sin_freq;

	wire [15:0]sin_out_remote;																			   
	reg	 [15:0]sin_freq_remote;
	wire [15:0]my_cnt;
		
	//�������� �������� �������
	reg [1:0]TaskMode;
	//_______________________________________________________________
	//|	�������	|	������� �����			|		DFOC �����		|
	//|	0 		|�������	= TaskL			| A�������� = TaskL		|
	//|			|���������	= stepper_amp	|						|
	//|---------|---------------------------|-----------------------|
	//|	1 		|�������	= ���������		| A�������� = ���������	|
	//|			|���������	= stepper_amp	|						|
	//|---------|---------------------------|-----------------------|
	//|	2 		|�������	= sin(sin_freq)	| A�������� = sin(sin_freq)|
	//|			|���������	= stepper_amp	|						|
	//|---------|---------------------------|-----------------------|
	//|	3 (SREG)|�������	= ���������		| A�������� = ��������� |
	//|			|���������	= stepper_amp	|	�� ���� � ���������	|
	//|         |                           |   �����				| 
	//|---------|---------------------------|-----------------------|
	//												
	
	reg	[15:0] task_ch0;	//0 ����� ������� �� ������ ��������� (������� ��� �������� ������, ��������� ��� DFOC ������)
	reg	[15:0] task_ch1;	//1 ����� ������� �� ������ ��������� (��������� ��� �������� ������)
	
	always @(*)
		begin  
			case (TaskMode)
				0 : begin 
						task_ch0 <=	TaskL;
					    task_ch1 <=	TaskH;
					end
				1 : begin 
						task_ch0 <=	u;
					    task_ch1 <=	TaskH;
					end				 
				2 : begin
						task_ch0 <=	sin_out;
					    task_ch1 <=	TaskH;
					end			  
				3 : begin
						task_ch0 <=	u;
					    task_ch1 <=	TaskH;
					end			  				
			endcase	
		end			 
		
		
	
	reg r_int_rst;	//����� ����������� � ����������
	reg sin_rst;	//����� ���� � �������� ����������
	
	reg reg_tune_mode;  //���� ������ ��������� ����������, � ���� ������ ������� ������������ � ������ ������ ������ ���������� � �������� �� �� �����, � ��������� ����� ��� ����� 0
	
	//������ 
		wire left_btn;	   //������ �����
		wire right_btn;	   //������ ������
		
	//���� ������� ����������
		wire manual_control_mode; 
		
		
	reg [15:0]slave_task_data; //������� ����� �������, ������� ����� ������� �� RS485	
	
	wire [31:0] snt;
	
	assign snt = {sin_out_remote[15],sin_out_remote[15],sin_out_remote[15],sin_out_remote[15],
	sin_out_remote[15],sin_out_remote[15],sin_out_remote,10'd0}+{16'd400,16'd0};
	
	parameter def_dfoc_bias_p = 0;
	parameter def_dfoc_bias_n = 0;
	
	//��������� ������� ���������� ���������������� ����������	
	always @(posedge clk or posedge rst)
		if(rst)
			begin
				cmi_start_strob <= 0;
				cmi_period <= 50;
				Kp0 <= 2000;
				Kp1 <= 3000;
				tl <= 0;
				th <= 0;
				phi_bias_p <= def_dfoc_bias_p;	  	 
				phi_bias_n <= def_dfoc_bias_n;	  	 
				FStrob<= 1'b0;
				FMode  <= 2'b00;   
				cmi_mode <= 0;				
				TaskMode <= 1;
				r_int_rst <= 0;
				sin_rst <= 0;			
				stepper_amp <= 32000;
				omega_p <= 32767;									
				sin_freq <= 0;
				sin_freq_remote <= 0;
				omega_max <= 3000;
				reg_tune_mode <= 0;
				slave_task_data <= 0;	
				task_out0 <= 0;
				task_out1 <= 0;
				task_out_strob <= 0;	  
				upper <= 0;
				b_0 <= 0;				  
				b_1 <= 0;
				b_2 <= 0;
				a_1 <= 0;
				a_2 <= 0;
			end
		else
			begin			
				if (FStrob) 
					FStrob <= 1'b0;	
				if (r_int_rst) 
					r_int_rst <= 1'b0;				
				if (sin_rst)
					sin_rst <= 1'b0;
				if (cal_btn)
					begin
						FMode  <= 2'b01; //���� ������ ���������� ������, �� �����������
						FStrob <= 1'b1;	 
					end	
				if (cmi_start_strob)
					cmi_start_strob <= 0;	  	
				if (task_out_strob)
					task_out_strob <= 0;	  
				if ((reg_strob)&(TaskMode==3))
					begin					  									
						task_out0 <= snt;
						task_out1 <= -({16'd710,16'd0} + snt);
						task_out_strob <= 1;		//������� ������� �� RS-485
					end
				if(param_strob)
					case (param_addr)
						0:	// ����� �����, ������� ���� ����� � ����������. ����� �������� ���� ��������, ���������� ���� ����������
							begin
								cmi_start_strob <= 1;
							end
						1:	// ����� ������ ������ ����������, ���������� ������ ����������, ������� ����� ���������� �� ���������������� ����������
							begin
								cmi_mode <= param_data;
							end			
						2: // ������ �������, ����� ������� �������������� ���� ���������� (1 = 5.12 ���). �������� ������ ����� �� 1 ������, ��� �������� cmi_period
							begin
								cmi_period <= param_data;
							end
						3: // ����� ������������ ���� �������
							begin 
								FMode <= param_data[1:0];
								FStrob <= 1'b1;
							end
						4: // ������ ���� �������
							begin 
								tl <= param_data;
								//TaskL <= param_data;
							end
						5: // ������� ���� �������
							begin
								th <= param_data;
								//TaskH <= param_data;
							end
						6: // ���� �������� ������� ����������� ���� ������������ ���� �� ������� ��� �������� � +
							begin
								phi_bias_p <= param_data;
							end		   
						7: // ����������� ���������� K�_0
							begin
								Kp0 <= param_data;
							end		   
						8: // ����������� ���������� K�_1
							begin
								Kp1 <= param_data;
							end		   
						9: //�������� �������� ��������
							begin
								TaskMode <= param_data[1:0];		
								reg_tune_mode <= param_data[15];	//������� ��� - �������� ����� ��������� �����������
								if (param_data[1:0] == 1)			//� ��� ������ ���� ������ ����� ���������� 
									r_int_rst <= 1;					//�� ���������� ������������ ����� ������������ 
								else	
								if (param_data[1:0] == 2)			//� ��� ������ ���� ������ ����� ���������� 
									sin_rst <= 1;					//�� ���������� ������������ ����� ������������ 
							end			  
						10: //����������� ���������� ��������
							begin
								omega_max <= param_data[14:0];
							end								 
						11: //��������� � ������� ������
							begin
								stepper_amp <= param_data;
							end				
						12:	//�������� ��� ����������� ���������������
							begin
								omega_p <= param_data[14:0];
							end
						13:	
							begin
								sin_freq <= param_data;
							end	
							//������� ����� ������� ������
						14: begin							
								slave_task_data <= param_data;
							end
							//������� ����� ������� ������
						15: begin	
								task_out0 <= {param_data, slave_task_data};
								task_out1 <= -({16'd710,16'd0} + {param_data, slave_task_data});
								task_out_strob <= 1;		//������� ������� �� RS-485
							end			  
						16: begin
								b_0 <= {param_data,3'd0};
							end
						17: begin
								b_1 <= {param_data,3'd0};
							end	
						18: begin
								b_2 <= {param_data,3'd0};
							end
						19: begin
								a_1 <= {param_data,3'd0};
							end							
						20: begin
								a_2 <= {param_data,3'd0};
							end	 
						21: begin
							  upper <= {param_data,3'd0};
							end
						22:	
							begin
								sin_freq_remote <= param_data;
							end	
						23: // ���� �������� ������� ����������� ���� ������������ ���� �� ������� ��� �������� � -
							begin
								phi_bias_n <= param_data;
							end		   
					endcase		
				else
					if (manual_control_mode)
						begin
								tl <= phi[15:0];
								th <= phi[31:16];
						end	
			end
	
	//************������������ �������� ���������� �� ��������������� ���������*********************
	
	wire cmi_ping;								//����� �� �������� ��������� ����� ����������
	
	reg [23:0] cmi_ping_counter;
	
	always @(posedge rst or posedge clk)        
		if(rst)
			cmi_ping_counter <=	0;
		else
			if (cmi_start_strob) 				//������ ����� ����� ������������ ����� ����� ������� ������ ������ ������ ����������
				cmi_ping_counter <=	0;
			else
				if (cmi_ping_counter)
					cmi_ping_counter <= cmi_ping_counter - 1;
				else	
					cmi_ping_counter <= {cmi_period,8'd0};
					
	assign 	cmi_ping = (cmi_ping_counter == 0);
		
	reg [15:0] counter; 			//�������� ������� ����� ����������
	
	wire [12:0]endat_pos; 			//��������� ���������� �� ������� EnDat
	
	always @(posedge clk or posedge rst)
		if(rst)
			begin
				counter <= 0;					    
				cmi_data0 <= 0;
				cmi_data1 <= 0;
				cmi_data2 <= 0;
				cmi_data3 <= 0;
				cmi_strob <= 0;
				TaskL <= 0;	  	 
				TaskH <= 0;	  
				cmi_direction <= 0;
			end
		else
			begin	
				if (!reg_tune_mode)
					begin	   
						case (TaskMode)			  
							0 : begin 		   	  
								  TaskL <= tl;
								  TaskH <= th;
								end
							1 : begin 
									if((param_addr==5)|(manual_control_mode))  //��������������, ������ ����� ������� hi
									 begin
								  		TaskL <= tl;
								  		TaskH <= th;
									 end else
									if(task_strob)
										begin
											TaskL <= task_in[15:0];
											TaskH <= task_in[31:16];
										end			  									 
								end				 
							2 : begin
								  TaskL <= 0;
								  TaskH <= 0;
								end			  
							3 : begin
//								  TaskL <= {sin_out[8:0],7'd0};
//								  TaskH <= {sin_out[15],sin_out[15],sin_out[15],sin_out[15],
//								  			sin_out[15],sin_out[15],sin_out[15],sin_out[15],
//								  			sin_out[15],sin_out[15:9]};
								  TaskL <= {sin_out[4:0],11'd0};
								  TaskH <= {sin_out[15],sin_out[15],sin_out[15],sin_out[15],
								  			sin_out[15],sin_out[15:5]};
								end			  				
						endcase							  
					end	
				if(cmi_start_strob)
					begin
						counter <= param_data;		  //�������� ���-�� �����, ������� ����� ����� � ��������� � ����������
						if (reg_tune_mode)
							begin
						case (TaskMode)
							0 : begin 
								  TaskL <= 0;
								  TaskH <= 0;
								end
							1 : begin 
								  TaskL <= tl;
								  TaskH <= th;
								end				 
							2 : begin
								  TaskL <= 0;
								  TaskH <= 0;
								end			  
							3 : begin
								  TaskL <= {sin_out[9:0],6'd0};
								  TaskH <= {sin_out[15],sin_out[15],sin_out[15],sin_out[15],
								  			sin_out[15],sin_out[15],sin_out[15],sin_out[15],
								  			sin_out[15],sin_out[15],sin_out[15:10]};
								end			  				
						endcase							  
							end	
					end
				if(cmi_strob)						  //����� cmi_strob �� ���������� ����� ����� ����, ��� ��� �������
					cmi_strob <= 0;
				else								 
					if(cmi_ping)					 //���� ������ ping, �� ������� 1 ����� ����������
						if(counter != 0 )
							begin		 
								cmi_direction <= 1;                   //����������� ����� �� �������� ������
								counter <= counter - 1;
								case(cmi_mode)
									0:
										begin 
											cmi_data0 <= Analog0;		  //� ����������� �� ������ ������ ����������
											cmi_data1 <= Analog1;		  //� ���������� ��������� ������ ��������.
											cmi_data2 <= analog_ch_6;	  //� ����� ����������� ��������� cmi_strob
											cmi_data3 <= analog_ch_7;
											cmi_strob <= 1;									
										end
									1:
										begin
											cmi_data0 <= p1;
											cmi_data1 <= p2;
											cmi_data2 <= p3;
											cmi_data3 <= pa;
											cmi_strob <= 1;									
										end
									2:
										begin
											cmi_data0 <= phi[15:0];
											cmi_data1 <= phi[31:16];
											cmi_data2 <= {3'b0,endat_pos[12:0]};
											cmi_data3 <= speed[15:0];
											cmi_strob <= 1;									
										end
									3: 	begin
											cmi_data0  <=  omega[15:0];
											cmi_data1  <=  speed[15:0];
											cmi_data2  <=  task_ch0; 
											cmi_data3  <=  task_ch1; 
											cmi_strob  <=  1;		
										end	
									4: 	begin
											cmi_data0  <=  eps_h[18:3];
											cmi_data1  <=  eps[18:3];
											cmi_data2  <=  u;  
											cmi_data3  <=  speed[15:0]; 
											cmi_strob  <=  1;		
										end				  
									5:	begin 
											cmi_data0 <= speed[15:0];
											cmi_data1 <= speed[31:16];
											cmi_data2 <= phi[15:0];
											cmi_data3 <= phi[31:16];
											cmi_strob <= 1;									
										end
								endcase 					
							end else
							begin	   
								cmi_direction <= 0;   //����������� ����� �� ����� ������
								if (reg_tune_mode)
									begin
										TaskL <= 0;
										TaskH <= 0;
									end	
							end	
			end									
			
 	//********************�������****************
	
	//8-��������� ��� ����� ����������
	
	wire adc_8ch_stb;				 
	
	assign adc_8ch_stb = 1'b1; //���������� ��������� � ��� � ������������ ��������� � ���������� ������������� �� ������ 4-� �������
	
	adc_spi_conv #(.chn_str(6),.chn_end(1)) eight_channel_adc (
		.clk(clk),
		.rst(rst),
		.strob_in(adc_8ch_stb),
		.sdi_out(sdi_out_adc),
		.sdo_in(sdo_in_adc),
		.sclk_out(sclk_out_adc),
		.conv_out(convst_adc),
		.value_out0(analog_ch_0),
		.value_out1(analog_ch_1),
		.value_out2(analog_ch_2),
		.value_out3(analog_ch_3),
		.value_out4(analog_ch_4),
		.value_out5(analog_ch_5),
		.value_out6(analog_ch_6),
		.value_out7(analog_ch_7),
		.finish()
		);
	
	
	//��� �������
	wire adc_rdy;
	
	adc_spi_conv_dual DUAL_ADC (
		.clk(clk),
		.rst(rst),
		.sdi_out(sdi_out),
		.sdo0_in(sdo0_in),
		.sdo1_in(sdo1_in),
		.sclk_out(sclk_out),
		.conv_out(convst),
		.value_out0(Analog0),
		.value_out1(Analog1),
		.finish(adc_rdy)
		);	 		 		
	
	
	//������������ ������
	wire sync_rst;
	
		
	parameter sensor_zero = 0;
	
	quad_sensor_core #(
		.ZeroPHI(sensor_zero))
		quad_sensor(
		.rst(rst),
		.clk(clk),
		.cA(sensA),
		.cB(sensB),
		.cC(sensR),
		.phi(Qphi),
		.omega(Qomega),
		.phi_rdy(),
		.omega_rdy(),
		.sync_rst(sync_rst)
		);	 		
	
	
	//����		 
	//�������������� �������� � ��� � 16 ��� ��������
	wire [11:0]a0;
	wire [11:0]a1;
	
	assign a0 = Analog0-12'h800;																   
	assign a1 = Analog1-12'h800;																   
	
	wire [15:0]adcSin;
	wire [15:0]adcCos;
	
	assign adcSin={a0,4'h0};
	assign adcCos={a1,4'h0};
	
	//������ ����
	
	parameter resolver_k1h =16'h02C4;
	parameter resolver_k2h =16'h03DD;
	parameter resolver_kdth =16'h007E;


//	parameter resolver_k1h =16'h02C4;
//	parameter resolver_k2h =16'h00E2;
//	parameter resolver_kdth =16'h0229;


    wire k_rdy;

	resolver_kalman #(
		.k1h(resolver_k1h),	  //200 ���, ����������� ������� ������� 1000
		.k2h(resolver_k2h),
		.kdth(resolver_kdth))
		resolver_sensor (.rst(rst),
		.clk(clk),
		.Qphi(Qphi),
		.Qomega(Qomega),
		.adcSin(adcSin),
		.adcCos(adcCos),
		.sync_rst(sync_rst),
		.DoSensor(adc_rdy),
		.phi(phi),
		.omega(omega),
		.rdy(k_rdy),
		.my_cnt(my_cnt)
		);				
		
/*		reg [31:0] rphi;
		
		always @(posedge clk, posedge rst)
			if(rst)
				rphi <= 0;
			else
				if(adc_rdy)
					rphi <= Analog1;
		
		assign phi = rphi;
		
*/


endat_pos_packet 
Label1 (
	.rst(rst),
	.clk(clk),
	.start(cmi_ping),
	.pos(endat_pos),
	.clk_out(clk_out_endat),
	.tx(tx_endat),
	.en_transmit(en_transmit_endat),
	.rx(rx_endat),
	.rdy()
);
	
	//***************��� ����������********************
	assign Drive_Direction = 1'b0;
	
	wire [15:0]p_23;       //���� ����� ���� V ��� W � ����������� �� �������� Drive_Direction
	wire [15:0]p_32;	   //���� ����� ���� V ��� W � ����������� �� �������� Drive_Direction	 
	
	assign p_23 = (Drive_Direction) ? p3 : p2;
	assign p_32 = (Drive_Direction) ? p2 : p3;
	
	//����� ����������� ���
	wire pwm_h1;	
	wire pwm_h2;
	wire pwm_h3;
	
	wire pwm_l1;
	wire pwm_l2;
	wire pwm_l3;	 
	
	
	//���������� �������
	
	wire clk_100;
	
	//assign clk_100 = clk;
	
	DCM pwm_dcm (.CLKIN(clk), 
		.RST(1'b0),
		.CLKFX(clk_100));
	// synthesis attribute DLL_FREQUENCY_MODE of pwm_dcm is "HIGH"
	// synthesis attribute DUTY_CYCLE_CORRECTION of pwm_dcm is "TRUE"
	// synthesis attribute STARTUP_WAIT of pwm_dcm is "TRUE"
	// synthesis attribute DFS_FREQUENCY_MODE of pwm_dcm is "LOW"
	// synthesis attribute CLKFX_DIVIDE of pwm_dcm is 4
	// synthesis attribute CLKFX_MULTIPLY of pwm_dcm is 9
	// synthesis attribute CLK_FEEDBACK of pwm_dcm  is "NONE"
	// synthesis attribute CLKOUT_PHASE_SHIFT of pwm_dcm is "NONE"
	// synthesis attribute PHASE_SHIFT of pwm_dcm is 0
	// synthesis attribute clkin_period of pwm_dcm is "20.00ns"   
	
	parameter pwm_deadzone=0;
	
	//��� ��������� ���� U
	
	pwm_core_hl #(
		.pwm_deadzone(pwm_deadzone)		   //���� ����������������� � ���
		)pwm_gen_1(
		.rst(rst),
		.clk(clk_100),
		.val_in(p1),
		.h_out(pwm_h1),
		.l_out(pwm_l1),
		.pwm_ready()
		);
	
	//��� ��������� ���� V
	pwm_core_hl 
		#(
		.pwm_deadzone(pwm_deadzone)		   //���� ����������������� � ���
		) pwm_gen_2 (
		.rst(rst),
		.clk(clk_100),
		.val_in(p_23),
		.h_out(pwm_h2),
		.l_out(pwm_l2),
		.pwm_ready()
		);
	
	//��� ��������� ���� W
	pwm_core_hl 
		#(
		.pwm_deadzone(pwm_deadzone)		   //���� ����������������� � ���
		)		
		pwm_gen_3 (
		.rst(rst),
		.clk(clk_100),
		.val_in(p_32),
		.h_out(pwm_h3),
		.l_out(pwm_l3),
		.pwm_ready()
		);					 
	
	//************������ ����������*************
		
	antibounce #(					//���� ��������� ������� ������ �����
		.wCnt(12))
		anti_b_l (
		.Clk(clk),
		.Rst(rst),
		.iUnstable(lft_btn),
		.oStable(left_btn)
		);
	 
	antibounce #(					//���� ��������� ������� ������ ������
		.wCnt(12))
		anti_b_r (
		.Clk(clk),
		.Rst(rst),
		.iUnstable(rt_btn),
		.oStable(right_btn)
		);
				
	assign manual_control_mode = (left_btn | right_btn);   //���� ������ ���� �� ���� �� ������, �� ������� ��������� � ������ ����������
	
	reg [15:0] manual_arg_step;
	
	always @(*)
		begin 
			case ({left_btn,right_btn})
				2'b00 : 	manual_arg_step <= 0;
				2'b01 : 	manual_arg_step <= -16000;
				2'b10 : 	manual_arg_step <= 16000;
				2'b11 : 	manual_arg_step <= 0;
			endcase	
		end														
		
    //*************************��������� ��������� ��������*************************
	
//	always @(*)
	//	begin
	//		if(left_btn|right_btn)
	//			Drive_Error <= 0;
	//		else
	//			if(end0|end1)				
	//				Drive_Error <= 1;
	//			else				
	//				Drive_Error <= 0;
	//	end							 
	
assign Drive_Error = 0;	
		
	//***************���������� �����********************
	wire [15:0]f_p1;  //������ � ���������� ���� � ������ DFOC
	wire [15:0]f_p2;
	wire [15:0]f_p3;
	
	wire [15:0]f_Amp;
	wire [31:0]f_phi;
	
	wire [15:0]s_Amp;
	wire [15:0]s_ARG_STEP;
	
	reg [1:0]FieldControlMode; //��������� ���������� ����� ���������� �����													   
	
	//00 - ��������� ������������
	//01 - ����� ����������
	//10 - ������� �����
	//11 - ����� DFOC ���������� �����
	
	assign p1 =  ((FieldControlMode == 2'b00)&(!manual_control_mode)) ? 16'h0	:   f_p1;		   
	assign p2 =  ((FieldControlMode == 2'b00)&(!manual_control_mode)) ? 16'h0	:	f_p2;	   
	assign p3 =  ((FieldControlMode == 2'b00)&(!manual_control_mode)) ? 16'h0	:	f_p3;	   
	
	//������������ ������ ���������� �����			
	wire [1:0] NFMode;	//����� �������� ������ ���������� �����
	wire NFStrob;		//����� ��������� �������� ������ ���������� �����
	reg [1:0]LFMode;    //C����� �������� ������ ���������� �����
	wire cal_rdy;       //���� ��������� ����������
	reg  cal_start;     //����� ������ ����������
	
	assign  NFStrob = FStrob;
	assign  NFMode = FMode;
	
	always @(posedge rst or posedge clk)
		if (rst)
			begin
				FieldControlMode <= 2'b10;	
				LFMode <= 2'b00;		
				cal_start <= 0;	
			end															 
		else
			if (NFStrob)
				begin				
					if (FieldControlMode!=2'b01)
						LFMode <= FieldControlMode;		  
					else
						cal_start <= 1;						
					FieldControlMode <= NFMode;
				end	
			else
				begin 
					if 	((FieldControlMode == 2'b01)&&(cal_rdy))
						FieldControlMode <= LFMode;
					cal_start <= 0;	
				end		


//***********************���������*************************************
reg [31:0] reg_timer;	   	 // WAS 19-bit wide.
	 

parameter takt_rascheta= 200000;

always @(posedge rst or posedge clk)     //��������� ������ ������������ ������ ����������
	if(rst)
		reg_timer<=takt_rascheta;				 // ������ 1 �� BUGAGA was 50000
	else				 
		if (reg_timer)			
			reg_timer <= reg_timer - 1;
		else
			reg_timer <= takt_rascheta;
			
assign reg_strob = (reg_timer == 0);			  

//������ ��������
reg [31:0]last_phi;

wire [31:0]w_speed = phi - last_phi; //������� ����� ���������� ��������� ��������� � �������
reg was_sync_rst;

always @(posedge rst or posedge clk)    
	if(rst)
		begin
			last_phi <= 0;
			speed <= 0;				 
			was_sync_rst <= 0;
		end	
	else
		begin
			if (reg_timer == 1)				//�� ���� ���� �� ������ ������� ����������
				begin
					if(!(sync_rst|was_sync_rst))	 //���� �� ���� ������ �������, ����������� ��������
						speed <= w_speed;	
					last_phi <= phi;				 //����������� �������� �������
					was_sync_rst <= 0;				 //���� ����, ��� ��� ����� ������� ������������ � 0
				end	
			else
				if(sync_rst)					   //���� ��� ����� �������, �� ��� ����� ������������� �� ��������, � ���������, ��� �������� ����������
					was_sync_rst <= 1;
		end
		

wire [18:0]a19;		//���� 19-������� ����������
wire [18:0]b19;		//���� 19-������� ����������
wire [36:0]c19;		//����� 19-������� ����������	

wire [32:0]full_eps;  //������ �������� ���������������

assign full_eps = {TaskH[15],TaskH,TaskL} - {phi[31],phi[31:0]};

wire k_switch;		  //������������� ������������� ����������

/*assign eps = (full_eps[32]) ? 											  //������� 19-������ ��������������� ��� ������������ Kp_0
			((full_eps[31:18]==14'h3FFF) ? full_eps[18:0] : 19'h40000) : 
			((full_eps[31:18]==14'h0000) ? full_eps[18:0] : 19'h3FFFF);*/

parameter regulator_low_eps_k = 23; 
			
wire [31-(regulator_low_eps_k-1):0]az0;
wire [31-(regulator_low_eps_k-1):0]ao0;

assign az0 =  0;
assign ao0 = ~0;			
			
assign eps  = (full_eps[32]) ? 
			   ((full_eps[31:regulator_low_eps_k-1]==ao0) ? full_eps[regulator_low_eps_k-1:regulator_low_eps_k-19] : 19'h40000) ://������� 19-������ ��������������� ��� ������������ Kp_1
			   ((full_eps[31:regulator_low_eps_k-1]==az0) ? full_eps[regulator_low_eps_k-1:regulator_low_eps_k-19] : 19'h3FFFF);
			

assign k_switch = (full_eps[32]) ? 						   //������������ ���������� �������������, ����� eps ��������� ��������� � �����������
				 ((full_eps[31:18]==14'h3FFF) ? 1 : 0) :
				 ((full_eps[31:18]==14'h0000) ? 1 : 0);			

parameter regulator_hi_eps_k = 22;                         //������� ��� ����������� ����������� ���������� ��� ������������ Kp_1                                                                                                                                                                                                                                                                                                                                                                                              				 

wire [31-(regulator_hi_eps_k-1):0]az1;
wire [31-(regulator_hi_eps_k-1):0]ao1;

assign az1 =  0;
assign ao1 = ~0;

assign eps_h = (full_eps[32]) ? 
			   ((full_eps[31:regulator_hi_eps_k-1]==ao1) ? full_eps[regulator_hi_eps_k-1:regulator_hi_eps_k-19] : 19'h40000) ://������� 19-������ ��������������� ��� ������������ Kp_1
			   ((full_eps[31:regulator_hi_eps_k-1]==az1) ? full_eps[regulator_hi_eps_k-1:regulator_hi_eps_k-19] : 19'h3FFFF);
			
			
//assign a19 = (k_switch) ? eps : eps_h;  //������������ ������ ����������
//assign b19 = (k_switch) ? Kp0 : Kp1;	//������������ ������ ����������


mult19 Kp_mult (
	.a(a19),
	.b(b19),
	.c(c19)
);		  			   



wire [18:0]p_om;
assign p_om = {1'b0,omega_p,3'b000};  //���������� �������� ��������� � 19-��� (�� ��� ������, ���� ��������������� ����� eps_h)

reg [18:0]u19;

parameter regulator_k0_int = 3;    //������� ��� ����������� ����������� ���������� ��� ������������ Kp_0                                                                                                                                                                                                                                                                                                                                                                                              				 
parameter regulator_k1_int = 5;    //������� ��� ����������� ����������� ���������� ��� ������������ Kp_1                                                                                                                                                                                                                                                                                                                                                                                             				 

wire [regulator_k0_int-1:0]az2;
wire [regulator_k0_int-1:0]ao2;

wire [regulator_k1_int-1:0]az3;
wire [regulator_k1_int-1:0]ao3;

assign az2 =  0;
assign ao2 = ~0;

assign az3 =  0;
assign ao3 = ~0;	

/*
always (*)
	begin 	
		if (eps_h == 19'h40000)
			u19 <= -p_om;
		else
		if (eps_h == 19'h3FFFF)
			u19 <= p_om;
		else
		if (k_switch)
			begin 	
				if (c19[36])
					begin
						if ((c19[35:35-(regulator_k0_int-1)]==ao2)
							u19 <= c19[35-(regulator_k0_int-1):35-(regulator_k0_int-1)-18];
						else
							u19 <= 19'h40000;
					end	else
					begin 	
						if ((c19[35:35-(regulator_k0_int-1)]==az2)
							u19 <= c19[35-(regulator_k0_int-1):35-(regulator_k0_int-1)-18];
						else	
							u19 <= 19'h3FFFF;
					end					
			end else
			begin  
				if (c19[36]) 
					begin 
						if ((c19[35:35-(regulator_k1_int-1)]==ao3)
							u19 <= c19[35-(regulator_k1_int-1):35-(regulator_k1_int-1)-18];	 
						else
							u19 <= 19'h40000;
					end	else
					begin	
						if ((c19[35:35-(regulator_k1_int-1)]==az3)
							u19 <= c19[35-(regulator_k1_int-1):35-(regulator_k1_int-1)-18];
						else 
							u19 <= 19'h3FFFF;
					end
			end			
	end	
*/

/*assign u19 = (eps_h == 19'h40000) ?  -p_om :
 	        ((eps_h == 19'h3FFFF) ?   p_om : 
			((k_switch) ? 		  
		  	((c19[36]) ? ((c19[35:35-(regulator_k0_int-1)]==ao2) ? c19[35-(regulator_k0_int-1):35-(regulator_k0_int-1)-18] : 19'h40000) :	 //������������ ���������� � ������ ����, ��� Kp_0 ����� 3 ����� ����� �����,
		  			   	 ((c19[35:35-(regulator_k0_int-1)]==az2) ? c19[35-(regulator_k0_int-1):35-(regulator_k0_int-1)-18] : 19'h3FFFF)):     //� Kp_1 5 ������ ����� �����
		  	((c19[36]) ? ((c19[35:35-(regulator_k1_int-1)]==ao3) ? c19[35-(regulator_k1_int-1):35-(regulator_k1_int-1)-18] : 19'h40000) :
		  	   		     ((c19[35:35-(regulator_k1_int-1)]==az3) ? c19[35-(regulator_k1_int-1):35-(regulator_k1_int-1)-18] : 19'h3FFFF))
		 	));
*/


wire [18:0]y;
wire rg_rdy;
	
filter2nd #(
.k(10)		   //���-�� ��� ����� ����� � �������������
)
Regulator (.rst(rst),
	.clk(clk),
	.start(reg_strob),
	.x(eps_h),
	.b0(b_0),
	.b1(b_1),
	.b2(b_2),
	.a1(a_1),
	.a2(a_2),
	.a(a19),
	.b(b19),
	.c(c19),
	.mul_busy(),
	.y(y),
	.rdy(rg_rdy)
);


reg rg_rdy1;

always @(posedge clk, posedge rst)
	if(rst)
		rg_rdy1 <= 0;
	else
		rg_rdy1 <= rg_rdy;

reg [19:0] up_y;

always @(posedge clk, posedge rst)
	if(rst)
		up_y <= 0;
	else
		if(rg_rdy)
			if(y[18])
				// minus
				up_y <= {y[18],y} - {upper[18],upper};
			else // plus
				up_y <= {y[18],y} + {upper[18],upper};

always @(posedge rst or posedge clk)
	if(rst)
		u19 <= 0;
	else
		if(rg_rdy1)		  // BUGAGA was rg_rdy
			begin 
				if (eps_h == 19'h40000)			 //��������
					u19 <= -p_om;
				else
				if (eps_h == 19'h3FFFF)			 //��������
					u19 <= p_om;
				else	  
					if(up_y[19])
						begin 
							if(up_y[18])
								u19 <= up_y;
							else
								u19 <= 19'h40000;
						end else
						begin
							if(up_y[18])
								u19 <= 19'h3FFFF;
							else
								u19 <= up_y;								
						end	
										 //����� ����������
			end		
			


wire [18:0]m_om;
assign m_om = {1'b0,omega_max,3'b000};	  

wire [18:0]d_u19;
wire [18:0]u19_max;
wire [18:0]u19_res;

assign  d_u19	= (u19[18]) ? -u19-m_om : u19-m_om;
assign  u19_max = (u19[18]) ? -m_om : m_om;


assign  u19_res = (d_u19[18]) ? u19 : u19_max;
assign  u = u19_res[18:3]; 



//*************************����� ����������*********** 
 	wire [15:0] calib_amp;
	wire [15:0] calib_arg_step;
	assign s_Amp 		=	((FieldControlMode == 2'b01)|(manual_control_mode)) ? calib_amp  	   :   stepper_amp; 
	assign s_ARG_STEP	=	(manual_control_mode) ? manual_arg_step :	
						   ((FieldControlMode == 2'b01) ? calib_arg_step   :   task_ch0);
						   		   
	
						   
	assign calib_amp = 16'd32000;
	
	assign calib_arg_step = 16'd8000;
	
	assign cal_rdy = sensR;
	
//	servo_calibrator_core #(
//	.calib_speed_value(16'd16000),
//	.end_safe_interval(32'd1966080)
//	)
//	calibrator (
//	.rst(rst),
//	.clk(clk),
//	.e0(end0),
//	.e1(end1),
//	.R(sensR),
//	.start(cal_start),
//	.pos(phi),
//	.calib_speed(calib_arg_step),
//	.e0_pos(e0_pos),
//	.e1_pos(e1_pos),
//	.rdy(cal_rdy)
//	);
	

	
//*****************������� �����********************

	wire rs;				//  ����� �� �������� ����������� ����� ��������� ���� (� ������� � DFOC �����)
	reg [13:0] r_cnt;		//  ����� �� ���� ���������� �������� �� ������ ��������� ����������
	
	always @(posedge rst or posedge clk)
		if(rst) 
			r_cnt<=14'h3FFF;
		else
			r_cnt<=r_cnt-1;
	
	assign rs = (r_cnt==0);

	
	reg [31:0] p_phi;		 //�������, ���������� ������ ���� � DFOC ������, ��� ����� �������� ��� � ������� �����
	
	always @(posedge rst or posedge clk)
		if(rst)
			p_phi<=0;
		else
			begin
				if (rs)	
					p_phi <= p_phi + {s_ARG_STEP[15],s_ARG_STEP[15],s_ARG_STEP[15],s_ARG_STEP[15],
									  s_ARG_STEP[15],s_ARG_STEP[15],s_ARG_STEP[15],s_ARG_STEP[15],
									  s_ARG_STEP[15],s_ARG_STEP[15],s_ARG_STEP[15],s_ARG_STEP[15],
					                  s_ARG_STEP[15],s_ARG_STEP[15],s_ARG_STEP[15],s_ARG_STEP[15],
									  s_ARG_STEP[15:0]};
			end	
			
assign f_Amp =	(FieldControlMode == 2'b11) ? task_ch0	:   s_Amp;	//������� ����� ����������� ������� DFOC	   
assign f_phi =	(FieldControlMode == 2'b11) ? phi		:   p_phi;	//����� ������� ������� ��������� ��������� p_phi	   

//**************����� DFOC******************
	parameter dfoc_sensor_k = 16'h0178;


	dfoc_pwm_nc_core #(
		.sm_k(dfoc_sensor_k))
		Servo_DFOC (
		.rst(rst),
		.clk(clk),
		.phi(f_phi),
		.Amp(f_Amp),
		.phase_bias_p(phi_bias_p),
		.phase_bias_n(phi_bias_n),
		.start(rs),
		.p1(f_p1),
		.p2(f_p2),
		.p3(f_p3),		 
		.pa(pa),
		.rdy()
		);	
		
   //********************��������� ��������� �������� �������************
   
   reg [15:0]z0;
   
   always @(posedge rst, posedge clk)
	   if(rst)
		   z0 <= 0;
	   else    		  
		   if(sin_rst)
			   z0 <= 0;
		   else
			   if(reg_strob)
		   			z0 <= z0 + sin_freq;
   
	cordic_core_v2 #(.vec_len(9949)) 
	sin_gen_cordic (
		.reset(rst),
		.clock(clk),
		.start(rs),
		.z0(z0),
		.finish(),
		.sin(sin_out),
		.cos()
	);

	
   reg [15:0]z0_remote;
   
   always @(posedge rst, posedge clk)
	   if(rst)
		   z0_remote <= 0;
	   else    		  
		   if(sin_rst)
			   z0_remote <= 0;
		   else
			   if(reg_strob)
		   			z0_remote <= z0_remote + sin_freq_remote;
   
	cordic_core_v2 #(.vec_len(9949)) 
	sin_gen_cordic_remote (
		.reset(rst),
		.clock(clk),
		.start(rs),
		.z0(z0_remote),
		.finish(),
		.sin(sin_out_remote),
		.cos()
	);	
		
	//***********������� ������������� DC BUS****************************
	reg BootSDone; //������� �������, ���� �� ��������� ������� ������������� DC BUS
	
	assign Boot_Done = BootSDone;
	
	//�������� ���������� ������������� ��� ������ ������� ������������� DC_BUS
	wire boot_h1;	  
	wire boot_l1;
	
	wire boot_h2;
	wire boot_l2;
	
	wire boot_h3;
	wire boot_l3;
	
	//������ ������ � ��������� ��������� ������������������ ������ IRMD2214ss
	reg  p_on_start;
	wire p_on_rdy;
	
	reg  wasStrobe;	//��������� ������� ��� ��������� ������ p_on_start	
	
	reg DC_BUS_Relay; //������� ���������� ���� �� ���� �������    	
	wire [12:0]DC_BUS_Critical_Level;	//������� ���� �������� DC_BUS ������� �������� ����� ����
	
	assign dc_rly = DC_BUS_Relay;
	assign DC_BUS_Critical_Level = 12'd1500;						
	
	always @(posedge clk or posedge rst)
		if(rst)					
			begin
				BootSDone<=1'b0;
				p_on_start<=1'b0;	
				wasStrobe<=1'b0;	
				DC_BUS_Relay<=1'b0;
			end	
		else 
			if (0)//(DC_BUS_Level<DC_BUS_Critical_Level)  //���� DC_BUS ������, ����������� ������ ���������� �������������
				begin 									  //� ����� boot.  ��������� ����, ������� ����� ������ ������������������
					BootSDone	 <= 1'b0;				  //� ���� ������� ������ DC_BUS
					p_on_start	 <= 1'b0;	
					wasStrobe	 <= 1'b0;
					DC_BUS_Relay <= 1'b0;
				end	else
				begin 
					DC_BUS_Relay<=1'b1;					  //��� ������ �� ��������� �������� ����
					if(BootSDone == 0)					  //���� �� ���� ��������� ��������� ������������������
						if(p_on_rdy)	  				  //�� ���������� ������ ���������� ��������� ������������������
							BootSDone <= 1'b1;			  //����� ������, ����� ����������� ���������� � ������� �����.
						else						   
							if(!wasStrobe)
								begin
									p_on_start <= 1'b1;
									wasStrobe  <= 1'b1;
								end	else
								p_on_start <= 1'b0;
						end	
	
	
	power_on_seq_core PWR_ON_SEQUENCE (.rst(rst),		 //������ ���������� ��������� ������������������
		.clk(clk),										 //��������� IRF IRMD2214ss
		.start(p_on_start),
		.h1(boot_h1),
		.l1(boot_l1),
		.h2(boot_h2),
		.l2(boot_l2),
		.h3(boot_h3),
		.l3(boot_l3),
		.flt_clr(flt_clr),
		.rdy(p_on_rdy)
		);															   
	
	
	assign h1 = (Drive_Error) ? 1'b0 : ((BootSDone) ? pwm_h1 : boot_h1);		 
	assign l1 = (Drive_Error) ? 1'b0 : ((BootSDone) ? pwm_l1 : boot_l1);		 
	
	assign h2 = (Drive_Error) ? 1'b0 : ((BootSDone) ? pwm_h2 : boot_h2);		 
	assign l2 = (Drive_Error) ? 1'b0 : ((BootSDone) ? pwm_l2 : boot_l2);		 
	
	assign h3 = (Drive_Error) ? 1'b0 : ((BootSDone) ? pwm_h3 : boot_h3);		 
	assign l3 = (Drive_Error) ? 1'b0 : ((BootSDone) ? pwm_l3 : boot_l3);		 
	
	
	reg [2:0]reg_str;
	
	always @(posedge clk or posedge rst)
		if(rst)
			reg_str <= 0;
		else
			if(reg_strob)
				reg_str <= reg_str+1;
	
 //������������ ��������� ������� ������
 	assign led_out[0] = Drive_Error|(!BootSDone);	   
 	assign led_out[1] = wasStrobe;
	assign led_out[2] = phi[20];
	assign led_out[3] = reg_str[2];			
	
 //���� �������
 
 reg [28:0]brk_cnt;
 
 assign  brk_rly=1'b0; 
 
 //��������� �������
 
 assign brk_res = 1'b0;
 
 		  
		 
endmodule