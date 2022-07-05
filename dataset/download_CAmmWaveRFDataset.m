...%% Legal Disclaimer
    ...% NIST-developed software is provided by NIST as a public service.
    ...% You may use, copy and distribute copies of the software in any medium,
    ...% provided that you keep intact this entire notice. You may improve,
    ...% modify and create derivative works of the software or any portion of
    ...% the software, and you may copy and distribute such modifications or
    ...% works. Modified works should carry a notice stating that you changed
    ...% the software and should note the date and nature of any such change.
    ...% Please explicitly acknowledge the National Institute of Standards and
    ...% Technology as the source of the software.
    ...%
    ...% NIST-developed software is expressly provided "AS IS." NIST MAKES NO
    ...% WARRANTY OF ANY KIND, EXPRESS, IMPLIED, IN FACT OR ARISING BY
    ...% OPERATION OF LAW, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTY
    ...% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT
    ...% AND DATA ACCURACY. NIST NEITHER REPRESENTS NOR WARRANTS THAT THE
    ...% OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE, OR
    ...% THAT ANY DEFECTS WILL BE CORRECTED. NIST DOES NOT WARRANT OR MAKE ANY
    ...% REPRESENTATIONS REGARDING THE USE OF THE SOFTWARE OR THE RESULTS
    ...% THEREOF, INCLUDING BUT NOT LIMITED TO THE CORRECTNESS, ACCURACY,
    ...% RELIABILITY, OR USEFULNESS OF THE SOFTWARE.
    ...%
    ...% You are solely responsible for determining the appropriateness of
    ...% using and distributing the software and you assume all risks
    ...% associated with its use, including but not limited to the risks and
    ...% costs of program errors, compliance with applicable laws, damage to
    ...% or loss of data, programs or equipment, and the unavailability or
    ...% interruption of operation. This software is not intended to be used in
    ...% any situation where a failure could cause risk of injury or damage to
    ...% property. The software developed by NIST employees is not subject to
    ...% copyright protection within the United States.
    %% Title: A MATLAB Script to download all the files for "Context-aware mmWave RF Signals Dataset with Lidar and Camera" (CAmmWaveRFDataset)
%% Author: Raied Caromi
%% Contact: raied.caromi@nist.gov
%% set save directory name
clear;clc;
saveDir = pwd; % Download to current dir, change if different dir is desired
%% Get json record of the dataset
baseUrl='https://datapub.nist.gov/midas/ark:/88434/';
recordID='mds2-2645';

timeOut=40;
options = weboptions('Timeout',timeOut);
readOptions = weboptions('Timeout',timeOut,'ContentType','json');
requestURL=[baseUrl,recordID];
try
    resp = webread(requestURL,readOptions);
    components=resp.components;
catch err
    fprintf('Failed to get dataset record form: %s \n',requestURL)
    fprintf('%s \n',err.message)
end
findDownloadURL=cellfun(@(x) isfield(x,'downloadURL'),components);
allWithDownloadURL=components(findDownloadURL);
getAllLinks=cellfun(@(x)strrep(x.('downloadURL'),'%20',' '), allWithDownloadURL,'un',0);
hashFilesIndex=cellfun(@(x) strcmp(x(end-6:end),'.sha256'),getAllLinks);
getFilesLinks=getAllLinks(~hashFilesIndex);
getFilesHashesText=struct2table(cellfun(@(x)x.('checksum'), allWithDownloadURL)).hash;
getFilesHashesText=getFilesHashesText(~hashFilesIndex);

getFilesSizes=cellfun(@(x)x.('size'), allWithDownloadURL);
getFilesSizes=getFilesSizes(~hashFilesIndex);
%%

baseFilesIndex=contains(getFilesLinks,{});% e.g. '.csv'
getBaseLinks=getFilesLinks(baseFilesIndex);
getBaseHashesText=getFilesHashesText(baseFilesIndex);
idPlace=cellfun(@(x) strfind(x,['/',recordID,'/']),getBaseLinks);

if ~isempty(getBaseLinks)
    for J=1:numel(getBaseLinks)
        baseFileToSave{J,1}=fullfile(saveDir,getBaseLinks{J}(idPlace(J)+length(recordID)+2:end));
        outFile=websave(baseFileToSave{J,1},getBaseLinks{J},options);
        hash=GetFileHash(baseFileToSave{J,1});
        if strcmpi(hash,getBaseHashesText{J})
        else
            fprintf('Error downloading base files, file:%s has wrong Hash! file will be deleted... \n',baseFileToSave{J,1})
            delete(fileToSave);
        end
    end
end
%%
% getFilesLinks & getFileseHashesText
downloadArea='area1';
areaIndex=cellfun(@(x) contains(x,downloadArea),getFilesLinks);
getFilesLinks=getFilesLinks(areaIndex);
getFilesHashesText=getFilesHashesText(areaIndex);
getFilesSizes=getFilesSizes(areaIndex);

downloadOption = input('Download option, \nEnter (A) for all data, or (RL) for RF and Lidar data only:','s');
if ~(strcmpi(downloadOption,'A')|| strcmpi(downloadOption,'RL'))
    error('Error. Input must be A, or RL')
end

%%
switch downloadOption
    case {'A', 'a'}
        desiredIndex=true(numel(getFilesLinks),1);
    case {'RL', 'rl'}
        desiredIndex=~cellfun(@(x) contains(x,'camera/'),getFilesLinks);
end
getFilesOnly=getFilesLinks(desiredIndex);
getFilesHashesText=getFilesHashesText(desiredIndex);
getFilesSizes=getFilesSizes(desiredIndex);

idPlace=cellfun(@(x) strfind(x,['/',recordID,'/']),getFilesOnly);

getFilePathsOnly=cellfun(@(x,y) x(y+length(recordID)+2:end),getFilesOnly,num2cell(idPlace),'UniformOutput',false);

AllDirs=fileparts(getFilePathsOnly);
fullNoneRepeatedDirs=fullfile(saveDir,unique(AllDirs));
[~,ind]=sort(cellfun(@length,fullNoneRepeatedDirs));
fullNoneRepeatedDirs=fullNoneRepeatedDirs(ind);
%%
for I=1:numel(fullNoneRepeatedDirs)
    if ~exist(fullNoneRepeatedDirs{I}, 'dir')
        mkdir(fullNoneRepeatedDirs{I});
    end
end
allFilesToSave=fullfile(saveDir,getFilePathsOnly);
allFilesThatExist=cellfun(@isfile,allFilesToSave);
totalSizeOfTheSetGB=sum(getFilesSizes)/1024^3;
fprintf('There are %d files in the dataset with a total size of %f GB \n', length(getFilesOnly),totalSizeOfTheSetGB)
%%
fprintf('Check if files already exist...\n')

getFilesOnlyExists=getFilesOnly(allFilesThatExist);
getFilePathsOnlyExists=getFilePathsOnly(allFilesThatExist);
getFilesHashesTextExists=getFilesHashesText(allFilesThatExist);
getFilesSizesExists=getFilesSizes(allFilesThatExist);

countAlreadyExistAndCorrect=0;
NumOfFilesExists=numel(getFilesOnlyExists);
steps=100;
verifyFilesSteps=1:round(NumOfFilesExists/steps):NumOfFilesExists;
if NumOfFilesExists>0
    fprintf('%d files already exist! Checking existing files integrity. This may take some time! \n',NumOfFilesExists)
    for K=1:NumOfFilesExists
        fileName=getFilePathsOnlyExists{K};
        fileToSave=fullfile(saveDir,fileName);
        %track file verification by percentage
        if any( K==verifyFilesSteps)
            fprintf('Progress:%d%% of existing files verified... \n',round(K/NumOfFilesExists*100))
        end
        hash=GetFileHash(fileToSave);
        if strcmpi(hash,getFilesHashesTextExists{K})
            
            countAlreadyExistAndCorrect=countAlreadyExistAndCorrect+1;
        else
            fprintf('file:%s has wrong Hash!.. deleting file! \n',fileName);
            delete(fileToSave)
            
        end
    end
    fprintf('%d files were checked and %d files were correct. \n',NumOfFilesExists, countAlreadyExistAndCorrect )
else
    fprintf('No file exist in the provided direcory: %s \n', saveDir)
end
%recount file sizes in case some were deleted in the check
allFilesThatExist=cellfun(@isfile,allFilesToSave);
if any(allFilesThatExist)
    files_exist_size_GB=sum(struct2table(cellfun(@dir,allFilesToSave(allFilesThatExist))).bytes)/1024^3;
else
    files_exist_size_GB=0;
end
%%
% update files to be downloaded
getFilesOnlyUpdated=getFilesOnly(~allFilesThatExist);
getFilePathsOnlyUpdated=getFilePathsOnly(~allFilesThatExist);
getFilesHashesTextUpdated=getFilesHashesText(~allFilesThatExist);
getFilesSizesUpdated=getFilesSizes(~allFilesThatExist);

countDownloaded=0;
countFailed=0;
fprintf('Attempting to download %d files with a total size of %f GB! \n',length(getFilesOnly)-countAlreadyExistAndCorrect, totalSizeOfTheSetGB-files_exist_size_GB)
fprintf('\n This might take long time depending on the network and local storage speed. \n ')

NumOfFilesUpdated=numel(getFilesOnlyUpdated);
startTime=tic;
downloadedFilesSteps=1:round(NumOfFilesUpdated/steps):NumOfFilesUpdated;

for K=1:NumOfFilesUpdated
    
    fileName=getFilePathsOnlyUpdated{K};
    fileToSave=fullfile(saveDir,fileName);
    %track download by percentage
    if any( K==downloadedFilesSteps)
        fprintf('Progress:%d%% of files downloaded... \n',round(K/NumOfFilesUpdated*100))
    end
    outFile=websave(fileToSave,getFilesOnlyUpdated{K},options);
    hash=GetFileHash(fileToSave);
    if strcmpi(hash,getFilesHashesTextUpdated{K})
        countDownloaded=countDownloaded+1;
    else
        fprintf('Error, file:%s has wrong Hash! file will be deleted... \n',fileName)
        delete(fileToSave);
        countFailed=countFailed+1;
    end
end
elapsedTime=toc(startTime);
fprintf('Download time for %d files= %s hh:mm:ss ---\n',countDownloaded,datestr(elapsedTime/(24*60*60),'HH:MM:SS'))
fprintf('%d files failed to download! \n',countFailed)
fprintf('Total number of the files in the dataset (newly downloaded and already exist)=%d \n', countDownloaded+countAlreadyExistAndCorrect)

%%
function hash=GetFileHash(fileNamePath)
mddigest   = java.security.MessageDigest.getInstance('SHA-256');

bufsize = 4*1024*1024;

fid = fopen(fileNamePath);

while ~feof(fid)
    [currData,len] = fread(fid, bufsize, '*uint8');
    if ~isempty(currData)
        mddigest.update(currData, 0, len);
    end
end

fclose(fid);

hash = reshape(dec2hex(typecast(mddigest.digest(),'uint8'))',1,[]);

end
