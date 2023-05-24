Objective : 
Depth estimation of the room by fitting  MIMO channel data to LIDAR data.
----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------
In this submission folder ('Submission_6G_ISAC_PS-0004'), there are 3 folders: 
1. 'Lidar_predicted' : This contains the predicted LIDAR PCD for area 2 data.
2. 'MATLAB Files': This folder contains the pre-processing code which is written in MATLAB.
3. 'Python Files': This folder contains the ML model code, training weights and the pre-processed input.

Please NOTE: The predicted output PCD for the AREA 2 data (Output data for evaluation) is provided in the folder 'Lidar_predicted'. 
NOTE-2: In order to reproduce the output pcd files for area 2, please follow the procedure below although output pcd files are already provided in 'Lidar_predicted' folder.
'Lidar_predicted'  folder contains files with names 'LidarPred_xxxxxx.mat', where the output files suffix matches with the suffix of the input files "CIR_xxxxxx.mat"

Along with these three folders, report ('Report_ITU_PS0004_6GISAC.docx')is also available in this folder.
Further instructions to re-produce the output pcd files for area-2 are explained below in this readme file: 
----------------------------------------------------------------------------------------------------------------------------------------------
-----------------Step-1 : Input Pre-processing------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------
Input Pre-processing step: It uses the RF data(input of this problem) as input and produce the pre-processed input for the ML model.
Inpput: Given RF data
Output: Pre-processed input file (in the same folder, pre-processed file for area 2 is provided as 'pCIR_area2_rratio_lim.mat')
Folder contiaing the files : 'MATLAB Files'

Description: Using this pre-processing before ML,we deterministically transform bi-static MIMO data into Mono-static(LIDAR) format by removing effect of TX.

Function Hierarchy :
MIMOlocs_tb.m (Testbench script across locations)
    |
    |--> MIMO3D_DataGen.m (Top function)
    |           |---> MIMO3D_fns.m (fns for processing 3D data)
    |           |---> MIMO2D_fns.m (fns for processing 2D data)

Function Descriptions:
MIMOlocs_tb.m - Takes in Datapath of rf folder & saves Pre-processed data across locations in .mat file.

MIMO3D_DataGen.m -
[Pwr_RTP,LOS] = MIMO3D_DataGen(H_mimo3D,MIMO_params);
% Returns 
% 1.Pwr_RTP (3D matrix): Power of reflections as seen by RX at each (r,theta,phi) bin .
% 2.LOS (struct).sinAoA(1x2 double),.sinAoD(1x2 double),.taps(int),.delay(float),.Amplitude(1xmax_taps complex)
% LOS path parameters

MIMO3D_fns.m 
    |--> Spatial_transform : Calculates Channel gain at each (RxBeamID,TxBeamID)
    |--> reshape_TP: Expands dimension of channel gain matrix from 2D to 4D. Each BeamID maps to (theta,phi) 
    |--> Find_peaks: Find BeamIDs (RxBeamID,TxBeamID) of LOS & reflected paths
    |--> Find_LOS: Selects BeamID of LOS among all paths.
    |--> AOD2r: Returns Powermap of reflections as seen from Rx by projecting AoDs back in time.


Example Script for MIMO3D_DataGen.m:

CIR = load(filename+'.mat');
H_mimo3D = CIR.mimoCir;

pwr = squeeze(sum(abs(H_mimo3D).^2,[1 2]));
[~,tap_LOS]= max(pwr);

MIMO_params.Mr = 8;MIMO_params.Nr = 8;%RX antennas
MIMO_params.Mt = 8;MIMO_params.Nt = 8;%TX antennas
MIMO_params.Fs=1.76e9;MIMO_params.c = 3e8;
MIMO_params.LOS_analysis_tap = tap_LOS;
MIMO_params.r0 = tap_i*MIMO_params.c/MIMO_params.Fs;

[Pwr_RTP,LOS] = MIMO3D_DataGen(H_mimo3D,MIMO_params);


-------------------------------------------------------------------------------------------------------------------------------------------------
-----------------Step-2 : ML Model for depth map prediciton------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
Folder containing files: 'Python Files'
Input: pre-processed input from pre-processing step (in the same folder, pre-processed file for area 2 is provided as 'pCIR_area2_rratio_lim.mat')
Output: PCD for predicted depth map

Assumption:
1) Testing data (RF data of area2) is first preprocessed using MATLAB script (Step-1)
2) File obtained from the MATLAB script has it's name "pCIR_area2_rratio_lim.mat"
3) "pCIR_area2_rratio_lim.mat" file is then used in the python script for testing purpose

Required libraries
** open3d
** tensorflow
** mat73 (for generating .npy file)

Instructions:
1) Start with "Testing.ipynb" jupyter notebook execution
2) Preprocessed data "pCIR_area2_rratio_lim.mat" would be sent into the code file as input.
3) We have already shared a preprocessed version of area2 samples in the submission folder. 
4) Also, the input file "pCIR_area2_rratio_lim.mat" is futhur converted into .npy format file for the ease of loading
   and processing the data further in the jupyter notebook.
5) The .npy file is named as "X_all_area2.npy". We have also saved an already generated version of this file in submission folder
6) Code for converting to .npy file is in the "Testing.ipynb" file (in comments)
7) Last cell of the notebook saves .pcd files

Results:
** The final predicted PCD files are stored in the folder 'Lidar_predicted' 
     - Naming format: Lidar_(sample_number).pcd
     - Example filename: LiderPred_000010.pcd
    
** Training script with the name "Training.ipynb" is also provided in the submission folder


Files shared for testing the samples
1) 'Testing.ipynb': File for testing prupose
2) 'Training.ipynb': File for training purpose
3) 'pCIR_area2_rratio_lim.mat': Pre-processed input for the ML model
4) 'X_all_area2.npy' : Pre-processed input compatible for the Python files
5) 'model_norm_cae_Ts_CL_ep100_ArrData_woReg_AA13_epc30.h5' - Training weights

Please Note: We wil also be uplaoding some supplementary data files needed for trianing purpose to make the data loading faster 
(Such as LIDAR data for all the samples cambined in a variable). The supplementary files are : 
1. 'X_all_area1.npy': Pre-processed input combined for all the samples of area 1
2. 'X_all_area3.npy': Pre-processed input combined for all the samples of area 3
3. 'Y_all_area1_0.25.npy': lidar PCD converted to the voxel grid of size 0.25m and combined for all the samples of area 1
4. 'Y_all_area3_0.25.npy':lidar PCD converted to the voxel grid of size 0.25m and combined for all the samples of area 3
5. 'filesName.mat': File containing the names of the input files (such as "CIR_xxxxxx.mat").
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------