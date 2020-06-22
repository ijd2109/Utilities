#!/usr/bin/python3
######################################################################################################
# Purpose of this script:
# 
# Using the output from 00_getNifti.sh, collect information contained in the .json "sidecar" files
# that accompany each scan. The .json has information pertaining to the task name, the acquisition time,
# and other information that is informative about each NIFTI file (each scan).
#
# This information is output into a neat .csv, which later is used to then build folder and file paths
# that are consistnet with BIDS format.
#  
# ---------------- ----------------- ------------------- ---------------------- --------------------------
# For questions contact: Ian J. Douglas, idouglas@utexas.edu; idmail92@gmail.com; ijd2109@columbia.edu
# -------------------------- ---------------------- ------------------- ----------------- ----------------
#

# A. Import modules
import os # interact with operating system
import pandas as pd # reading and writing data frames
import numpy as np # numeric data manipulation
import glob # to imitate the * behavior in shell commands
import json # to read json files
import re # for string manipulation

# B. Read in the dicomFolderPaths.txt file [the output from 00_getNifti.sh]
#### The file is a simple text file that lists all paths to all dicoms found when running 00_getNifti.sh
#### These are the folders ending in /dicom (not the /nii directory that was created in dcm2niix)
dcmPaths = pd.read_table(
	'dicomFolderPaths.txt', # this text file containins the paths to ALL the above /nii folders
	header = 0, # tell python that there are no column names, thus the first entry is data
	names = ['path'] # this 1-element list means that the first column will be called 'path' 
)

# C. Edit the paths so that they begin with the root folder of the server directory where the dicoms live
for j in np.arange(dcmPaths.shape[0]):
  # The goal is to create the file path so it begins at the root directory of the server / computer file tree.
  # And then directs all the way to the NIFTI file. dicomFolderPaths.txt however has paths that just begin
  # where 00_getNifti.sh was run from, starting the a "."
  # Example:
  # This script was created originally for a project called <my_awesome_study>, so:
  # Replace the "." in ./<SubjectIDFolder>/<task>/ with <my_root_directory>/<my_awesome_study>/<SubjectIDFolder>/<task>/
    dcmPaths.loc[j, 'path'] = re.sub("^\.", "<my_root_directory>/<my_awesome_study>", dcmPaths.loc[j, 'path'])

# D. For each path to a dicom, there is also a nii folder, in which are NIFTI and JSON files for the scan run.
#### 1. Follow each path, check that the nii folder exists, check that the json file exists
#### 2. Extract from the json the 'ProtocolName' and 'AcquisitionTime' of each scan
#### 3. From the filename itself, extract the date (not time) of the scan

# Define empty lists to later take on the protocol (task) name of each scan, the time, and the date of the scan
protocol_name = []
acquisition_time = []
date_of_scan = []
# For debugging, define other lists that will add information inside the loop for later analysis if needed
#### path_successful = []
#### counter = 0 # for debugging, not used otherwise

# (1) 'For each row of the dicom folder paths data frame'
# Assign the path to an object called 'p'
for j in np.arange(dcmPaths.shape[0]): 
    p = dcmPaths.loc[j, 'path'] 
    #### For debugging (otherwise leave hashed out)
    # print(p)
    # counter += 1
        
    # (2) If the path itself actualy exists, and it contains a /nii dir, and in which exists a json file:
    # Explanation- path.exist(path) will return TRUE if path exists, path.exists(path + '/nii') will return
    # True if the path also extends to contain a directory called /nii (which would have been created)
    # When the .nii files were generated. But, len(glob.glob(path + '/nii/*json')) will check to make sure
    # that a .json file does exist there. It returns a list of length 0 if there is no match from glob.
    if os.path.exists(p) and os.path.exists(p + '/nii') and len(glob.glob(p + '/nii/*json')) == 1:
        # (3) Then extract the filepath to the json as a character string by indexing glob output (a list)
        # Note that the output from glob is a list ['path'].
        # We need to supply open() with a simple character string representing a filepath
        # We further have checked that only one json exists in the folder (which is to be expected)
        # So simply use glob.glob(...).pop() to extract the (last, and) only .json path in the list
        # Note, .pop() removes the element from the list, which is okay b/c its a temporary result from glob.glob
        jsonFilePath = glob.glob(p + '/nii/*json').pop()
            
        # (4) Extract the info from the json
        # Start with an if statement to ensure that we just extracted a json filepath:
        if jsonFilePath.endswith('json'): 
            # 4a. Open the file. This is more like, loading or accessing it.
            jsfile = open(glob.glob(p + '/nii/*json').pop())
            # 4b. Read the file. The file needs to be interpreted/parsed after it is "opened"
            jsdata = json.load(jsfile)
            # 4c. Add the protocol name (the task) to our running list of these values (for each loop iter.)
            protocol_name.append(jsdata['ProtocolName'])
            # 4d. Same for the acquisition time (time of scan)
            acquisition_time.append(jsdata['AcquisitionTime'])
                
            # (5). We also need the date, which is included in each json file's actual filename.
            # Based on prior knowledge of what these file names look like, extract the desired info.
            # The date always begins with an underscore and then the year "..._20110101....json"
            ## 5a. Pair down the file path so it deletes everything between (including /danl/.../nii/)
            filename = re.sub('^/.+/nii/', '', jsonFilePath)
            ## 5b. Create a "match object" using `re.search(PATTERN, MY_STRING)`
            match_object = re.search('_201[0-9]{5}', filename)
            ## 5c. Extract the matching segment using MY_MATCH_OBJECT.group()
            string_extraction = match_object.group()
            ## 5d. Using re.sub(), drop the leading "_"
            the_date = re.sub( '_', '', string_extraction) # remove the leading underscore
            ## 5e. Add breaks in the date so it goes from YYYYMMDD to YYYY-MM-DD
            date_formatted = the_date[0:4] + "-" + the_date[4:6] + "-" + the_date[6:9]
            # Append the data to the iteratively building list.
            date_of_scan.append(date_formatted)
                
            #### For debugging (otherwise skip):
            #### path_successful.append(p)
            #### print('nii folder contains ' + str(sum(are_json)) + ' file(s)')
            #### print((jsdata['ProtocolName'],jsdata['AcquisitionTime']))
            #### Following two lines are also for debugging, leave hashed out otherwise
            #### print(jstuple)
            #### jstuple = (jsdata['ProtocolName'], jsdata['AcquisitionTime'], counter)
                
        # (6) Now, for each if statement above, add an else statement.
        # The else statement will append the results lists we are building, but insert a message.
        # When we write out the final results of this procedure, any file paths that did not
        # lead to a json, or had other issues, will be easy to identify, and won't break the loop here.
        else:
            protocol_name.append('NO_JSON_FILE_IN_NII_DIR') # error message in place of task name
            acquisition_time.append(9999) # Another placeholder for failed paths
            date_of_scan.append('9999-01-01') # nonsensical date
    else: # for when it failed at the step `os.exists or glob.glob length == 1`
        protocol_name.append('BAD_FILEPATH')
        acquisition_time.append(9999)
        date_of_scan.append('9999-01-01')
# done 

# E. Add the information to the data frame, and write it out.
newDF = dcmPaths.assign(
	task_name = protocol_name, 
	scan_time = acquisition_time, 
	date = date_of_scan
)
newDF.to_csv('jsonSidecarDataProcessed.csv', # this gets further processed by .Rmd file!
             index = False) # no row names (just numbers here)
# Now we'll be ready to use the csv file jsonSidecarDataProcessed.csv in our next step!
# It will contain information extracted from the json associated with each NIFTI, and the file path.
