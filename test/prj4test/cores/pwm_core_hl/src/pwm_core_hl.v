//***************************************��� ��������� � ��� ���������******************************
//������: ������� �.�., ���� �.�.
//		  ������� "������� ����������" �����(��), 2009 �.
//**************************************************************************************************//

module pwm_core_hl(
	input rst,							//����������� �����
	input clk,							//�������� ��������
	input [15:0] val_in,				//����������
	output h_out,  						//����� �� ������ ���������
	output l_out,						//����� �� ������� ���������
	output pwm_ready					//���� ��������� ������� ��� (��� �������� ������ �������� ����������)
	);
	
	parameter k=14;						//���-�� ��� ���		  
	parameter pwm_deadzone=0;

	reg  [15:0] val_in_s;	   
    wire [16:0] val_in_s_dz;	
	reg  [15:0] val_in_st;	   
	
	always @(posedge clk, posedge rst)	//������� �������� val_in � ����� ��������� �����
	if(rst)
	val_in_s <= 0;
	else
	val_in_s <= val_in;   
	
	assign val_in_s_dz = (val_in_s[15]) ? {val_in_s[15],val_in_s} - pwm_deadzone : {val_in_s[15],val_in_s} + pwm_deadzone;	//����������� ������� ���� � 0  
	
	always @(*)   //�������� �� ���������� �����������
		begin
			if (val_in_s_dz[16])
				begin 
					if (val_in_s_dz[15])
						val_in_st <= val_in_s_dz[15:0];
					else
						val_in_st <= 16'h8000;
				end							  
			else
				begin 
					if (val_in_s_dz[15])
						val_in_st <= 16'h7FFF;
					else
						val_in_st <= val_in_s_dz[15:0];
				end	
		end	
	
	 
	reg [k-1:0]val;						//�������� ������� ��� ������� ������������� ������ Hi � Low
	reg [k-1:0]cnt;                       //������� �������
	
	
	always @(posedge clk, posedge rst)
	if(rst)
		val <= 0;
	else							
		if(cnt == 0) 
			val <= (val_in_st[15:16-k])+(1<<(k-1));	  //���� ���������� ������ ��� ���������� �������� ����� �������� 
												  //����������� � ��������� ��� �� ��������� [-2^(k-1) 2^(k-1)-1] � [0 2^k-1]
			
    reg cnt_sign;
	
	always @(posedge clk, posedge rst)			  //������������������ ������, � ������������ �������� �������
	if(rst)
		{cnt_sign,cnt} <= 0;		
	else
		{cnt_sign,cnt} <= {cnt_sign,cnt} - 1; 
		
	wire [k-1:0]pwm_c;	
	assign pwm_c = (cnt_sign) ? ~cnt : cnt;
												  
	assign {h_out,l_out} = (val > pwm_c) ? 2'b10 : 2'b01; //������������ ������� Hi � Low
	
	assign pwm_ready = (cnt==0);                   //�� 2 ����� ���������� ������ ready, ����� ����� ��� ������ � �������� �����
	                                               //�������� �� ���������� � ���������� ������
	
	
endmodule
