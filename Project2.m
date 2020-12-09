%% Analog IC Project 2
%% About
% Aaron Tobias, Joshua Newman
% 
% Analog Integrated Circuits
%
% December 11, 2020
%
% Dr. Lee
%
%% Objective
% The objective of this project is to design the single-ended folded cascode amplifier using the
% transistor circuit model with the pre-simulation data (provided as the Excel file). This approach
% will eventually lead to design automation of analog integrated circuits which can significantly
% reduce the design time.
%
%% Design Constraints
%
% # gm1 >= 350uA/V, gm1 = 2I1/(|VGS1| – |VTHp|)
% # Power consumption (VDD×Iss) <= 480 uW
% # I1 = I2, I1 + I2 = Iss
% # NMOS: VTHn = 559mV, VGS = 0.8V or 1V, PMOS: |VTHp| = 747mV, |VGS| = 0.9V or 1.1V
% # VDD = 3V, |VDS1| = 2V, |VDS2| = 0.6V, VDS3 = 0.5V, VDS4 = 1V
% # L = 1um, W = 0.5um ~ 10um (W should not exceed 10um)
%

%%% Putting Constraints in Matlab

% Clear variables and close windows
clc;clear;close all hidden;
format shorteng;
% Voltage Constraints
VDD=3;
VTHn=0.559;
VTHp=0.747;
VGSp_LIST=[0.9,1.1];
VGSn_LIST=[0.8,1];

% M1
VDS1=2;
% M2
VDS2=0.6;
% M3
VDS3=0.5;
% M4
VDS4=1;

%width and length constraints
L=1e-6;
W_MIN=0.5e-6;
W_MAX=10e-6;

%% Determine I_SS, V_I_CM, V_B1, V_B2, V_B3, and R_D based on design constraints

disp("First we calculate the max ISS value to get a power consumption under 480µW")
ISS_MAX=480e-6/VDD %Max ISS to get power under 480uW
disp("This means that our max I1 value is half of our max ISS value")
I1_MAX=ISS_MAX/2   %I1+I2=ISS, I1=I2 ... I1=ISS/2
I1_LIST=5e-6:1e-6:I1_MAX; %possible I1 currents



figure()
gm1_LIST=2*I1_LIST'./(VGSp_LIST-VTHp);
plot(ones(1,length(gm1_LIST))*VGSp_LIST(1),gm1_LIST(:,1),'.')
hold on
plot(ones(1,length(gm1_LIST))*VGSp_LIST(2),gm1_LIST(:,2),'.')
xlabel('V_{GS}_1');
ylabel('g_{m1}');
xlim([0.8 1.2])
line([0.8 1.2], [350e-6 350e-6],'Color','red','LineStyle','--')
min1=find(gm1_LIST(:,1)>350e-6); %find gm1s > 350uA/V for VGS = 0.9V
min2=find(gm1_LIST(:,2)>350e-6); %find gm1s > 350uA/V for VGS = 1.1V
min_cur1=sprintf('%.0fuA',I1_LIST(min1(1))*1e6);
min_cur2=sprintf('%.0fuA',I1_LIST(min2(1))*1e6);
text(VGSp_LIST(1),gm1_LIST(min1(1),1),strcat('\leftarrow ',min_cur1));
text(VGSp_LIST(2),gm1_LIST(min2(1),2),strcat('\leftarrow ',min_cur2));
legend('V_{GS}=0.9V','V_{GS}=1.1V','350uA/V')
title('g_{m1}vs I_1')
hold off

fprintf("For VGSp = 0.9V, I1 must be greater than or equal to %s to obtain gm1 of 350uA/V.\n",min_cur1);
fprintf("For VGSp = 1.1V, I1 must be greater than or equal to %s to obtain gm1 of 350uA/V.\n",min_cur2);

%Inputs
VGSn=VGSn_LIST(2); %choose 1V for NMOS
VGSp=VGSp_LIST(1); %choose 0.9V for PMOS

fprintf("We chose a VGSp of %0.1fV to allow a larger range of potential currents.\n",VGSp);
fprintf("We chose a VGSn of %0.1fV.\n",VGSn);

disp("We then assigned these values to the PMOS and NMOS transistors.");

VGS1=VGSp %M1 is PMOS
VGS2=VGSp %M2 is PMOS
VGS3=VGSn %M3 is NMOS
VGS4=VGSn %M4 is NMOS


disp("We chose a current I1 greater than the minimum value found above")
I1=50e-6 %Chosen for nice round RD, among range that fits constraints
disp("This gives us a gm1 value of:")
gm1=2*I1/(VGS1-VTHp)
disp("I2 is the same as I1")
I2=I1
disp("ISS is I1+I2");
ISS=I2+I1
disp("The power consumption is then calculated:")
PWR=VDD*ISS


% overdrive voltages, |VDS| > VOV to be active
disp("We can then calculate the overdrive voltages needed to put the transistors into saturation");
VOVn=VGSn-VTHn
VOVp=VGSp-VTHp

disp("We then used KVL to determine the voltages at each node");
VD4=VDS4 %
VB3=VGSn %
VB2=VD4+VGSn %
VD3=VDS3+VD4 %
VOUT=VD3
VB1=VD3+VGSp %
VD2=VDS2+VD3 %
VICM=VGSp+VD4
disp("We can then calculate RD by using Ohm's law")
RD=(VDD-VD2)/I1

%% NMOS Trendlines

W_DATA=[0.5,1,5,10]*1e-6;
ID_DATA=[1,2,5,10,20,50,100]*1e-6;
ID_LIST=5e-7:1e-7:100e-6;

%Rout vs ID
%Given data
ROUT_DATA_N=[8.53E+06,4.84E+06,2.41E+06,1.49E+06,9.43E+05,5.32E+05,3.46E+05];
%Matlab
[xData, yData] = prepareCurveData( ID_DATA, ROUT_DATA_N );
ft = fittype( 'power2' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Robust = 'LAR';
opts.StartPoint = [283.933740044594 -0.75016598190214 -180437.381754493];
ROUTNfit=fit(xData,yData,ft,opts);
%ROUT_MATLAB_N = result.a*ID_LIST_N.^(result.b)+result.c;
%fprintf("NMOS:\n ROUT = %e*ID^{%e} + %e\n",result.a,result.b,result.c)

%From Excel Trendline
ROUT_EXCEL_N = 552.996385450445*ID_LIST.^(-0.691755459405021);
ROUT_EXCEL_ERROR_N = ROUT_DATA_N - (552.996385450445*ID_DATA.^(-0.691755459405021));

figure
subplot( 2, 1, 1 );
hold on
plot(ROUTNfit, xData, yData);
plot(ID_LIST,ROUT_EXCEL_N);
sgtitle(sprintf('NMOS\nR_{out} vs I_D'))
title('Curve-fit vs actual data');
legend('Actual','Curve-fit (Matlab)','Curve-fit (Excel)')
xlabel('I_D')
ylabel('R_{out}')
hold off

%plot error
subplot( 2, 1, 2 );
hold on
plot(ID_DATA,ROUT_EXCEL_ERROR_N,'x')
plot( ROUTNfit, xData, yData, 'residuals' )
title('Error margins')
legend('Excel residuals','Matlab residuals', 'Zero Line', 'Location', 'NorthEast');
xlabel('I_D')
ylabel('R_{out}')
grid on

%IA vs W
%Given
if (VGSn==0.8)
    IA_DATA_N=[3.32E-06,5.50E-06,2.68E-05,5.33E-05];
elseif (VGSn==1)
    IA_DATA_N=[9.05E-06,1.55E-05,8.12E-05,1.63E-04];
end

%Curve-fit (Excel)
W_LIST=W_MIN:0.5e-6:W_MAX;
if (VGSn==0.8)
    IA_N= 5.27798066595059.*W_LIST + 0.443329752953811e-6; %VGS=0.8V
    IA_EXCEL_ERROR_N=IA_DATA_N - (5.27798066595059.*W_DATA + 0.443329752953811e-6);
elseif (VGSn==1)
    IA_N= 16.3235660580021.*W_LIST - 0.0597099892588577e-6; %VGS=1V
    IA_EXCEL_ERROR_N=IA_DATA_N - (16.3235660580021.*W_DATA - 0.0597099892588577e-6);
end

%Curve-fit (Matlab)
[xData, yData] = prepareCurveData( W_DATA, IA_DATA_N );
ft = fittype( 'poly1' );
IANfit = fit(xData,yData,ft);
WNfit = fit(yData,xData,ft);

figure
subplot( 2, 1, 1 );
hold on
plot(IANfit, xData, yData);
plot(W_LIST,IA_N);
sgtitle(sprintf('NMOS\n I_A vs W, V_{GS} = %.1fV',VGSn))
title('Curve-fit vs actual data');
legend('Actual','Curve-fit (Matlab)','Curve-fit (Excel)', 'Location', 'NorthWest')
xlabel('W')
ylabel('I_A')
hold off

%plot error
subplot( 2, 1, 2 );
hold on
plot(W_DATA,IA_EXCEL_ERROR_N,'x')
plot( IANfit, xData, yData, 'residuals' )
title('Error margins')
legend('Excel residuals','Matlab residuals', 'Zero Line', 'Location', 'NorthEast');
xlabel( 'W');
ylabel( 'I_A');
grid on
hold off

%% PMOS Trendlines
%Rout vs ID
%Given data
ROUT_DATA_P=[6.93E+06,3.91E+06,1.94E+06,1.17E+06,7.04E+05,3.52E+05,2.06E+05];

%Matlab
[xData, yData] = prepareCurveData( ID_DATA, ROUT_DATA_P );
ft = fittype( 'power2' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.Robust = 'LAR';
opts.StartPoint = [148.974663599144 -0.779641370529516 -62275.9189076183];
ROUTPfit=fit(xData,yData,ft,opts);

%From Excel Trendline
ROUT_EXCEL_P = 193.626778333894000*ID_LIST.^(-0.756803491149173);
ROUT_EXCEL_ERROR_P = ROUT_DATA_P - 193.626778333894000*ID_DATA.^(-0.756803491149173);

figure
subplot( 2, 1, 1 );
hold on
plot(ROUTPfit, xData, yData);
plot(ID_LIST,ROUT_EXCEL_P);
%plot(W_DATA,IA_DATA,'x');
sgtitle(sprintf('PMOS\nR_{out} vs I_D'))
title('Curve-fit vs actual data');
legend('Actual','Curve-fit (Matlab)','Curve-fit (Excel)', 'Location', 'NorthEast')
xlabel('I_D')
ylabel('R_{out}')
hold off

%plot error
subplot( 2, 1, 2 );
hold on
plot(ID_DATA,ROUT_EXCEL_ERROR_P,'x')
plot( ROUTPfit, xData, yData, 'residuals' )
title('Error margins')
legend('Excel residuals','Matlab residuals', 'Zero Line', 'Location', 'NorthEast');
xlabel('I_D')
ylabel('R_{out}')
grid on

%IA vs W
if (VGSp==0.9)
    IA_DATA_P=[2.42,5.08,33.48,69.82]*1e-6;
elseif (VGSn==1.1)
    IA_DATA_P=[6.18,12.32,77.28,159.98]*1e-6;
end

%Curve-fit (Excel)
W_LIST=W_MIN:0.5e-6:W_MAX;
if (VGSp==0.9)
    IA_P = 7.12936627282492.*W_LIST - 1.70863587540279e-6; %VGS=0.9
    IA_EXCEL_ERROR_P=IA_DATA_P -(7.12936627282492.*W_DATA - 1.70863587540279e-6);
elseif (VGSp==1.1)
    IA_P = 16.2680988184748.*W_LIST - 3.16590762620837e-6; %VGS=1.1V
    IA_EXCEL_ERROR_P=IA_DATA_P - ( 16.2680988184748.*W_DATA - 3.16590762620837e-6);
end

%Curve-fit (Matlab)
[xData, yData] = prepareCurveData( W_DATA, IA_DATA_P );
ft = fittype( 'poly1' );
IAPfit = fit(xData,yData,ft);
WPfit = fit(yData,xData,ft);



figure
subplot( 2, 1, 1 );
hold on
plot(IAPfit, xData, yData);
plot(W_LIST,IA_P);
sgtitle(sprintf('PMOS\nI_A vs W, V_{GS} = %.1fV',VGSp));
title('Curve-fit vs actual data');
legend('Actual','Curve-fit (Matlab)','Curve-fit (Excel)', 'Location', 'NorthWest')
xlabel('W')
ylabel('I_A')
hold off

%plot error
subplot( 2, 1, 2 );
hold on
plot(W_DATA,IA_EXCEL_ERROR_P,'x')
plot( IAPfit, xData, yData, 'residuals' )
title('Error margins')
legend('Excel residuals','Matlab residuals', 'Zero Line', 'Location', 'SouthWest');
xlabel( 'W');
ylabel( 'I_A');
grid on

%% Find W1-4 using Iss, V_I_CM, V_B1-3, V_DS1-4 as inputs.
% Program should use mathematical expressions for I_A(W) and Rout(ID)
% obtained by curve fitting pre-simulated I_A and Rout data
% Report should include computer program source code and screen shot of
% results
disp("To obtain W1-4")
disp("We first find Rout for ID using the trendlines")
Rout1= ROUTPfit(I1)
Rout2= ROUTPfit(I2);
Rout3= ROUTNfit(I2); %Id=50uA, trendline predicts 532k, perfect
Rout4= ROUTNfit(ISS);


disp("We then find IP from Ip=(VDS-Vov)/Rout")
IP1=(VDS1-VOVp)/Rout1
IP2=(VDS2-VOVp)/Rout2
IP3=(VDS3-VOVn)/Rout3
IP4=(VDS4-VOVn)/Rout4

disp("Then we can find Ia=Id-Ip")
IA1=I1-IP1
IA2=I2-IP2
IA3=I2-IP3
IA4=ISS-IP4

disp("This allows us to use the trendline for IA vs W to find our W")
%Find W from trendline
W1=WPfit(IA1)
W2=WPfit(IA2)
W3=WNfit(IA3)
W4=WNfit(IA4)

%% Document the procedure for setting the design parameters, especially the procedure for setting W_1-5 should be clearly described.
% Justify your design meets all design constraints
disp("Finally, we check all our values against our design constraints.");
disp("If our values do not meet the constraint, the program errors out.");
disp(' ');
disp('1)');
assert(gm1>=350e-6,'gm1:\t  %.2f uA/V < 350uA/V \n\n',gm1*1e6)
fprintf('gm1:\t  %.2f uA/V >= 350uA/V \n\n',gm1*1e6);

disp('2)');
assert(PWR<480e-6,'Pwr:\t  %.2f uW > 480 uW\n\n',PWR*1e6)
fprintf('Pwr:\t  %.2f uW <= 480 uW\n\n',PWR*1e6); 

disp('3)');
fprintf('I1:\t\t  %.2f uA \n',I1*1e6);
fprintf('I2:\t\t  %.2f uA \n',I2*1e6);
assert(I1==I2,'I1 != I2');
disp('I1==I2')
fprintf('ISS:\t  %.2f uA \n',ISS*1e6);
assert((I1+I2)==(ISS),'I1+I2 != ISS');
disp('I1+I2=ISS');
disp(' ')

disp('4)');
assert(VTHn==0.559,'VTHn:\t  %.0f mV != 559mV\n',VTHn*1e3);
fprintf('VTHn:\t  %.0f mV = 559mV\n',VTHn*1e3);
assert(VGSn==0.8 | VGSn==1,'VGSn:\t  %.2f V \n != 0.8V or 1V',VGSn);
fprintf('VGSn:\t  %.2f V = 0.8V or 1V \n',VGSn);
assert(VTHp==0.747,'VTHp:\t  %.0f mV != 747mV \n',VTHp*1e3);
fprintf('VTHp:\t  %.0f mV = 747mV \n',VTHp*1e3);
assert(VGSp==0.9 | VGSp==1.1,'VGSp:\t  %.1f V != 0.9V or 1.1V \n\n',VGSp);
fprintf('VGSp:\t  %.2f V = 0.9V or 1.1V \n\n',VGSp);

disp('5)');
assert(VDD==3,'VDD != 3V');
fprintf('VDD:\t  %.2f V = 3 V\n',VDD);
assert(VDS1==2,'VDS1:\t  %.2f V != 2 V\n',VDS1);
fprintf('VDS1:\t  %.2f V = 2 V\n',VDS1);
assert(VDS2==0.6,'VDS2:\t  %.2f V != 0.6 V \n',VDS2);
fprintf('VDS2:\t  %.2f V = 0.6 V \n',VDS2);
assert(VDS3==0.5,'VDS3:\t  %.2f V != 0.5 V\n',VDS3);
fprintf('VDS3:\t  %.2f V = 0.5 V\n',VDS3);
assert(VDS4==1,'VDS4:\t  %.2f V != 1 V\n\n',VDS4);
fprintf('VDS4:\t  %.2f V = 1 V\n\n',VDS4);

disp('6)');
assert(L==1e-6,'L:\t\t %.2f um != 1 um \n',L*1e6);
fprintf('L:\t\t  %.2f um = 1 um \n',L*1e6);
assert(W1>=0.5e-6, 'W1: %.2f um < 0.5 um',W1*1e6);
assert(W1<=10e-6, 'W1: %.2f um > 10 um',W1*1e6);
fprintf('W1:\t\t 0.5 um < %.2f um < 10um  \n',W1*1e6);
assert(W2>=0.5e-6, 'W2: %.2f um < 0.5 um',W2*1e6);
assert(W2<=10e-6, 'W2: %.2f um > 10 um',W2*1e6);
fprintf('W2:\t\t 0.5 um < %.2f um < 10um  \n',W2*1e6);
assert(W3>=0.5e-6, 'W3: %.2f um < 0.5 um',W3*1e6);
assert(W3<=10e-6, 'W3: %.2f um > 10 um',W3*1e6);
fprintf('W3:\t\t 0.5 um < %.2f um < 10um  \n',W3*1e6);
assert(W4>=0.5e-6, 'W4: %.2f um < 0.5 um',W4*1e6);
assert(W4<=10e-6, 'W4: %.2f um > 10 um',W4*1e6);
fprintf('W4:\t\t 0.5 um < %.2f um < 10um  \n',W4*1e6);

