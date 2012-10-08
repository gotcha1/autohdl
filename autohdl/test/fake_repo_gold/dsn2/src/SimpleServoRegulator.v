module SimpleServoRegulator(
	input  rst,					//����������� �����
	input  clk,					//�������� ��������
	input  [31:0]position_task,	//������� �� ���������
	input  [15:0]speed_task,	//������� �� ��������
	input  [31:0]phi,			//��������� ������� ���������
	input  [15:0]omega,			//��������� ������� ��������
	input  [30:0]omega_q,		//��������� ������� �������� �� ������������� �������
	output [15:0]u,				//�������� �������� �� ���� ������������ ����(������� �� ����)
	input  get_param_st,		//����� �� �������� ������� ��������� ���������
	input  [7:0]param_index,	//��� ����������� ���������
	input  [15:0]param_data,	//�������� ����������� ���������
	output reg [15:0]out_param0,    //�������� ���������� ��������� ��� ������ � ����������
	output reg [15:0]out_param1,    //�������� ���������� ��������� ��� ���������
	output reg [15:0]out_param2,    //�������� ���������� ��������� ��� ���������
	output reg [15:0]out_param3,	//�������� ���������� ��������� ��� ���������
	input  enable,				 //���� ���������� ������� ����������
	output rdy					//���� ��������� ������� ����������
);

//***********������ ���������� ����������� ������***********************************
reg [18:0]Kp_s;	//����������� �������� ����������������� ����� ������� ��������
parameter Kp_s_initial = 0; //��������� �������� ������������ Kp_s
reg [18:0]Ki_s;	//����������� �������� ������������� ����� ������� ��������
parameter Ki_s_initial = 0; //��������� �������� ������������ Ki_s
reg [18:0]Kd_s;	//����������� �������� ����������������� ����� ������� ��������
parameter Kd_s_initial = 0; //��������� �������� ������������ Kd_s
reg int_rst_s;	//����� ������ ����������� ������� ��������		  
reg [4:0]pos_eps_b;			 //����� �������� ����  ��������������� �� ���������
parameter eps_b_initial = 25; //��������� �������� ������������ pos_eps_b
reg [18:0]Kp_p;	//����������� �������� ����������������� ����� ������� ���������
parameter Kp_p_initial = 0; //��������� �������� ������������ Kp_p
reg [18:0]Ki_p;	//����������� �������� ������������� ����� ������� ���������
parameter Ki_p_initial = 0; //��������� �������� ������������ Ki_p
reg [18:0]Kd_p;	//����������� �������� ����������������� ����� ������� ���������
parameter Kd_p_initial = 0; //��������� �������� ������������ Kd_p
reg int_rst_p;	//����� ������ ����������� ������� ���������		

reg [15:0]low_level;	//������� �� �������� �������� ������������		
reg [15:0]max_speed;	//������� �� �������� �������� ������������

parameter low_level_initial = 0; //��������� �������� ������������ Kp_pl

reg [18:0]Kp_pl;	//����������� �������� ����������������� ����� ������� ��������� (��� ����� ����������������)
parameter Kp_pl_initial = 0; //��������� �������� ������������ Kp_pl
reg [18:0]Ki_pl;	//����������� �������� ������������� ����� ������� ���������	 (��� ����� ����������������)
parameter Ki_pl_initial = 0; //��������� �������� ������������ Ki_pl
reg [18:0]Kd_pl;	//����������� �������� ����������������� ����� ������� ���������  (��� ����� ����������������)
parameter Kd_pl_initial = 0; //��������� �������� ������������ Kd_pl

reg [14:0]max_pos; //������ ������������� �������� ��������� (�� ������� 16 ������)
parameter max_pos_initial = 400;						   

reg [15:0]max_int_pos;	//������������ ���������� �� ���������
parameter  max_int_pos_initial= 100;
reg [15:0]max_int_spd;	//������������ ���������� �� ��������
parameter  max_int_spd_initial= 2000;

reg [1:0]DoPos;      //1 - �� ���������, 0 - �� ��������
reg out_switch;   //������������� �������� ���������

reg [15:0]aper_dt;									 

parameter aperiodic_dt_initial=-1; //��������� ��������  ���������� ������� ����������

//**********************************************************************************

//��������� ��������� ���������� ����������
always @(posedge rst, posedge clk)
	if(rst)
		begin 	  
			//****************������������� ����������****************
			Kp_s <= Kp_s_initial;
			Ki_s <= Ki_s_initial;
			Ki_s <= Kd_s_initial;		 
			int_rst_s <= 0;		
			pos_eps_b <= eps_b_initial;
			Kp_p <= Kp_p_initial;
			Ki_p <= Ki_p_initial;
			Ki_p <= Kd_p_initial;		 
			Kp_pl <= Kp_pl_initial;
			Ki_pl <= Ki_pl_initial;
			Ki_pl <= Kd_pl_initial;		 
			int_rst_p <= 0;		
			DoPos <= 1;		   
			out_switch <= 1;  
			low_level <= low_level_initial;	   
			max_speed <= 300;
			max_pos <= max_pos_initial;
			max_int_pos  <= max_int_pos_initial;
			max_int_spd <= max_int_spd_initial;
			aper_dt <= aperiodic_dt_initial;
			//********************************************************
		end
	else
		begin 								  
			if(int_rst_s)
				int_rst_s <= 0;
			if(int_rst_p)
				int_rst_p <= 0;
			//���������� �������� ����������
			if(get_param_st)
				case(param_index)
					0 : begin 
							if(param_data)
								int_rst_s <=1;
							else
								int_rst_p <=1;
						end
					1 :	Kp_s <= {1'b0,param_data,2'b00};
					2 : Ki_s <= {2'b00,param_data,1'b0};
					3 : Kd_s <= {2'b00,param_data,1'b0};
					4 : pos_eps_b <= param_data[4:0];
					5 :	Kp_p <= {1'b0,param_data,2'b00};
					6 : Ki_p <= {2'b00,param_data,1'b0};
					7 : Kd_p <= {2'b00,param_data,1'b0};	
					8 : DoPos <= param_data[1:0]; 
					9 : out_switch <= param_data[7:0];
					10:	Kp_pl <= {1'b0,param_data,2'b00};
					11: Ki_pl <= {2'b00,param_data,1'b0};
					12: Kd_pl <= {2'b00,param_data,1'b0};	
					13: low_level <= param_data;
					14: max_speed <= param_data;
					15: max_pos <= param_data[14:0];
					16: max_int_spd <= param_data;
					17: max_int_pos <= param_data;
					18: aper_dt <= param_data;
				endcase	
		end	
	
		
//******************���� ��������� ������� ���������� �������� � ���������**********	  
reg [18:0] timer;	 										
reg [1:0]  pos_timer;	 										
reg [3:0]  speed_timer;	 																				
wire OnTimer;

wire pos_st;		//����� ������ ������� ���������� ��������� 
wire speed_st;      //����� ������ ������� ���������� ��������

parameter takt_rascheta = 50000;

always @(posedge rst or posedge clk)              //��������� ������ ������������ ������ ���������� ���������
	if(rst)
		timer<=-1;				 
	else		
		if(enable)
			timer <= timer - 1;

wire OnSpeedTimer;
assign OnSpeedTimer = (timer[1:0] == 0);						

reg [47:0]omega_smooth_summ;
reg [30:0]omega_smooth;
//reg [32:0]omega_smooth_summ;
//reg [15:0]omega_smooth;


always @(posedge rst or posedge clk)         
	if(rst)						 
		begin
			omega_smooth_summ <=0;
			omega_smooth <= 0;
		end	
	else
		if(OnSpeedTimer)
			begin 
				if(OnTimer)
					begin 
						omega_smooth <= omega_smooth_summ[47:17];
						omega_smooth_summ <= {omega_q[30],omega_q[30],omega_q[30],omega_q[30],
											  omega_q[30],omega_q[30],omega_q[30],omega_q[30],
											  omega_q[30],omega_q[30],omega_q[30],omega_q[30],
											  omega_q[30],omega_q[30],omega_q[30],omega_q[30],
											  omega_q[30],omega_q};					
					end	else
						omega_smooth_summ <= omega_smooth_summ + {omega_q[30],omega_q[30],omega_q[30],omega_q[30],
											  					  omega_q[30],omega_q[30],omega_q[30],omega_q[30],
											  					  omega_q[30],omega_q[30],omega_q[30],omega_q[30],
																  omega_q[30],omega_q[30],omega_q[30],omega_q[30],
																  omega_q[30],omega_q};				
			end	


assign OnTimer = (timer == 0);			

always @(posedge rst or posedge clk)              //��������� ������ ������������ ������ ���������� �������� 
	if(rst)										  //(�� ������������ ����� 7 ������ ����� ������������ �������, 
		speed_timer<=4'b1111;				 	  //����������� ����� ������� ��� ���������� ���������)
	else				 
		begin 
			if(~speed_timer[3])
				speed_timer <= speed_timer - 1;
			if(OnTimer)
				speed_timer[3] <= 0;
		end	
			
assign speed_st = (speed_timer == 0);	

always @(posedge rst or posedge clk)			//��������� ������ ����������� ������ ���������� ���������
	if(rst)										//�� ������ 4 ����� ������� (��� ����� ��� ������� � 4 ����
		pos_timer <= 0;							//���� ������� ��������)
	else
		if(OnTimer)
			pos_timer <= pos_timer + 1;

assign pos_st = OnTimer;//((pos_timer == 0)&(OnTimer));

//************************���������� ����������*************************************
reg  [18:0]a;
reg  [18:0]b;
wire [36:0]c;

mult19 m19_reg (	 //19 ������ �������� ���������� mult19
	.a(a),
	.b(b),
	.c(c)
);															  
//***************************��������� ������� ���������****************************
wire [18:0]eps_p; //��������������� �� ���������
reg [31:0]p_task; //������������ �������� ���������
wire [15:0]de_pos_high; //������ ������� ����� �������� �� ��������� � ������������
wire pos_ovf;			//���� ������������ ��������� �� �����������
wire [15:0]m_pos;
assign m_pos = {1'b0,max_pos};		

assign de_pos_high = (position_task[31]) ? m_pos + position_task[31:16]  : m_pos - position_task[31:16];
assign pos_ovf = de_pos_high[15];

always @(posedge rst, posedge clk)
	if(rst)
		p_task <= 0; 
	else begin 
			if(pos_ovf)           		//���� ������� ��������� �� ������ ������ �����������
				begin 
					if(position_task[31])	//� ������� ��������� �������������,
						p_task <= -{m_pos,16'd0};	 //�� ��� ����� -������ �����������
					else
						p_task <= {m_pos,16'd0};	 //����� ��� ����� ������ �����������
				end	else
				begin 
					p_task <= position_task;		//���� ������� ��������� ������ �����������, �� ��� �� ��������
				end	
		 end
		 
//************************���������� ����������(��������)************
wire  [18:0]a_a;
wire  [18:0]b_a;
wire [36:0]c_a;

mult19 m19_a (	 //19 ������ �������� ���������� mult19
	.a(a_a),
	.b(b_a),
	.c(c_a)
);																	 
wire ap_rdy;		 
wire [18:0]ap_pos;
aperiodic_core 
aper_core (
	.rst(rst),
	.clk(clk),
	.start(pos_st),
	.x(p_task[27:9]),
	.y(ap_pos),
	.dt_T({aper_dt,2'd0}),
	.mula(a_a),
	.mulb(b_a),
	.mulc(c_a),
	.mul_busy(),
	.rdy(ap_rdy)
);		 						 

wire [31:0]ap_task;
assign ap_task = {ap_pos[18],ap_pos[18],ap_pos[18],ap_pos[18],ap_pos,9'd511};
		 
wire [17:0]abs_eps; //������ ��������������� ���������
assign abs_eps = (eps_p[18]) ? -eps_p : eps_p;		  
wire ll_switch;		//������������ �� ����������� ������� ������
assign ll_switch = (low_level>abs_eps[17:2]);


reg [18:0]Kpp;
reg [18:0]Kip;
reg [18:0]Kdp;

always @(*)			  //������������� �������������
	if(ll_switch)
		begin 
			Kpp <=Kp_pl;
			Kip <=Ki_pl;
			Kdp <=Kd_pl;
		end	else
		begin 
			Kpp <=Kp_p;
			Kip <=Ki_p;
			Kdp <=Kd_p;
		end			 

eps_saturator PositionEps (	 
	.rst(rst),
	.clk(clk),
	.a(ap_task), 
	.b(phi),
	.sbit(pos_eps_b),
	.c(eps_p)
);

wire [18:0]u_p;  	 //����� ���������� ���������
reg  [18:0]u_p_sat;   //����� ���������� ���������
wire [18:0]a_p;   //����� � ����������					  
wire [18:0]b_p;   //����� � ����������			
wire [15:0]acc_p; //���������� ������������� �����
wire [15:0]dcc_p; //���������� ����������������� �����	

PID_Regulator #(	   //��� ��������� ��������
	.k(4)
)
PositionRegulator (
	.rst(rst),
	.clk(clk),
	.start(ap_rdy),
	.e(eps_p),
	.Kp(Kpp),
	.Ki(Kip),
	.Kd(Kdp),
	.u(u_p),
	.rdy(rdy),
	.int_rst(int_rst_p),
	.a(a_p),
	.b(b_p),
	.mul_busy(),
	.c(c),
	.acc_o(acc_p),
	.dcc_o(dcc_p),
	.max_int(max_int_pos)
);


wire [18:0]u_p_abs;

assign u_p_abs = (u_p[18]) ? {3'b0,max_speed} + u_p : {3'b0,max_speed} - u_p;

always @(*)
	begin 							  
		if (u_p_abs[18]) 
			begin 				
				if(u_p[18])
					u_p_sat <= -{3'b0,max_speed};
				else
					u_p_sat <= {3'b0,max_speed};
			end else
					u_p_sat <= u_p;
	end					 
	
//***************************��������� ������� ��������*****************************
wire [18:0]u_s;   //����� ���������� ��������
wire [19:0]eps_s; //��������������� �� ��������					  
wire [18:0]a_s;   //����� � ����������					  
wire [18:0]b_s;   //����� � ����������			
wire [15:0]acc_s; //���������� ������������� �����
wire [15:0]dcc_s; //���������� ����������������� �����	 
wire [18:0]s_task;//������� ���������� �� ��������

assign s_task = (DoPos) ? u_p_sat : {speed_task[15],speed_task[15],speed_task[15],speed_task};

assign eps_s =	{s_task[18],s_task} -  omega_q[20:1]; // {omega[15],omega[15:0],3'b0};


PID_Regulator #(	   //��� ��������� ��������
	.k(5)
)
SpeedRegulator (
	.rst(rst),
	.clk(clk),
	.start(speed_st),
	.e(eps_s[19:1]),
	.Kp(Kp_s),
	.Ki(Ki_s),
	.Kd(Kd_s),
	.u(u_s),
	.rdy(),
	.int_rst(int_rst_s),
	.a(a_s),
	.b(b_s),
	.mul_busy(),
	.c(c),
	.acc_o(acc_s),
	.dcc_o(dcc_s),
	.max_int(max_int_spd)
);
//***************************�������� ������ ����������*****************************			  
reg mult_state;	//���� �� ������� � ������ ������ �������� ����������

always @(posedge rst, posedge clk)
	if(rst)
		mult_state <= 0;
	else
		case (mult_state)
			1'b0: if(speed_st) mult_state <= 1;		//0 - ��������� ���������
			1'b1: if(pos_st)   mult_state <= 0;		//1 - ��������� ��������
		endcase	

always @(*)
	if(mult_state)
		begin
			a <= a_s;
			b <= b_s;
		end	else
		begin 
			a <= a_p;
			b <= b_p;
		end	
//************************������������ ������ ����������****************************
assign u = (ll_switch) ? 0 : u_s[18:3];				   


//****************************������������ ����������*******************************

always @(*)
	case (out_switch)
		0:begin 			
			out_param0 <= eps_s[18:3];
			out_param1 <= u;
			out_param2 <= acc_s;
			out_param3 <= omega_q[19:4];
		  end	
		1:begin 			
			out_param0 <= eps_p[18:3];
			out_param1 <= u_p_sat[15:0];
			//{out_param3,out_param2} <= {ap_pos[18],ap_pos[18],ap_pos[18],ap_pos[18],ap_pos,9'd511}; //omega_q[19:4];
			//<= ap_pos[18:3];	
			out_param3 <= omega_q[19:4];
			out_param2 <= dcc_s;
		  end			  
	endcase 	
//**********************************************************************************

endmodule
	