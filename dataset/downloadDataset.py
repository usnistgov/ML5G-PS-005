# Legal Disclaimer
# NIST-developed software is provided by NIST as a public service. 
# You may use, copy and distribute copies of the software in any medium,
# provided that you keep intact this entire notice. You may improve,
# modify and create derivative works of the software or any portion of
# the software, and you may copy and distribute such modifications or
# works. Modified works should carry a notice stating that you changed
# the software and should note the date and nature of any such change.
# Please explicitly acknowledge the National Institute of Standards and
# Technology as the source of the software.
# 
# NIST-developed software is expressly provided "AS IS." NIST MAKES NO
# WARRANTY OF ANY KIND, EXPRESS, IMPLIED, IN FACT OR ARISING BY
# OPERATION OF LAW, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTY
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT
# AND DATA ACCURACY. NIST NEITHER REPRESENTS NOR WARRANTS THAT THE
# OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE, OR
# THAT ANY DEFECTS WILL BE CORRECTED. NIST DOES NOT WARRANT OR MAKE ANY 
# REPRESENTATIONS REGARDING THE USE OF THE SOFTWARE OR THE RESULTS 
# THEREOF, INCLUDING BUT NOT LIMITED TO THE CORRECTNESS, ACCURACY,
# RELIABILITY, OR USEFULNESS OF THE SOFTWARE.
# 
# You are solely responsible for determining the appropriateness of
# using and distributing the software and you assume all risks
# associated with its use, including but not limited to the risks and
# costs of program errors, compliance with applicable laws, damage to 
# or loss of data, programs or equipment, and the unavailability or
# interruption of operation. This software is not intended to be used in
# any situation where a failure could cause risk of injury or damage to
# property. The software developed by NIST employees is not subject to
# copyright protection within the United States.
# Title: A Python Script to download all the files for "Context-aware mmWave RF Signals Dataset with Lidar and Camera"
# Author: Raied Caromi
# Contact: evan.black@nist.gov, raied.caromi@nist.gov
# Requires: Python3, requests (https://pypi.org/project/requests/)

#%%
from pathlib import Path
import os
import time
import datetime
import hashlib
import requests
import sys
#%%

baseUrl = "https://data.nist.gov/rmm/records/"
recordID = "mds2-2645"

def webSavePy(url, output_path):
    # MAX_RETRIES = 2
    # WAIT_SECONDS = 5
    # for i in range(MAX_RETRIES):
        timeOut=20
        try:
            req = requests.get(url, stream = True,timeout=timeOut)
            fileSizeIsKnown=False
            chunkSize=4*1024*1024
            if 'Content-length' in req.headers:
                fileSize=int(req.headers['Content-length'])
                fileSizeIsKnown=True
                if chunkSize>fileSize:
                    chunkSize=fileSize
            else:
                chunkSize=1024
            progress=0.0
            bar_len = 60
            suffix=' Bytes Downloaded'
            with open(output_path, "wb") as myFile:
                for chunk in req.iter_content(chunk_size = chunkSize):
                    if chunk:
                        myFile.write(chunk)
                        progress+=chunkSize
                        if fileSizeIsKnown:
                            # if file size is known display text progress bar
                            progToFSize=min(progress/fileSize,1)
                            filled_len = int(round(bar_len * progToFSize))
                            percents = round(100.0 * progToFSize, 1)
                            bar = '=' * filled_len + '-' * (bar_len - filled_len)
                            suffix=' '+str(progress)+'/'+str(fileSize) +' Bytes Downloaded'
                            sys.stdout.write('[%s] %s%s ...%s\r' % (bar, percents, '%', suffix))
                            sys.stdout.flush()
                        else:
                            sys.stdout.write('%s ...%s\r' % (progress, suffix))
                            sys.stdout.flush()
            # break
        except requests.exceptions.ConnectionError as errc:
            print ("\n Failed on file:",url,"\n Error Connecting:",errc)
            sys.exit(1)
        except requests.exceptions.Timeout as errt:
            print ("\n Failed on file:",url,"\n Timeout Error:",errt)
            sys.exit(1)

#%% Create save directory 
saveDir = '.'
if saveDir[-1]!='/':
    saveDir=saveDir+'/'

if not(os.path.exists(saveDir)):
    os.mkdir(saveDir)
#%% Get json record of the dataset

requestURL=baseUrl+recordID
resp = requests.get(requestURL)
if resp.status_code != 200:
    print ("\n Failed to get dataset record form",requestURL, " with code:",resp.status_code)
    print("\n",print(resp.json()))
    sys.exit(1)
else:
    components=resp.json()['components']
# %% get file downloadable links and file sizes
getAllLinks=[]
getAllSizes=[]
getAllHashes=[]
for J in range(len(components)):
    for keys in components[J]:
        if keys=='downloadURL':
            getAllLinks.append(components[J]['downloadURL'].replace("%20"," "))
        if keys=='size':
            getAllSizes.append(components[J]['size'])
        if keys=='checksum':
            getAllHashes.append(components[J]['checksum'])        
# %% separate files and their hashes, i.e., files with .sha256
getFilesOnly=[]
getSizesOnly=[]
getFilesHashesLinks=[]
getFilesHashesNameOnly=[]
getFilesOnlyNameOnly=[]
getFilesHashesText=[]
for I in range(len(getAllLinks)):
    if getAllLinks[I][-len('sha256'):-1]=='sha25':
        getFilesHashesLinks.append(getAllLinks[I])
        getFilesHashesNameOnly.append(os.path.splitext(os.path.basename(getAllLinks[I]))[0])
    else:
        getFilesOnly.append(getAllLinks[I])
        getFilesOnlyNameOnly.append(os.path.basename(getAllLinks[I]))
        getFilesHashesText.append(getAllHashes[I]['hash'])
        if getAllSizes:
            getSizesOnly.append(getAllSizes[I])
# %% calculate the total download size
if getSizesOnly:
    totalSizeOfTheSetGB=sum(getSizesOnly)/pow(1024,3)
    print("\n There are ",len(getFilesOnly), " files in the dataset with a total size of ",totalSizeOfTheSetGB," GB")
else:
    print ("\n Size variable was empty")
# %% create directory structure for the download
allDirs = set()
allFilesToSave=[]
for K in range(len(getFilesOnly)):
    idPlace=getFilesOnly[K].find(recordID)
    allFilesToSave.append(str(Path(saveDir+getFilesOnly[K][idPlace+len(recordID):])))
    allDirs.add(str(Path(getFilesOnly[K][idPlace+len(recordID):]).parent))
uniqueDirs = list(allDirs)
# %% create the directories 
for L in range(len(uniqueDirs)):
    os.makedirs(saveDir+uniqueDirs[L], exist_ok=True)
# %% check if files exist and verify them, if a file has a wrong hash, remove it
print("\n Check if files already exist...")

Count_already_exist=0
Count_already_exist_and_correct=0
for x in allFilesToSave:
    if os.path.isfile(x):
        Count_already_exist+=1
readChunk=4*1024*1024
if Count_already_exist>0:
    print("\n",Count_already_exist," files already exist! Checking files integrity. This may take some time!")
    #Count_already_exist=0
    for M in range(len(getFilesOnly)):
        if os.path.isfile(allFilesToSave[M]):
            #get the hash from the file 
            print(" Checking file: ",getFilesOnlyNameOnly[M],"... ", end="", flush=True)     
            sha256_hash = hashlib.sha256()
            with open(allFilesToSave[M],"rb") as fin:
                # Read and update hash string value in blocks of readChunk
                for byte_block in iter(lambda: fin.read(readChunk),b""):
                    sha256_hash.update(byte_block)
                    sha256_hash.hexdigest()
            
            #if hashFileText==sha256_hash.hexdigest():
            if getFilesHashesText[M]==sha256_hash.hexdigest():
                print(" File has correct hash!")
                Count_already_exist_and_correct+=1
            else:
                print( " File has wrong hash! .. File Removed!")
                os.remove(allFilesToSave[M])
    print("\n",Count_already_exist," files were checked and ", Count_already_exist_and_correct , " files were correct.")

else:
    print("\n No file exist in the provided direcory:", saveDir)

#Count_already_exist_and_correct
files_exist_size=0
for x in allFilesToSave:
    if os.path.isfile(x):
        files_exist_size=files_exist_size+os.path.getsize(x)
#        Count_already_exist_and_correct+=1
#%% download files that do no it exist in the directory 
start_time_tr = time.time()
count_downloaded=0
count_failed=0
max_count_failed_to_quit=1
listOfFailedDownloads=[]
print("\n Attempting to download ",len(getFilesOnly)-Count_already_exist_and_correct, " files with a total size of ",totalSizeOfTheSetGB-files_exist_size/pow(1024,3),"GB!"
 ,"If script halts, run it again.")
for N in range(len(getFilesOnly)):
    if not(os.path.isfile(allFilesToSave[N])):
        print("Downloading File No ",N+1,", ",getFilesOnly[N],".")   
        webSavePy(getFilesOnly[N], allFilesToSave[N])
        #get the hash from the file 
        print("\n Checking if file downloaded correctly... ", end="", flush=True)  
        sha256_hash = hashlib.sha256()
        with open(allFilesToSave[N],"rb") as fin:
            # Read and update hash string value in blocks of readChunk
            for byte_block in iter(lambda: fin.read(readChunk),b""):
                sha256_hash.update(byte_block)
                sha256_hash.hexdigest()
        
        #if hashFileText==sha256_hash.hexdigest():
        if getFilesHashesText[N]==sha256_hash.hexdigest():
            count_downloaded+=1
            print("File: ",getFilesOnlyNameOnly[N], "Download Ok, Hash ok!")
        else:
            print("File: ",getFilesOnlyNameOnly[N], "Wrong Hash.. File Removed!")
            os.remove(allFilesToSave[N])
            listOfFailedDownloads.append(getFilesOnly[N])
            count_failed+=1
        if count_failed>=max_count_failed_to_quit:
            print("Something is wrong! ",max_count_failed_to_quit, " failed to download. Exiting program")
            break

print("\n Download time for",count_downloaded," files= %s hh:mm:ss ---" % datetime.timedelta(seconds=(time.time() - start_time_tr)))
print("\n",count_failed," files failed to download!")
print("\n Total number of the files in the dataset (newly downloaded and already exist)=", count_downloaded+Count_already_exist_and_correct)
