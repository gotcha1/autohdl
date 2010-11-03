module cmi_single_timeslot_generator(
	input rst,					//����������� �����
	input clk,					//�������� ���������
	input [15:0]width,			//������ ���������� ����� � ������ ����������
	input reload,				//����� ������������ ������������ �������� ������������ ����������
	input [23:0]cmi_count,		//��������, ������� ����� ���������� � ������� ��������� ��� �������� ������ reload
	output  marker_st 			//����� �� ������ ������ ���������� �����
	);

reg [16:0]timeslot_cnt;		//C������ ������� ����� ���������� �������
reg [23:0]cmi_cnt;		//������� ������� ����������

always @(posedge rst or posedge clk)
	if(rst)
		timeslot_cnt <= 0;
	else
		begin 
			if(cmi_cnt!=0)
				timeslot_cnt <= timeslot_cnt-1;		//���� �� ��� �� ��� ���������, �� ����� �������� ������
			if(timeslot_cnt[16])
				timeslot_cnt <= {1'b0,width};		//���� ��������� �� -1, �� ����� ����� ������ width
		end																							   

assign marker_st = timeslot_cnt[16];
		
always @(posedge rst or posedge clk)
	if(rst)
		cmi_cnt<=0;
	else
		if(reload)                     		//���� ����� reload, �� ��������� ����� �������� � �������
			cmi_cnt <= cmi_count;
		else
			if(marker_st)						//���� ������ ����� �������� ����������, �������������� �������
				cmi_cnt <= cmi_cnt - 1;
	
endmodule	
