#!/usr/bin/python3
######################################################################################################
# Purpose of this script:
# 
# Using the spreadsheet "bidsFilePaths.csv" (output from 02_jsonToBidsPaths.R), take .nii.gz and .json 
# files that currently exist in some location indicated in the spreadsheet column called "path", and
# move them to "bids_path". All necessary subdirectories will also be created in the process, if they
# don't already exist. Lasty, a small but necessary edit will be made to the .json file itself so that
# it is formatted correctly for BIDS validation.
#
# ---------------- ----------------- ------------------- ---------------------- --------------------------
# For questions contact: Ian J. Douglas, idouglas@utexas.edu; idmail92@gmail.com; ijd2109@columbia.edu
# Check for updates at https://github.com/ijd2109/Utilities/tree/master/BIDSifying
# -------------------------- ---------------------- ------------------- ----------------- ----------------
#

# PART 1
# Import required modules
import os # interact with operating system
import pandas as pd # reading and writing data frames
import numpy as np # numeric data manipulation
import glob # to imitate the * behavior in shell commands
import csv # to read csv files
import re # for string manipulation
import json # read and edit json files

# PART 2
# Read in the spreadsheet where we classified each scan by its old filepath, and built its BIDS filepath
bidsFilePaths = pd.read_csv('bidsFilePathsV01.csv')
# Select only the old filepath, and the bids filepath
justPaths = bidsFilePaths[['path','BIDS_path']]
# initialize a running list of the paths to the jsons, because they will need to be edited after being copied
jsonPathList = []
taskDataList = [] # to store the corresponding data
# PART 3
for j in np.arange(justPaths.shape[0]): # for each row of justPaths
    # PART 3a
    # Define some folders based on the elements of the path
    p = justPaths.loc[j, 'path']
    bp = justPaths.loc[j, 'BIDS_path']
    root  = '/danl/SB/bids'
    subject = re.search('sub-[0-9]{3}', bp).group() # subject ID
    session = re.search('ses-[0-9]{1}', bp).group() # session #
    filename = re.search('sub-[0-9]{3}_ses.+$', bp).group() # filename plus extension
    if 'anat' in bp:
        taskType = 'anat'
    else:
        taskType = 'func'
    # end if
    # The path to the json file:
    jsonPath = re.sub('.nii.gz' , '.json', bp)
    
    # PART 3b
    # Set up a list of commands to first
    #### (1) cd into the root of the SB bids directory
    #### (2) build the entire file tree for this given NIFTI file
    #### (3) Copy (and rename) the NIFTI
    #### (4) Copy over (and rename) the json as well
    cmd1 = 'cd ' + root
    cmd2 = 'mkdir ' + root + '/' + subject # make the subject subdir
    cmd3 = 'mkdir ' + root + '/' + subject + '/' + session # make the session subdir
    cmd4 = 'mkdir ' + root + '/' + subject + '/' + session + '/' + taskType # make the func|anat subdir
    cmd5 = 'cp ' + p + '/nii/*nii.gz ' + bp # copy over the nifti
    cmd6 = 'cp ' + p + '/nii/*json ' + jsonPath # copy over the json
    # put all these into one single command line sequence separated by semi-colon
    cmdline = cmd1 + ';' + cmd2 + ';' + cmd3 + ';' + cmd4 + ';' + cmd5 + ';' + cmd6
    # Run the commands
    os.system(cmdline)
    # Lastly, add to the running list of .json paths
    jsonPathList.append(jsonPath) # note json path is a mutable list, does not need to be reassigned using "="
# Done.

# PART 4
# Read in the json file, edit it, overwrite it back out in place. As follows:
#### Call `file = open(filepath, mode)` with mode as "r" to open a stream of file for reading. 
#### Call json.load(file) to return the JSON object from file of the previous step. 
#### Call file.close() to close the file-reading stream.
# Edit the data that has been read in from the json:
#### Use the indexing syntax json_object[item] = value
# Writing it back out:
#### Call open(file, mode) with mode as "w" to open a stream of file for writing. 
#### Call json.dump(data, file), where data is the information we edited. 
#### Call file.close() to close the file-writing stream.

for i in range(jsonPathList):
    if os.path.exists(jsonPathList[i]):
        f = open(file=jsonPathList[i], mode="r") # open it in read mode
        jdata = json.load(f)
        f.close()
        # Edit it
        jdata['TaskName'] = bidsFilePaths.loc[i, 'jsonTaskName']
        # Write it out (after opening it again, in write mode)
        f = open(file=jsonPathList[i], mode="w") # here open it in write mode
        json.dump(jdata, f)
        f.close()
# done.
# Bidsifying done!! You are ready to run the BIDS-validator: https://bids-standard.github.io/bids-validator/
