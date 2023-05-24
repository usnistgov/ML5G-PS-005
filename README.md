# Digital-twin-enabled 6G: Depth Map Estimation in mmWave systems

> Software and dataset resource for ITU AI/ML in 5G Challenge. 

<p align="center">
<img src="docs/gif/room_estimation.gif" alt="drawing">
</p>

* To participate to the challenge, please register on the official [ITU AI/ML in 5G Challenge platform](https://challenge.aiforgood.itu.int/match/matchitem/79).
* The presentation of the challenge is available at the following [link](https://www.youtube.com/watch?v=xaBS6Q6KgO0&ab_channel=AIforGood).

# Getting Started

The software does not require any installation procedure: simply download or clone the repository to your local folders.
To execute the baseline solution the follow library are required:
* open3d
* tensorflow
* mat73 (for generating .npy file)


## Download dataset

The dataset can be downloaded from [NIST Public Data Repository](https://doi.org/10.18434/mds2-2645)


To download the training dataset for the ITU-Challenge:

* Execute the matlab script dataset/downloadDataset.m or the python script dataset/downloadDataset.py.
In case of problems in downloading the dataset, you can request temporary access to download the data from  a [Shared folder](https://drive.google.com/drive/folders/1jGtE3UtdqgEkBojJ8OS7rYHA0H7kf6OW?usp=sharing). 

# Baseline solution
The baseline to beat is the winner [solution](https://github.com/ITU-AI-ML-in-5G-Challenge/ML5G-PS-004-Depth-map-estimation-in-6G-mmWave-systems) of the 2022 ITU AI/ML in 5G challenge. 

## Baseline folder structure

In baseline folder, there are 3 sub-folders: 
* Lidar_predicted : This contains the predicted LIDAR PCD for area 2 data.
* MATLAB Files: This folder contains the pre-processing code which is written in MATLAB.
* Python Files: This folder contains the ML model code, training weights and the pre-processed input.

NOTE-1: The predicted output PCD for the AREA 2 data (Output data for evaluation) is provided in the folder 'Lidar_predicted'. 

NOTE-2: In order to reproduce the output pcd files for area 2, please follow the procedure below although output pcd files are already provided in 'Lidar_predicted' folder.
'Lidar_predicted'  folder contains files with names 'LidarPred_xxxxxx.mat', where the output files suffix matches with the suffix of the input files "CIR_xxxxxx.mat"

Along with these three folders, report ('Report_ITU_PS0004_6GISAC.docx') is also available in this folder.

## Input Pre-processing

Input Pre-processing step: It uses the RF data (input of the problem statement) as input and produce the pre-processed input for the ML model.
Inpput: Given RF data
Output: Pre-processed input file (in the same folder, pre-processed file for area 2 is provided as 'pCIR_area2_rratio_lim.mat')
Folder contiaing the files : 'MATLAB Files'

Description: Using this pre-processing before ML, we deterministically transform bi-static MIMO data into Mono-static (LIDAR) format by removing effect of TX.

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


## ML Model for depth map prediciton

Folder containing files: 'Python Files'
Input: pre-processed input from pre-processing step (in the same folder, pre-processed file for area 2 is provided as 'pCIR_area2_rratio_lim.mat')
Output: PCD for predicted depth map

Assumption:
* Testing data (RF data of area2) is first preprocessed using MATLAB script (Step-1)
* File obtained from the MATLAB script has it's name "pCIR_area2_rratio_lim.mat"
* "pCIR_area2_rratio_lim.mat" file is then used in the python script for testing purpose


### Instructions
* Start with "Testing.ipynb" jupyter notebook execution
* Preprocessed data "pCIR_area2_rratio_lim.mat" would be sent into the code file as input.
*  We have already shared a preprocessed version of area2 samples in the submission folder. 
*  Also, the input file "pCIR_area2_rratio_lim.mat" is futhur converted into .npy format file for the ease of loading
   and processing the data further in the jupyter notebook.
*  The .npy file is named as "X_all_area2.npy". We have also saved an already generated version of this file in submission folder
*  Code for converting to .npy file is in the "Testing.ipynb" file (in comments)
*  Last cell of the notebook saves .pcd files

Results:
* The final predicted PCD files are stored in the folder 'Lidar_predicted' 
     - Naming format: Lidar_(sample_number).pcd
     - Example filename: LiderPred_000010.pcd
    
* Training script with the name "Training.ipynb" is also provided in the submission folder


Files shared for testing the samples:
*  'Testing.ipynb': File for testing prupose
*  'Training.ipynb': File for training purpose
*  'pCIR_area2_rratio_lim.mat': Pre-processed input for the ML model
*  'X_all_area2.npy' : Pre-processed input compatible for the Python files
*  'model_norm_cae_Ts_CL_ep100_ArrData_woReg_AA13_epc30.h5' - Training weights

Please Note: We will also be uploading some supplementary data files needed for training purpose to make the data loading faster 
(Such as LIDAR data for all the samples cambined in a variable). The supplementary files are : 
*  'X_all_area1.npy': Pre-processed input combined for all the samples of area 1
*  'X_all_area3.npy': Pre-processed input combined for all the samples of area 3
*  'Y_all_area1_0.25.npy': lidar PCD converted to the voxel grid of size 0.25m and combined for all the samples of area 1
*  'Y_all_area3_0.25.npy':lidar PCD converted to the voxel grid of size 0.25m and combined for all the samples of area 3
*  'filesName.mat': File containing the names of the input files (such as "CIR_xxxxxx.mat").

### Reference
* R. Xu, W. Dong, A. Sharma and M. Kaess, "[Learned Depth Estimation of 3D Imaging Radar for Indoor Mapping](https://ieeexplore.ieee.org/document/9981572)," 2022 IEEE/RSJ International Conference on Intelligent Robots and Systems (IROS), Kyoto, Japan, 2022, pp. 13260-13267, doi: 10.1109/IROS47612.2022.9981572.


# Contributing

We welcome contributions. Please note that all contributions are in the 
public domain. Your contributions will be acknowledged.
Here are some ways in which you can contribute:

* If you find an issue and want to submit a code change, please create a fork, 
make your changes and submit a pull request. Here are some instructions on 
how to proceed:
[Instructions on how to generate pull request from github](https://help.github.com/articles/creating-a-pull-request-from-a-fork/).

* Please open an issue if you find a problem.



# Authors & Main Contributors

This repository is maintained by [Steve Blandino](https://www.nist.gov/people/steve-blandino) (steve.blandino@nist.gov) and [Raied Caromi](https://www.nist.gov/people/raied-caromi) (raied.caromi@nist.gov).




# Related Work

The NIST Wireless Networks Division works with the networking industry to research, develop, promote, measure, and deploy emerging networking technologies and standards that revolutionize how networks are operated and used.
* [Millimeter-Wave Channel Sounding and Modeling](https://www.nist.gov/communications-technology-laboratory/wireless-networks-division/millimeter-wave-channel-sounding-and)

* [Future Wireless Communications Systems and Protocols](https://www.nist.gov/programs-projects/future-wireless-communications-systems-and-protocols)