function  funs = MIMO2D_fns()
funs.Spatial_transform = @Spatial_AoA_AoD_transform;
funs.Find_peaks = @Find_peaks;
funs.Find_LOS = @Find_LOS;
funs.NULL_LOS = @NULL_LOS;
funs.AOD2r = @AOD2r;
end

function [W_AoA_AoD,W_AoA] = Spatial_AoA_AoD_transform(W,Mr,Nr,Mt,Nt)

% AoA by 2D fft across each column
W_AoA = zeros(Mr,Nr,Mt*Nt);

for TXant = 1:Mt*Nt
    W_i = reshape(W(:,TXant),Mr,Nr);
    W_AoA(:,:,TXant) = fftshift(fft2(W_i));
end

% AoD by 2D fft at each AoA
W_AoA_AoD = zeros(Mr,Nr,Mt,Nt);

for theta_AoA = 1:Mr
    for phi_AoA = 1:Nr
        W_AoA_i = reshape(W_AoA(theta_AoA,phi_AoA,:),Mt,Nt);
        W_AoA_AoD(theta_AoA,phi_AoA,:,:) = fftshift(fft2(W_AoA_i));
    end
end

end


function [pks_en] = Find_peaks(Pwr_AOA_AOD)

pks_en = zeros(size(Pwr_AOA_AOD));%Flags for peak
Mr=size(Pwr_AOA_AOD,1);Mt=size(Pwr_AOA_AOD,2); 

for i = 1:Mt% Finding peaks in AOA for each AOD angle
    [~,locs_i,~,~] = findpeaks(Pwr_AOA_AOD(:,i));
    pks_en(locs_i,i)=pks_en(locs_i,i)+1;
end

for j = 1:Mr % Finding peaks in AOD for each AOA angle
    [~,locs_j,~,~] = findpeaks(Pwr_AOA_AOD(j,:));
    pks_en(j,locs_j)=pks_en(j,locs_j)+1;
end

%Find Peaks in 2D (AOA & AOD)
%pklocs_2D = find(pks_en==2);

end

function [AOA_LOS,AOD_LOS] = Find_LOS(Pwr_AOA_AOD,pks_en)
data_pk = zeros(size(Pwr_AOA_AOD));
data_pk(pks_en==2) = Pwr_AOA_AOD(pks_en==2);

%Mr=size(Pwr_AOA_AOD,1);Mt=size(Pwr_AOA_AOD,2); 

%LOS peak : Least delay;highest Pwr ; Tightest (low width) ;Lower AOA,AOD ; 
[~,I] = max(data_pk,[],"all");%LOS : Find highest Pwr peak (for now)
%y_maxpk = mod(I,Mt);x_maxpk= ceil(I/Mt);

%[r_maxpk,c_maxpk]= ind2sub(size(data_pk),I);
%sinAOD_LOS = (c_maxpk-Mt/2)/(Mt/2); sinAOA_LOS = (r_maxpk-Mr/2)/(Mr/2) ;
[AOA_LOS,AOD_LOS]= ind2sub(size(data_pk),I);
end

function [rfl_en] = NULL_LOS(Pwr_AOA_AOD,x_LOS,y_LOS)
Pwr_LOS = Pwr_AOA_AOD(x_LOS,y_LOS);
LOS_nbr_x = x_LOS+(-2:2);LOS_nbr_y = y_LOS+(-2:2) ;%Check 2 adj. bins along both axes
LOS_nbr_en = (Pwr_AOA_AOD(LOS_nbr_x,LOS_nbr_y,1) > Pwr_LOS/10);%10dB below LOS pk as threshold

rfl_en = ones(size(Pwr_AOA_AOD));
rfl_en(LOS_nbr_x,LOS_nbr_y) = ~LOS_nbr_en;

%H_rfl = H_AOA_AOD();%H_rfl : H of reflections
%H_rfl(x_LOS,y_LOS,:)=0;% Set H=0@ LOS_theta  over time
end

%Projecting AOD(r2) to time/R dim

function [H_Rtheta] = AOD2r(H_Rtheta,H_rfl,delay_tap,LOS,AOD2r_en)
%Return (R,theta) of reflections : By projecting AOD(r2) dim --> R(absolute dist/time) dim 
% 1. Calculate r2/r1 (r2 = r_tx;r1 = r_rx)
% 2. Project AOD to R

%AOD2r_en : 1 (GET RX Pwr(R,theta)); 0 (GET TX Pwr(R,theta));
if~exist('AOD2r_en','var')
    AOD2r_en=1;
end

Mr=size(H_rfl,1);Mt=size(H_rfl,2); 

%LOS_taps = ceil(LOS.delay*Fs);
t_abs = delay_tap+LOS.taps;%t_abs : Absolute time taps

Sin = @(sinA,sinB) sinA*sqrt(1-sinB^2) - sqrt(1-sinA^2)*sinB;%y = Sin(A-B) 
%y = @(sinA,sinB) sinA*sqrt(1-sinB^2) - sqrt(1-sinA^2)*sinB;%y = Sin(A-B) 
% ??Projections only for pks OR H_rfl > thres OR for all H_rfl
for x = 1:Mr
    for y = 1:Mt
        sinAOD = (y-Mt/2)/(Mt/2);sinAOA = (x-Mr/2)/(Mr/2);

        %r_tx/r_rx = sin(AOA_pk - AOA_LOS)/sin(AOD_pk - AOD_LOS)
        r_ratio = abs(Sin(sinAOA,LOS.sinAOA)/Sin(sinAOD,LOS.sinAOD));

        % Project AOA2r instead & Get TX perspective
        if(~AOD2r_en);r_ratio = 1/r_ratio;end

        % if LOS path
        if(isnan(r_ratio)); continue;end 
        
        % Project back in time to get r1 : t_abs*r1/(r1+r2)
        t_proj = t_abs/(1+r_ratio);
        if(t_proj>1); t_indx = round(t_proj); else; t_indx = 1; end

        % Scale power : TX-Rfl-RX --> RX-Rfl-RX [(r1*r2)^2 --> (r1*r1)^2]
        H_Rtheta(x,t_indx) = H_Rtheta(x,t_indx)+ H_rfl(x,y)*r_ratio;
        
    end
end
end