#!/usr/bin/bash
######################################################################################################
# Purpose of this script:
# 
# From the root node of the repository, find all the dicom files.
# (It is assumed that the dicoms, resulting from fMRI or MRI scans, are stored
## in some recognizeable folders, such as "<something/something/something/DICOMS".
# The User of this script should know where to look for these files.
# IF NOT, the user can try a more sophisticated search, by searching by file type.
# This script does not implement that, but it could be done using the Linux command `file`.)
#  
# Next, convert the dicoms, which are TRs, to a NIFTI
# This script will also store the resultant .nii (NIFTI) file in a sub-subdirectory called nii.
#
# NOTE: this script requires dcm2niix, a bash command, to be installed on your machine/server.
#
# ---------------- ----------------- ------------------- ---------------------- --------------------------
# For questions contact: Ian J. Douglas, idouglas@utexas.edu; idmail92@gmail.com; ijd2109@columbia.edu
# -------------------------- ---------------------- ------------------- ----------------- ----------------
#

# 1:
# `cd` into the root directory for the study.
## Ideally, all dicoms in any subdirectories below this folder will pertain to the same study or analysis.
cd /<my_home_directory>/<my_awesome_study>/

# 2:
# Now, create a text file that, on each new line, contains the filepath to each folder in the directory 
## to which we just `cd`-ed in step #1. To do so, store the results from the `find` command in a .txt file.
## This will separate folder paths by linebreaks, as desired.
### NOTE! This is wrapped in an if-else, because we don't want to run this heavy command more than once.
# This can be improved if we know the names of the folders we are looking for (the folder with the dicoms!).
if [ ! -e fileTree.txt ]; # Here, checking to see if the file exists
then
  find . -type d > fileTree.txt; # run the find command, and store the result as a text file
fi
# Prior to reading the file in, use 'chmod 755 <filename>', ensuring it is readable, writable, + executable
chmod 755 fileTree.txt
found=$(<SB_fileTree.txt) # here we read it in and assign its contents to the variable "found"

# 3:
# Filter through these results looking for the desired folders.
# `echo "$found"` will print the contents of "found" as strings to be manipulated with grep.
# Following the grep command, supply a regular expression we are searching for (to identify folders with .dcm files)
# Note, we can also use this in combination with -v, to invert the selection, and make sure we just get the:
## FOLDER where the dicom lives. 
# After supplying all of our search criteria, we aim to have an exhaustive list of:
## FOLDERs directly in which ALL (every) of the dicoms exist in the entire study. IF not, do more grep-ing!
wave1or2_resting=`echo "$found" | grep /REST___EYES | grep -v /REST___EYES.*/.*`
wave3_resting=`echo "$found" | grep /REST_-_EYES | grep -v /REST___EYES.*/.*`
anatomical=`echo "$found" | grep /MPRAGE | grep -v /MPRAGE.*/.*` # captures all waves
wave1or2_task=`echo "$found" | grep /TASK[0-9]_ | grep -v /TASK[0-9]_.*/.*` # captures all tasks at waves 1 and 2
wave3_task=`echo "$found" | grep /Task[0-9] | grep -v /Task[0-9].*/.*` # captures all tasks at wave 3

# 4:
# With the folder/file paths from different sources above, concatenate them into one long array.
# We use `for ...` so that it can treat each path in each of the above sub-lists seperately.
# This is necessary so that instead of returning one string, like so: ("<dir/path1> <dir/path2>"),
# instead we get an array where each dir path is a different element: ("<dir/path1>", "<dir/path2>", etc)
dirList=() # initialize an empty array to capture the results
j=1 # initialize an indexer to keep track of where we are assigning each element into dirList
# Now loop through all elements of each list.
# Use j++ to increase the indexer by one at each iteration
# Thus each element is assigned to the next available spot in dirList, directly following the last one
for path in $wave1or2_resting; do dirList[j++]=$path; done
for path in $wave3_resting; do dirList[j++]=$path; done
for path in $anatomical; do dirList[j++]=$path; done
for path in $wave1or2_task; do dirList[j++]=$path; done
for path in $wave3_task; do dirList[j++]=$path; done
# dirList now contains a list of paths to folders, inside of which each contain dicoms to convert!
# Let's save this as a text file sp we don't have to run this portion again, unless more folders are added.
### The syntax echo ${VARIABLE[@]} will print out every item of the variable (because of the '@')
### They will be printed out as is, separated by a blank space.
### Using (the pipe, and then) tr " " "\n", we replace all the blank spaces with \n.
### When we then use '>' to send this to a text file, the \n will be interpreted as line breaks.
echo ${dirList[@]} | tr " " "\n" > dicomFolderPaths.txt

# 5: (converting the dicoms to NIFTI files)
# Loop over the contents of dirList and do:
#### (5i) Create a folder called dicoms
### (5ii) Create a folder called nii
## (5iii) Extract just the dicoms from the original folder and move them to the newly created dicoms folder.
for i in $(seq 1 ${#dirList[@]}); # translation: "for folderpath in 1 2 3 4 ... <length_of_dirList>" ...
do # '${i}' drops the i-th number of the sequence into the brackets; extracting the i-th element of dirList
# Henceforth `${dirList[${i}]}` refers to the i-th dir path (to folder with the dicom files) within dirList
  mkdir ${dirList[${i}]}/dicoms; # 5i. create a dicoms folder at the end of the path
  mkdir ${dirList[${i}]}/nii; # 5ii. create a nii folder at the end of the path
  # now, for each TR in this i-th folder of dirList, **move** it to the newly-created dicoms folder.
  # (This script was produced for a study in which the dicoms all had filenames containing sequential numbers)
  # The dicoms may be called "001", "000190.dcm", or "00010.dcm", etc. So extract all that meet these criteria
  # THE **grep** CRITERIA MUST BE SPECIFIC TO THE **filenames** OF THE DICOMS!!!
  # notably, (for THIS example) no dicoms have letters in the filename, other than .dcm
  for TR in $(ls ${dirList[${i}]} | grep -E '^[[:digit:]]+$|^[[:digit:]]+.dcm$');
  do
    mv ${dirList[${i}]}/$TR ${dirList[${i}]}/dicoms; # 5iii. move all of these TRs into the dicoms folder
  done # Now we are ready to run dcm2niix on the dicoms folder.
  
  # (still inside the loop, working with `${dirList[${i}]}`)
  # 6. Use the dcm2niix command to do the conversions (https://github.com/rordenlab/dcm2niix)
  ## dcm2niix will take a folder of dicoms (TRs) and convert them all to a single NIFTI file.
  ## arguments / flags:
  ### -b includes the BIDS format sidecar file. then supply y (yes), n (no), or o (another option).
  ### -m merge 2D slices for the same series regardless of study time, echo, orientation, etc..
  ### -z to compress file afterwards.
  ### -o comes right before you name the destination folder.
  ### Last thing you supply is the name of the input folder. 
  dcm2niix -b y -m y -z y -o ${dirList[${i}]}/nii ${dirList[${i}]}/dicoms
done # Done!

# Now, within each subject's folder that contained the TRs in dicom format, there is:
#
# 1. A new folder called nii, containing the NIFTI file and any other outputs from dcm2niix
# 2. A new folder called dicoms containing the original dicoms


