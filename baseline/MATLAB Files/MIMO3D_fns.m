function  funs = MIMO3D_fns()
funs.Spatial_transform = @Spatial_AoA_AoD_transform;
funs.reshape_TP = @reshape_TP;
funs.Find_peaks = @Find_peaks;
funs.Find_LOS = @Find_LOS;
funs.AOD2r = @AOD2r;
funs.snr_aoa_aod = @snr_aoa_aod;
end

function [W_AoA_AoD,W_mid] = Spatial_AoA_AoD_transform(W,Mr,Nr,Mt,Nt,fft_mode)

if~exist('fft_mode','var')
    fft_mode=1;
end
if(fft_mode==1) % 1: 2D FFT across AOA & AOD for 1 tap
    % AoA by 2D fft across each column
    W_AoA = zeros(Mr,Nr,Mt*Nt);
    
    for TXant = 1:Mt*Nt
        W_i = reshape(W(:,TXant),Mr,Nr);
        W_AoA(:,:,TXant) = fftshift(fft2(W_i));
    end
    W_mid = W_AoA;
    % AoD by 2D fft at each AoA
    W_AoA_AoD = zeros(Mr,Nr,Mt,Nt);
    
    for theta_AoA = 1:Mr
        for phi_AoA = 1:Nr
            W_AoA_i = reshape(W_AoA(theta_AoA,phi_AoA,:),Mt,Nt);
            W_AoA_AoD(theta_AoA,phi_AoA,:,:) = fftshift(fft2(W_AoA_i));
        end
    end
    
end
if(fft_mode==2)% 2: H_beam for 64 RX & 64 TX beamIDs for all taps
    nTxAnt = size(W,2);
    nRxAnt = size(W,1);
    N_delay_taps = size(W,3);

    H_beam = zeros(nRxAnt,nTxAnt,N_delay_taps);
    %W_AoA_AoD = zeros(sqrt(nRxAnt),sqrt(nRxAnt),sqrt(nTxAnt),sqrt(nTxAnt));
    dftCbTxV = dftmtx(sqrt(nTxAnt));dftCbTxH = dftmtx(sqrt(nTxAnt));
    dftCbRxV = dftmtx(sqrt(nRxAnt));dftCbRxH = dftmtx(sqrt(nRxAnt));

    dftCbTx = kron(dftCbTxV,dftCbTxH);
    dftCbRx = kron(dftCbRxV,dftCbRxH);

    for t = 1:N_delay_taps
        H_beam(:,:,t) = dftCbRx'*W(:,:,t)*dftCbTx;
    end
    H_beam = fftshift(H_beam);
    %W_mid = H_beam;
    W_AoA_AoD=H_beam;
end
end

%reshape H_beam(2D) to H_AOA_AOD(4D) i.e Expand(Theta,Phi)
function[H_AOA_AOD] = reshape_TP(H_beam)
nTxAnt = size(H_beam,2);Mt = sqrt(nTxAnt);Nt =sqrt(nTxAnt);
nRxAnt = size(H_beam,1);Mr = sqrt(nRxAnt);Nr =sqrt(nRxAnt);   
N_delay_taps = size(H_beam,3);
H_AOA_AOD = zeros(Mr,Nr,Mt,Nt,N_delay_taps);
for t=1:N_delay_taps
    for Rxant = 1:Mr*Nr
        [AOA_Phi,AOA_Theta]=ind2sub(size(zeros(Mr,Nr)),Rxant);
        temp =reshape(H_beam(Rxant,:,t),Mt,Nt).';
        H_AOA_AOD(AOA_Theta,AOA_Phi,:,:,t) = temp;
    end
end

end


function [pks_en] = Find_peaks(Pwr_AOA_AOD)

pks_en = zeros(size(Pwr_AOA_AOD));%Flags for peak
Mr=size(Pwr_AOA_AOD,1);Nr=size(Pwr_AOA_AOD,2);
Mt=size(Pwr_AOA_AOD,3);Nt=size(Pwr_AOA_AOD,4);


% For each AOD angle : Find peaks in AOA
for It = 1:Mt*Nt
    [i,j] = ind2sub(size(zeros(Mt,Nt)),It);
    pks_en_t = MIMO2D_fns().Find_peaks(squeeze(Pwr_AOA_AOD(:,:,i,j)));
    pks_en_init = squeeze(pks_en(:,:,i,j));
    pks_en(:,:,i,j) = pks_en_init + pks_en_t;
    %end
end

% For each AOA angle : Find peaks in AOD
 for Ir = 1:Mr*Nr 
     [i,j] = ind2sub(size(zeros(Mr,Nr)),Ir);%T : Theta ; P : Phi
    pks_en_r = MIMO2D_fns().Find_peaks(squeeze(Pwr_AOA_AOD(i,j,:,:)));
    pks_en_init = squeeze(pks_en(i,j,:,:));
    pks_en(i,j,:,:) = pks_en_init + pks_en_r;
    %end
end


end

function [AOA_LOS,AOD_LOS] = Find_LOS(Pwr_AOA_AOD,pks_en)
data_pk = zeros(size(Pwr_AOA_AOD));
data_pk(pks_en==4) = Pwr_AOA_AOD(pks_en==4);


%LOS peak : Least delay;highest Pwr ; Tightest (low width) ;Lower AOA,AOD ; 
[~,I] = max(data_pk,[],"all");%LOS : Find highest Pwr peak (for now)


[AOATheta_maxpk,AOAPhi_maxpk,AODTheta_maxpk,AODPhi_maxpk] = ind2sub(size(data_pk),I);

AOA_LOS = [AOATheta_maxpk AOAPhi_maxpk];
AOD_LOS = [AODTheta_maxpk AODPhi_maxpk];
end

%Projecting AOD(r2) to time/R dim

function [Pwr_Rthetaphi] = AOD2r(Pwr_Rthetaphi,H_rfl,delay_tap,LOS,SNR_AOA_AOD,AOD2r_en)
%Return (R,theta) of reflections : By projecting AOD(r2) dim --> R(absolute dist/time) dim 
% 1. Calculate r2/r1 (r2 = r_tx;r1 = r_rx)
% 2. Project AOD to R

%AOD2r_en : 1 (GET RX Pwr(R,theta)); 0 (GET TX Pwr(R,theta));
if~exist('AOD2r_en','var')
    AOD2r_en=1;
end

Mr=size(H_rfl,1);Nr=size(H_rfl,2);
Mt=size(H_rfl,3);Nt=size(H_rfl,4);

%% Inline functions
%y = sqrt(1-x^2)% x : sin; y : cos
Cos = @(sinA) sqrt(1-sinA^2);
Sin = @(CosA) sqrt(1-CosA^2);
%Sin(A-B)
SinAB = @(sinA,sinB) sinA*sqrt(1-sinB^2) - sqrt(1-sinA^2)*sinB;
%y = Cos(delta(Theta),delta(Phi)) % cos(Angle) btwn 2 polar vectors.
Cos_TP = @(sinT1,sinP1,sinT0,sinP0) sinT1*sinT0*Cos(SinAB(sinP1,sinP0)) + Cos(sinT1)*Cos(sinT0);

%% 
for Ir = 1:Mr*Nr % For each AOA angle : Project AOD in time
    [Tr,Pr] = ind2sub(size(zeros(Mr,Nr)),Ir);%T : Theta ; P : Phi
    sinAOA(1) = (Tr-Mr/2)/(Mr/2);sinAOA(2) = (Pr-Nr/2)/(Nr/2);
    for It = 1:Mt*Nt
        [Tt,Pt] = ind2sub(size(zeros(Mt,Nt)),It);
        sinAOD(1) = (Tt-Mt/2)/(Mt/2);sinAOD(2) = (Pt-Nt/2)/(Nt/2);
        
        % @r1+r2 > r0 : Project AODs back in time
        if(delay_tap>LOS.taps)
            %r_tx/r_rx = sin(AOA_pk - AOA_LOS)/sin(AOD_pk - AOD_LOS)
            
            Cos_TP_AOA = Cos_TP(sinAOA(1),sinAOA(2),LOS.sinAOA(1),LOS.sinAOA(2));
            Cos_TP_AOD = Cos_TP(sinAOD(1),sinAOD(2),LOS.sinAOD(1),LOS.sinAOD(2));
            r_ratio = abs(Sin(Cos_TP_AOA)/Sin(Cos_TP_AOD));
            
            % Project AOA2r instead & Get TX perspective
            if(~AOD2r_en);r_ratio = 1/r_ratio;end
    
            % if LOS path : AOA = LOS.AOA & AOD = LOS.AOD
            if(isnan(r_ratio)); continue;end 

            %if reflectors close to RX : AOA ~= LOS.AOA & AOD = LOS.AOD
            if(isinf(r_ratio)); continue;end %Ignore RX close reflections
            if(r_ratio>1e1);continue;end
    
            %if reflectors close to TX : AOA = LOS.AOA & AOD ~= LOS.AOD
            if((r_ratio==0)); continue;end %Ignore TX close reflections
            if(r_ratio<1e-1);continue;end

            % Project back in time to get r1 : t_abs*r1/(r1+r2)
            t_proj = delay_tap/(1+r_ratio);
            
            if(t_proj>1); t_indx = round(t_proj); else; t_indx = 1; end
        else %@r<r0 Project AoDs at same time index
            t_indx = delay_tap;
            r_ratio = 1;
        end

        % Scale power : TX-Rfl-RX --> RX-Rfl-RX [(r1+r2)^2 --> (2*r1)^2]     
        if(isnan(SNR_AOA_AOD(Tr,Pr,Tt,Pt)))%ZF
            W_eq = r_ratio;%(1/2)*(1+r_ratio) ;
        else%MMSE
            W_eq = r_ratio*(1/(1 + 1/SNR_AOA_AOD(Tr,Pr,Tt,Pt)));
        end
        
        if(AOD2r_en)%Project AOD2r : Get reflections From Rx perspective
            Pwr_Rthetaphi(Tr,Pr,t_indx) = Pwr_Rthetaphi(Tr,Pr,t_indx)+ abs(H_rfl(Tr,Pr,Tt,Pt)*W_eq).^2;
        else%Project AOA2r : Get reflections From Tx perspective
            Pwr_Rthetaphi(Tt,Pt,t_indx) = Pwr_Rthetaphi(Tt,Pt,t_indx)+ abs(H_rfl(Tr,Pr,Tt,Pt)*W_eq).^2;
        end        
    end
end
end


% SNR at each (AOA,AOD) over time : For MMSE equalization
%
function[SNR_AOA_AOD] = snr_aoa_aod(H_rfl)
Mr=size(H_rfl,1);Nr=size(H_rfl,2);
Mt=size(H_rfl,3);Nt=size(H_rfl,4);
SNR_AOA_AOD = NaN(size(zeros(Mr,Nr,Mt,Nt)));% If Nan :Instead apply ZF equalization
for Ir = 1:Mr*Nr % For each AOA angle :
    [Tr,Pr] = ind2sub(size(zeros(Mr,Nr)),Ir);%T : Theta ; P : Phi
    for It = 1:Mt*Nt
        [Tt,Pt] = ind2sub(size(zeros(Mt,Nt)),It);
        H_n = squeeze(H_rfl(Tr,Pr,Tt,Pt,:));
        [~,Idx] = max(H_n);
        %SNR(AOA,AOD) : Multiple pks over time
        sig_pwr = abs(H_n(Idx))^2;
        noise_pwr = (1/(numel(H_n)-1))*(sum(abs(H_n).^2)-abs(H_n(Idx))^2);
        SNR_AOA_AOD(Tr,Pr,Tt,Pt) = sig_pwr/noise_pwr ;
    end

end
end
