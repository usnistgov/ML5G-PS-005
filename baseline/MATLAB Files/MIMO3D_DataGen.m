%% Generates MIMO Pwr(theta,phi,r) profile from RX perspective (MIMO--> Lidar) : ITU challenge 2022 
% Author : Yeswanth Guddeti 
% Date : 19/10/2022

function[Pwr_Rthetaphi,LOS] = MIMO3D_DataGen(H_mimo3D,params,Pwr_en)

%%  Global params
    r0 = params.r0;%Abs LOS distance(m) = N_delay_taps*(1/1.76G)*3e8
    
    Fs=params.Fs;c = params.c;
    Mr = params.Mr;Nr = params.Nr;%RX antennas
    Mt = params.Mt;Nt = params.Nt;%TX antennas

    LOS_analysis_tap =params.LOS_analysis_tap;% Delay tap used to resolve LOS (AOA,AOD)
    Calc_mode = params.Calc_mode;
    Rx_en = params.Rx_en;% O/p Perspective 1: RX  0: Tx 

    %LOS param
    LOS.delay = r0/c;
%% Generate Power heatmap : Pwr_en 1/0
    %Pwr_en : 1 (GET Pwr(R,theta,phi) & LOS); 0 (GET LOS Only);
if~exist('Pwr_en','var')
    Pwr_en=1;
end
%% Spatial transform : Returns 2D AoA, AoD matrix 

    N_delay_taps = size(H_mimo3D,3);
    
    fft_mode=2;%Compute FFT at each beam ID (Rx x Tx)
    if(fft_mode==2)
        [H_beam] = MIMO3D_fns().Spatial_transform(H_mimo3D,Mr,Nr,Mt,Nt,fft_mode);
        % Reshape H_beam(2D) to H_AOA_AOD(4D)
        % Calculate LOS from H_AOA_AOD (4D) 
        if(strcmp(Calc_mode,'4D'))
            H_AOA_AOD = MIMO3D_fns().reshape_TP(H_beam);
            %% Resolve LOS path : returns AOA,AOD, timeframes of LOS path
            
            Pwr_AOA_AOD  = abs(H_AOA_AOD(:,:,:,:,LOS_analysis_tap)).^2;
            %% Find all peaks/clusters at t=1
            [pks_en] = MIMO3D_fns().Find_peaks(Pwr_AOA_AOD);%pks_en=4 for pk in 4D
            

            %% Find LOS cluster
            [AOA_LOS,AOD_LOS] = MIMO3D_fns().Find_LOS(Pwr_AOA_AOD,pks_en);

        % Calculate LOS from Hbeam (2D)
        elseif(strcmp(Calc_mode,'2D'))
            Pwr_beam  = abs(H_beam(:,:,LOS_analysis_tap)).^2;
            [pks_en] = MIMO2D_fns().Find_peaks(Pwr_beam);%pks_en=2 for pk in 2D
            [Ir,It] = MIMO3D_fns().Find_LOS(Pwr_beam,pks_en);
            AOA_LOS = ind2sub(size(zeros(Mr,Nr)),Ir);
            AOD_LOS = ind2sub(size(zeros(Mt,Nt)),It);
            H_AOA_AOD = MIMO3D_fns().reshape_TP(H_beam);
           
        end
    end
  
    %Convert matrix index to actual AOA,AOD values
    sinAOA_LOS = [(AOA_LOS(1)-Mr/2)/(Mr/2) (AOA_LOS(2)-Nr/2)/(Nr/2)];
    sinAOD_LOS = [(AOD_LOS(1)-Mt/2)/(Mt/2) (AOD_LOS(2)-Nt/2)/(Nt/2)];
    
    LOS.sinAOA = sinAOA_LOS;LOS.sinAOD = sinAOD_LOS;
    
    %% NULL LOS path from H
    LOS.Amplitude = squeeze(H_AOA_AOD(AOA_LOS(1),AOA_LOS(2),AOD_LOS(1),AOD_LOS(2),:));
    H_AOA_AOD(AOA_LOS(1),AOA_LOS(2),AOD_LOS(1),AOD_LOS(2),:) = 0;
 

    %% Return Pwr(R,theta,phi) of reflections from RX Perspective
    % By projecting AOD(r2) dim --> R(absolute dist/time) dim 

    %Pwr_Rthetaphi params
    LOS.taps = round(LOS.delay*Fs);
    R_taps = N_delay_taps; % t = r1+r2 
    Theta_taps = size(H_AOA_AOD,1);Phi_taps = size(H_AOA_AOD,2);

    Pwr_Rthetaphi = zeros(Theta_taps,Phi_taps,R_taps);
    if(Pwr_en)
        %ZF
        SNR_AOA_AOD = NaN([Mr Nr Mt Nt]);
        %For MMSE
        %[SNR_AOA_AOD] = MIMO3D_fns().snr_aoa_aod(H_rfl);
        for t = 1:N_delay_taps
            [Pwr_Rthetaphi] = MIMO3D_fns().AOD2r(Pwr_Rthetaphi,H_AOA_AOD(:,:,:,:,t),t,LOS,SNR_AOA_AOD,Rx_en);
        end

    end
end



