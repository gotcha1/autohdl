`default_nettype none
module ctrl_v2_kiortest
    (
    // Global Inputs
    
    input	clk_in,	// Clock 50 Mhz
    input	rst_in, // Reset Active High
    
    // LITTLE-USB Serial Interface
    
    input	usb_rx_in,	// LITLE_USB Receiver
    output	usb_tx_out,	// LITTLE_USB Tranceiver
    
    // SWITCH BOX 
    
    input	[1:0]	box_in, // Box input signals
    output	[1:0]	box_out,// Box multiplexers signals
    
    // Lyminaries ARM interface
    
    output	uart1_tx_out,	// UART1 Transmitter
    input	uart1_rx_in,	// UART1 Receiver
    output	uart2_tx_out,	// UART2 Transmitter
    input	uart2_rx_in,	// UART2 Receiver
    
    // ===> Control Interface #1
    
    //  1.1 DAC
    
    output	dac1_load_out,	// LOAD signal
    output	dac1_clk_out,	// CLK signal
    output	dac1_sdi_out,	// SDI signal
    
    // 1.2 DISCRETTE OUTPUTS
    
    output	[4:0] ctrl1_out,
    
    // 1.3 RS485 Interface
    
    output	rs485_tx1_out,	// Transmitter
    output	rs485_de1_out,	// TX_ENABLE
    input	rs485_rx1_in,	// Receiver
    
    // ===> Control Interface #2
    
    //  2.1 DAC
    
    output	dac2_load_out,	// LOAD signal
    output	dac2_clk_out,	// CLK signal
    output	dac2_sdi_out,	// SDI signal
    
    // 2.2 DISCRETTE OUTPUTS
    
    output	[4:0] ctrl2_out,
    
    // 2.3 RS485 Interface
    
    output	rs485_tx2_out,	// Transmitter
    output	rs485_de2_out,	// TX_ENABLE Active High
    input	rs485_rx2_in,	// Receiver
    
    // ===> RS422 Sensor Interfaces
    
    // Channel #1
    
    input rs422_rx1_in,		// Receiver
    
    // Channel #2
    
    input rs422_rx2_in,		// Receiver
    
    // Channel #3
    
    input 	rs422_rx3_in,	// Receiver
    output	rs422_tx3_out,	// Transmitter
    output	rs422_de3_out,	// TX_Enable
    
    // Channel #4
    
    input 	rs422_rx4_in,	// Receiver
    output	rs422_tx4_out,	// Transmitter
    output	rs422_de4_out,	// TX_Enable
    
    // Channel #5
    
    input rs422_rx5_in,		// Receiver
    
    // Channel #6
    
    input rs422_rx6_in,		// Receiver
    
    // Channel #7
    
    input 	rs422_rx7_in,	// Receiver
    output	rs422_tx7_out,	// Transmitter
    output	rs422_de7_out,	// TX_Enable
    
    // Channel #8
    
    input 	rs422_rx8_in,	// Receiver
    output	rs422_tx8_out,	// Transmitter
    output	rs422_de8_out,	// TX_Enable
    
    // ===> RS422 External Interfaces
    
    // Channel #1
    
    input 	rs422_ext_rx1_in,	// Receiver
    output	rs422_ext_tx1_out,	// Transmitter
    output	rs422_ext_de1_out,	// TX_Enable
    
    // Channel #2
    
    input 	rs422_ext_rx2_in,	// Receiver
    output	rs422_ext_tx2_out,	// Transmitter
    output	rs422_ext_de2_out,	// TX_Enable
    
    // Channel #3
    
    input rs422_ext_rx3_in,		// Receiver
    
    // Channel #4
    
    input rs422_ext_rx4_in,		// Receiver
    
    // Digital inputs General Purpose
    
    input	[23:0]	dig_in,		// 
    
    // Digital outputs General Purpose
    
    output	[20:0]	dig_out,	//
    
    // Solid state outputs General Purpose
    
    output	[5:0]	ssr_out,	//
    
    // Analog to Digital Convertor AD7812
    output	adc_dout,			// SPI DO
    output	adc_sclk_out,		// SPI SCK
    input	adc_din,			// SPI DI
    output	adc_con_out,		// ADC CONVERT
    
    // Expantion slot
    input	[3:0]	exp_in,		//  Expantion Inputs
    output	[11:0] 	exp_io		//	Expantion bidirectional
    );
    
    wire clk;
    wire rst;
    
    wire f100;
    
    wire [31:0] Pos;
    wire [30:0] Velocity;
    wire [29:0] to;
    
    reg [15:0] param_1;
    reg [15:0] param_2;    
    reg [15:0] param_3;    
    reg [15:0] param_4;
    
    
        wire  gray_ready;
    reg b_reg_reset;
    
    wire [15:0] wReg;
    
    
    assign clk = clk_in;
    assign rst = ~rst_in;
    
    reg [31:0] rSSI;
    reg rGoStrob;
    
    
    wire  [15:0] pwm_a;
    wire  [15:0] pwm_b;
    
    
    
    wire wPWM_A_h;
    wire wPWM_A_l;
    
    wire wPWM_B_h;
    wire wPWM_B_l;
    
    wire [15:0]ia;
    wire [15:0]ib;
    
    wire [15:0]iq;
    wire [15:0]id;
    wire [15:0]i_a;
    wire [15:0]i_b;
    wire [15:0]uq;
    wire [15:0]ud;
    wire [15:0]Va;
    wire [15:0]Vb;
    

    // waz 12
   	wire rs;				//  ����� �� �������� ����������� ����� ��������� ���� (� ������� � DFOC �����)
	reg [7:0] r_cnt;		//  ����� �� ���� ���������� �������� �� ������ ��������� ����������
	
	always @(posedge rst or posedge clk)
		if(rst) 
			r_cnt<=13'h1FFF;
		else
			r_cnt<=r_cnt-1;
	
	//assign rs = (r_cnt==0); 
    reg [31:0] Pol;
    
    always @(posedge clk)
        if(rs)
            Pol <= Pol + param_1;
    
            
            
      wire [15:0] wPA;
      
      wire [31:0] wPhi;
      
      assign wPhi = param_1[0] ? {rSSI[15:00],16'd0} : Pol;
      
wire pixel_clock;

   DCM vga_dcm (.CLKIN(clk), 
			.RST(1'b0),
			.CLKFX(pixel_clock));
   // synthesis attribute DLL_FREQUENCY_MODE of vga_dcm is "HIGH"
   // synthesis attribute DUTY_CYCLE_CORRECTION of vga_dcm is "TRUE"
   // synthesis attribute STARTUP_WAIT of vga_dcm is "TRUE"
   // synthesis attribute DFS_FREQUENCY_MODE of vga_dcm is "HIGH"
   // synthesis attribute CLKFX_DIVIDE of vga_dcm is 12
   // synthesis attribute CLKFX_MULTIPLY of vga_dcm is 4
   // synthesis attribute CLK_FEEDBACK of vga_dcm  is "NONE"
   // synthesis attribute CLKOUT_PHASE_SHIFT of vga_dcm is "NONE"
   // synthesis attribute PHASE_SHIFT of vga_dcm is 0
   // synthesis attribute clkin_period of vga_dcm is "20.00ns"      

    dfoc_pwm_core_2ph #(
        .sm_k(32'd3276800),
        .reg_k(1))
        DFOK (
        .rst(rst),
        .clk(clk),
        .clk_pwm(pixel_clock),
        .phi(wPhi),
        .Amp(param_4),
        .phase_bias(param_1),
        .ia(ia),
        .ib(ib),
        .start(gray_ready/*rs*/),
        .iq(iq),
        .id(id),
        .i_a(i_a),
        .i_b(i_b),
        .uq(uq),
        .ud(ud),
        .Va(Va),
        .Vb(Vb),
        .Kp(0),
        .Ki(0),
        .dead_time(0),
        .iq_bias(0),
        .int_rst(0),
        .s_mode(1),
        .h1(wPWM_A_h),
        .h2(wPWM_B_h),
        .l1(wPWM_A_l),
        .l2(wPWM_B_l),
        .pa(wPA),
        .iq_sin(),
        .rdy(rs),
        .p_rdy()
        );
    
    
    
    //------------- SSI Interface -------------------
    reg sstrob;
    wire oSSI;
    wire iSSI;
    reg [31:0] incc; //waz 12
    
    always @(posedge clk, posedge rst)
        if(rst) begin
                incc <= 0;
                sstrob <= 0;
        end else 
            if(b_reg_reset == 0)begin
                    if(incc == 0) begin
                            incc <= param_3<<10;
                            sstrob <= 1;
                    end else begin
                            incc <= incc - 1;
                            sstrob <= 0;
                        end
            end else begin
                    incc <= param_3<<10;
                    sstrob <= 0;
                end
    
    
    reg [15:0] counter;
    
    
    wire [31:0] data_out;
    wire [31:0] gray_in;
    wire data_ready;
    
    ssi #(
        .prescaler(20),
        .dim(32),
        .ssi_stop(40) // waz 30 - mean 50 steps per rev..  
        )SSI
        (
        .clk(clk),                          // Клок 50 Mhz
        .rst(rst),                          // Ресет активный высокий
        .ssi_clk_out(oSSI),                     // Выход на SSI клок
        .ssi_data_in(iSSI),                 // Вход данных от SSI
        .read_in(sstrob),                     // Строб запроса датчика
        .data_out(data_out),              // Выход данных
        .data_ready(data_ready)                       // Готовность данных
        ) ;
    
    assign gray_in = {32'd0,data_out};
    
    assign rs422_tx8_out = oSSI;
    assign rs422_de8_out = 1;
    assign iSSI = rs422_rx6_in;
    
    assign uart1_tx_out = iSSI;
    assign uart2_tx_out = data_ready;
    
    wire [31:0] gray_out;

    
    gray2bin g2b (
        .clk(clk),
        .rst(rst),
        .read_in(data_ready),
        .gray_in(gray_in),
        .data_out(gray_out),
        .data_ready(gray_ready)
        );
    
    
    reg [15:0] gray_fi;
    
    always @(posedge clk)
        if(gray_ready)
            gray_fi <= gray_out; 
    
    always @(posedge clk)
        rGoStrob <= gray_ready;
    
    always @(posedge clk)
        if(gray_ready)
            rSSI <= gray_out/*50*/;
    
    
    
    wire wAH,wAL,wBH,wBL,wCH,wCL,wDH,wDL;
    
    assign wAH = wPWM_A_h;
    assign wAL = wPWM_A_l;
    assign wBH = ~wPWM_A_h;
    assign wBL = ~wPWM_A_l;
    
    assign wCH = wPWM_B_h;
    assign wCL = wPWM_B_l;
    assign wDH = ~wPWM_B_h;
    assign wDL = ~wPWM_B_l;
    
    
    
    assign dig_out[10] = wPWM_A_h; // AH
    assign dig_out[9]  = wPWM_A_l; // AL
    assign dig_out[7]  = ~wPWM_A_h; // BH
    assign dig_out[8]  = ~wPWM_A_l; // BL
    
    assign dig_out[14] =  wPWM_B_h; // CH
    assign dig_out[13]  = wPWM_B_l; // CL
    assign dig_out[11]  = ~wPWM_B_h; // DH
    assign dig_out[12]  = ~wPWM_B_l; // DL
    
    
    assign dig_out[18] = 1;// 1; // PUSK
    assign dig_out[15] = 0; // Sbros Avar Driver
    assign dig_out[16] = 0; // Sbros Avar Tok
    
    assign dig_out[0] = 0;
    assign dig_out[1] = 0;
    assign dig_out[2] = 0;
    assign dig_out[3] = 0;
    assign dig_out[4] = 0;
    assign dig_out[5] = 0;
    assign dig_out[6] = 0;
    
    assign dig_out[17] = 0;
    assign dig_out[19] = 0;
    assign dig_out[20] = 0;
    
    assign rs422_ext_de2_out  = 1;
    
    
    always @(posedge clk)
        if(data_ready)
            counter <= counter + 1;
    
    
    //**************8-��������� ���, ��� ������ ����� � ����������************
    wire [11:0]adc_ch0; 		//����� 1 ���������������� ���
    wire [11:0]adc_ch1; 		//����� 2 ���������������� ���
    wire [11:0]adc_ch2; 		//����� 3 ���������������� ���
    wire [11:0]adc_ch3; 		//����� 4 ���������������� ���
    wire [11:0]adc_ch4; 		//����� 5 ���������������� ���
    wire [11:0]adc_ch5; 		//����� 6 ���������������� ���
    wire [11:0]adc_ch6; 		//����� 7 ���������������� ���
    wire [11:0]adc_ch7; 		//����� 8 ���������������� ���
    
    
    wire adc_rdy;
    
    adc_spi_conv_v2 #(
        .chn_str(0),
        .chn_end(7))
        adc_8_ch (
        .clk(clk),
        .rst(rst),
        .sdi_out(adc_dout),
        .sdo_in(adc_din),
        .sclk_out(adc_sclk_out),
        .conv_out(adc_con_out),
        .value_out0(adc_ch0),
        .value_out1(adc_ch1),
        .value_out2(adc_ch2),
        .value_out3(adc_ch3),
        .value_out4(adc_ch4),
        .value_out5(adc_ch5),
        .value_out6(adc_ch6),
        .value_out7(adc_ch7),
        .finish(adc_rdy)
        );						
    
    wire [15:0]zero_level; //������� ����������
    wire [15:0]i_a1;  //��� ���� A1
    wire [15:0]i_b1;  //��� ���� B1
    wire [15:0]i_c1;  //��� ���� C1
    wire [15:0]i_c2;  //��� ���� C2
    wire [15:0]u_l1;  //���������� ���� L1
    wire [15:0]u_l2;  //���������� ���� L2
    wire [15:0]u_l3;  //���������� ���� L3
    
    assign zero_level = {4'b0,adc_ch0[11:0]};
    
    assign u_l1 = {4'b0,adc_ch1[11:0]}-zero_level;
    assign u_l2 = {4'b0,adc_ch2[11:0]}-zero_level;
    assign u_l3 = {4'b0,adc_ch3[11:0]}-zero_level;
    
    assign i_a1 = {4'b0,adc_ch4[11:0]}-zero_level;
    assign i_b1 = {4'b0,adc_ch5[11:0]}-zero_level;
    assign i_c1 = {4'b0,adc_ch6[11:0]}-zero_level;
    assign i_c2 = {4'b0,adc_ch7[11:0]}-zero_level;   
    
    reg init_start;
    
    always @(posedge clk, posedge rst)
        if(rst)
            init_start <= 1;
        else
            if(init_start)
                init_start <= 0;
                
 wire [11:0]ia_bias;               
 wire [11:0]ib_bias;               
    
    current_bias_init_core Label1 (.rst(rst),
        .clk(clk),
        .start(init_start),
        .ia(adc_ch3),
        .ib(adc_ch4),
        .adc_rdy(adc_rdy),
        .ia_bias(ia_bias),
        .ib_bias(ib_bias),
        .rdy()
        );
    
assign ia ={adc_ch3,4'b0} - {ia_bias,4'b0};
assign ib ={adc_ch4,4'b0} - {ib_bias,4'b0};
        
    //**************Внешний технологический интерфейс*************************
    
    //Входящий пакет
    wire [7:0] cmi_head_in;
    wire [15:0]cmi_data0_in;	//Блок данных 0 входного пакета
    wire [15:0]cmi_data1_in;	//Блок данных 1 входного пакета
    wire [15:0]cmi_data2_in;	//Блок данных 2 входного пакета
    wire [15:0]cmi_data3_in;	//Блок данных 3 входного пакета
    wire cmi_fault;				//Ошибка принятия пакета
    wire cmi_in_st;				//Строб прихода пакета
    
    //Исходящий пакет
    reg [15:0]cmi_data0_self;	//Блок 0 исходящей телеметрии
    reg [15:0]cmi_data1_self;	//Блок 1 исходящей телеметрии
    reg [15:0]cmi_data2_self;	//Блок 2 исходящей телеметрии
    reg [15:0]cmi_data3_self;	//Блок 3 исходящей телеметрии
    wire marker_st_out;         //Строб обновления телеметрии
    
    //Параметры исходящей телеметрии
    reg [15:0]tsg_width;			//Ширина временного слота в тактах генератора деленная
    reg cmi_reload;					//Строб перезапуска отправки телеметрии
    reg [23:0]cmi_count;			//Кол-во пакетов телеметрии, которые необходимо отправить
    
    cmi_single_packet_manager #(
        .link_speed(54))
        packetmanager (
        .rst(rst),
        .clk(clk),
        .rx(rs422_ext_rx4_in),
        .tx(rs422_ext_tx2_out),
        .width(tsg_width),
        .reload(cmi_reload),
        .cmi_count(cmi_count),
        .marker_st_out(marker_st_out),
        .cmi_data0_self(cmi_data0_self),
        .cmi_data1_self(cmi_data1_self),
        .cmi_data2_self(cmi_data2_self),
        .cmi_data3_self(cmi_data3_self),
        .cmi_head_in(cmi_head_in),
        .cmi_data0_in(cmi_data0_in),
        .cmi_data1_in(cmi_data1_in),
        .cmi_data2_in(cmi_data2_in),
        .cmi_data3_in(cmi_data3_in),
        .cmi_in_st(cmi_in_st),
        .cmi_fault(cmi_fault)
        );
        
        
        // test
        
        wire [18:0] a19,b19,c19;
        assign a19 = param_3;
        assign b19 = param_4;
mult19 m19_dfoc (	 //19 ������ �������� ���������� mult19
	.a(a19),
	.b(b19),
	.c(c19)
);
        
    
    //*************************Обработка входящих пакетов*********************
    reg [5:0]cmi_mode;  //Номер канала телеметрии
    
    always @(posedge rst, posedge clk)
        if(rst)
            begin 
                cmi_mode <= 0;
                tsg_width <= 12500;  //По умолчанию ширина временного слота 0.25 мс
                cmi_reload <= 0;				  
                cmi_count <= 0;				
                param_1 <= 0;
                param_2 <= 0;
                b_reg_reset <= 0;
        end else
            begin 
                if(b_reg_reset)
                    b_reg_reset <= 0;
                if(cmi_reload)
                    cmi_reload <= 0; //Сброс строба cmi_reload
                if(cmi_in_st)					//Если пришел пакет
                    case (cmi_head_in[3:0])		//Смотрим его тип по заголовку
                        0:begin 			 
                                cmi_count <= {cmi_data1_in[7:0],cmi_data0_in[15:0]};	//Установка нужного канала и запуск съема данных телеметрии
                                cmi_mode  <= cmi_data2_in[5:0];							  
                                cmi_reload <= 1;
                            end	
                        1:begin 
                                tsg_width <= cmi_data0_in;  //Установка периода снятия телеметрии
                            end					
                        2:begin 
                                param_1 <= cmi_data0_in;
                            end	
                        3:begin 
                                param_2 <= cmi_data0_in;
                                b_reg_reset <= 1;
                            end	
                        4:begin
                                param_3 <= cmi_data0_in;
                            end
                        5:begin 
                                param_4 <= cmi_data0_in;
                            end
                    endcase						
            end	
    //*********************Формирование исходящей телеметрии******************
    
    
    wire [15:0] reg_par0,reg_par1,reg_par2,reg_par3;
    
    always @(posedge rst, posedge clk)
        if(rst)
            begin 
                cmi_data0_self <= 0;
                cmi_data1_self <= 0;
                cmi_data2_self <= 0;
                cmi_data3_self <= 0;
            end
        else if(marker_st_out)
            begin
                case(cmi_mode)
                    0:begin 
                            cmi_data0_self <= pwm_a;
                            cmi_data1_self <= pwm_b;
                            cmi_data2_self <= 0;
                            cmi_data3_self <= rSSI;
                        end	
                    1:begin 
                            cmi_data0_self <= reg_par0;
                            cmi_data1_self <= reg_par1;
                            cmi_data2_self <= reg_par2;
                            cmi_data3_self <= reg_par3;
                        end			
                    2:begin 
                            cmi_data0_self <= Va;
                            cmi_data1_self <= Vb;
                            cmi_data2_self <= wPA;
                            cmi_data3_self <= rSSI;
                        end	
                    3:begin 
                            cmi_data0_self <= adc_ch1;
                            cmi_data1_self <= adc_ch5;
                            cmi_data2_self <= adc_ch6;
                            cmi_data3_self <= adc_ch7;
                        end
                    4:begin 
                            cmi_data0_self <= adc_ch1;
                            cmi_data1_self <= adc_ch2;
                            cmi_data2_self <= adc_ch3;
                            cmi_data3_self <= adc_ch4;
                        end	
                    5:begin 
                            cmi_data0_self <= ia;
                            cmi_data1_self <= ib;
                            cmi_data2_self <= iq;
                            cmi_data3_self <= id;
                        end	
                    6:begin 
                            cmi_data0_self <= i_a;
                            cmi_data1_self <= i_b;
                            cmi_data2_self <= ud;
                            cmi_data3_self <= uq;
                        end	
                endcase														  
            end	    	
    //
    // added bugaga
    //
    
  
    
endmodule