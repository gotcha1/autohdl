module cmi_single_packet_manager(
	input rst, 					//����������� �����
	input clk,					//�������� ���������
	input rx,					//����� �����   USART
	output tx,					//����� ������	USART
	input [15:0]width,			//������ ���������� ����� � ������ ����������
	input reload,				//����� ������������ ������������ �������� ������������ ����������
	input [23:0]cmi_count,		//��������, ������� ����� ���������� � ������� ��������� ��� �������� ������ reload
	output marker_st_out,		//����� �� �������� ���� �������� ������ ����������
	input  [15:0]cmi_data0_self,//������ 0 ����� ����������
	input  [15:0]cmi_data1_self,//������ 1 ����� ����������
	input  [15:0]cmi_data2_self,//������ 2 ����� ����������
	input  [15:0]cmi_data3_self,//������ 3 ����� ����������

	output [7:0] cmi_head_in,	//��������� ���������� ������
	output [15:0]cmi_data0_in,	//������ 0 ����� ���������� �����
	output [15:0]cmi_data1_in,	//������ 1 ����� ���������� �����
	output [15:0]cmi_data2_in,	//������ 2 ����� ���������� �����
	output [15:0]cmi_data3_in,	//������ 3 ����� ���������� �����	  
	output cmi_in_st,			//����� ������� ������		
	output cmi_fault			//���� ����, ��� ������ ����� �����
	);
	
parameter link_speed = 54;  //�������� �������� �� ������: 434 - 115200, 54 - 921600
	
//�������� USART	 
wire [7:0]rx_data;
wire rx_ena;
/*
uart_rx_v2 #(
    .pClkHz(50_000_000),
    .pBaud(921_600),
    .pStopBits(1),
    .pParity(0),
    .pDataWidth(8)
    )
usart_rx (.iClk(clk),
    .iRst(rst),
    .iRxD(rx),
    .oData(rx_data),
    .oDone(rx_ena)
);

*/
rs232_rx #(
	.pWORDw(8),
	.pBitCellCntw(link_speed))
usart_rx (
	.Rst(rst),
	.Clk(clk),
	.iSerial(rx),
	.oRxD(rx_data),
	.oRxDReady(rx_ena)
);		


//������� �������
cmi_recv_packet recv_packet (
	.clk(clk),
	.rst(rst),
	.rx_ena(rx_ena),
	.rx_data(rx_data),
	.cmi_head(cmi_head_in),
	.cmi_data0(cmi_data0_in),
	.cmi_data1(cmi_data1_in),
	.cmi_data2(cmi_data2_in),
	.cmi_data3(cmi_data3_in),
	.cmi_rdy(cmi_in_st),
	.cmi_fault(cmi_fault),
	.marker_st(),
	.marker_type()
);	

//��������� ��������� ������ ��� �������� �������
cmi_single_timeslot_generator single_tsg (
	.rst(rst),
	.clk(clk),
	.width(width),
	.reload(reload),
	.cmi_count(cmi_count),
	.marker_st(marker_st_out)
);

//������������� �������
reg cmi_send_start;  //���� �������� ����������. ����������� ����� 2 ����� ����� marker_st_out, �.�. ����� ��������� cmi_data0

always @(posedge rst or posedge clk)
	if(rst)
		cmi_send_start <=0;
	else	
		if(marker_st_out)
			cmi_send_start <=1;
		else	
        	cmi_send_start <=0;
			
reg [5:0]seq;		//����� ������

always @(posedge rst or posedge clk)
	if(rst)
		seq <= 0;
	else
		if(marker_st_out)
			seq <= seq + 1;
			
wire [7:0]cmi_head_self;  //�������� ���������� ������(�������� ���������)			
assign cmi_head_self = {seq,2'b00};

wire [7:0]tx_data;
wire tx_enable;	
wire tx_rdy;
wire tx_busy;

assign tx_busy = ~tx_rdy;

cmi_send_packet send_packet (
	.clk(clk),
	.rst(rst),
	.start(cmi_send_start),
	.cmi_head(cmi_head_self),
	.cmi_data0(cmi_data0_self),
	.cmi_data1(cmi_data1_self),
	.cmi_data2(cmi_data2_self),
	.cmi_data3(cmi_data3_self),
	.tx_busy(tx_busy),
	.tx_data(tx_data),
	.tx_enable(tx_enable),
	.rdy()
);

//���������� USART
/*
uart_tx_v2 #(
    .pClkHz(50_000_000),
    .pBaud(921_600),
    .pStopBits(1),
    .pParity(0),
    .pDataWidth(8))
usart_tx (.iRst(rst),
    .iClk(clk),
    .iData(tx_data),
    .iEnStrobe(tx_enable),
    .oTxD(tx),
    .oDone(tx_rdy)
);
*/
rs232_tx #(
	.pWORDw(8),
	.pBitCellCnt(link_speed))
usart_tx (
	.Rst(rst),
	.Clk(clk),
	.iCode(tx_data),
	.iCodeEn(tx_enable),
	.oTxD(tx),
	.oTxDReady(tx_rdy)
);		 

endmodule
