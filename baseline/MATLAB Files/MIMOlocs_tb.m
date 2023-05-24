%% MIMO 3D DataGen across locations

%% LOAD ITU MIMO data

Datapath = '/home/modemmatlab/av_agrawal/ITU_004/ML5G-PS-004-main/ML5G-PS-004-main/dataset/area3/area3';

files = dir(strcat(Datapath,'/rf/*.mat'));
[samples, ~] = size(files);


%%  Global params
    MIMO_params.r0 = 5;%Abs LOS distance(m) = N_delay_taps*(1/1.76G)*3e8
    MIMO_params.Fs=1.76e9;MIMO_params.c = 3e8;
   
    MIMO_params.Mr = 8;MIMO_params.Nr = 8;%RX antennas
    MIMO_params.Mt = 8;MIMO_params.Nt = 8;%TX antennas

    MIMO_params.LOS_analysis_tap =1;% Delay tap used to resolve LOS (AOA,AOD)
    
    % Heat map Calculation in 2D : Beam Indx(AOA,AOD)  4D : Theta,Phi(AOA,AOD)
    MIMO_params.Calc_mode = '4D';% Calc_mode : '2D' OR  '4D' 
    MIMO_params.Rx_en = 1;% Output Depth map 1: RX perspective 0: Tx Perspective


%% LOS analysis
delay_max =  100;%No. of delays for LOS analysis
pwr_loc = zeros(samples,delay_max);
n_taps = zeros(samples,1);
LOS_i = struct('taps',0,'sinAOA',0,'sinAOD',0,'delay',0,'Amplitude',1i*ones(1,delay_max));
LOS = repmat(LOS_i,samples,1);

%% Generate heat map OR Just LOS analysis
Pwr_en = 1;
%Output power map
Pwr_RTP = zeros(samples,MIMO_params.Mr,MIMO_params.Nr,delay_max);

for loc_i = 1:samples    
    
    CIR = load(strcat(Datapath,'/rf/', files(loc_i).name));  % File loading part based on the sample no. needs to be added
    
    H_mimo3D = CIR.mimoCir;
    n_taps(loc_i) = min(size(H_mimo3D,3),delay_max);
    H_mimo3D = H_mimo3D(:,:,1:n_taps(loc_i));
    
    % Get Avg MIMO power across (Theta.Phi) for Mesh(loc,time)
    pwr_loc_i= squeeze(sum(abs(H_mimo3D).^2,[1 2]));
    pwr_loc(loc_i,1:n_taps(loc_i)) =  pwr_loc_i;
    

    % Find LOS delay at each location
    [pk_i,tap_i]= max(pwr_loc_i);
    
    % Set LOS delay in MIMO3D_Datagen for each location
    MIMO_params.LOS_analysis_tap = tap_i;
    MIMO_params.r0 = tap_i*MIMO_params.c/MIMO_params.Fs;

    if(Pwr_en)
        [Pwr_RTP_i,LOS(loc_i)] = MIMO3D_DataGen(H_mimo3D,MIMO_params);
        Pwr_RTP(loc_i,:,:,1:n_taps(loc_i)) = Pwr_RTP_i;        
    else
        [~,LOS(loc_i)] = MIMO3D_DataGen(H_mimo3D,MIMO_params,Pwr_en);
    end
end
%% Save MIMO Pwr(X,Y,Z) data to file
save('pCIR_area2_rratio_lim.mat','Pwr_RTP','LOS','n_taps','MIMO_params','-v7.3');

%% Plot power across locations
%r_ax = (0:size(pwr_loc,2)-1)*params.c/params.Fs;
%figure;imagesc(r_ax,1:samples,10*log10(pwr_loc));
%xlabel('Range (m)');ylabel('Location no.')
%title('MIMO Power across locations over time')


    
