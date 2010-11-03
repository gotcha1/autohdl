module current_bias_init_core(
	input rst, //�����
	input clk, //�������� ���������
	input start, //������ ��������� �������� ��������
	input [11:0]ia, //���� � ��� ���� A
	input [11:0]ib,	//���� � ��� ���� B
	input adc_rdy,  //���� ���������� ���
	output reg [11:0]ia_bias, //�������� ���� a
	output reg [11:0]ib_bias, //�������� ���� b
	output reg rdy);  //���� ����������
	
	
reg [19:0]ia_b;	 //�������� ������������ ��� ���������� �������� ��������
reg [19:0]ib_b;	 //�������� ������������ ��� ���������� �������� ��������

reg [10:0]timer;
reg [1:0]state;  //���� ����, ��� ���� ������� ����������

always @(posedge rst, posedge clk)
	if(rst)
		begin 
			ia_bias <= 0;
			ib_bias <= 0;
			timer <= 0;
			rdy <=0;			
            ia_b <=0;				   
            ib_b <=0;				   
			state <= 0;
		end	 else
		if (timer)
			begin 
				if(adc_rdy)					//������ ����������� ������������ ���-�� ������������  ���
                    begin
    					timer<=timer-1;
                        ia_b <= ia_b+{ia[11],ia[11],ia[11],ia[11],ia[11],ia[11],ia[11],ia[11],ia}; //����������� � ia_b �������� ���� ia
                        ib_b <= ib_b+{ib[11],ib[11],ib[11],ib[11],ib[11],ib[11],ib[11],ib[11],ib}; //����������� � ib_b �������� ���� ib
                    end
				rdy<=0;	
			end	else
			begin 
                case(state)
                2'b00:  begin
						    if (start)
							    begin 
								    timer <= 2000;		//���� �����, �� ����������� 1000 ������ ���, ���� ��������� ��������� ����������� �������� �� ����
								    state <= 2'b01;
							    end	
						    rdy <= 0;
                        end
                2'b01:  begin
                           ia_b <= {ia[11],ia[11],ia[11],ia[11],ia[11],ia[11],ia[11],ia[11],ia}; //���������� � ia_b �������� ���� ia
                           ib_b <= {ib[11],ib[11],ib[11],ib[11],ib[11],ib[11],ib[11],ib[11],ib}; //���������� � ib_b �������� ���� ib
                           timer <= 255;    //���������� ������ �� 255 �������� � ������� ������� ������� ��� 255 �������� ����
                           state <= 2'b10;     
                        end
                2'b10:  begin
                            ia_bias <= ia_b[19:8];     //����� ������� �������� ����� �� ��������� 256 ������                 
                            ib_bias <= ib_b[19:8];                      
                            state <= 2'b00;
                            rdy <= 1;
                        end 
                endcase
			end	
	
endmodule	
