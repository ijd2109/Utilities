# (this script is intended to be run using `Rscript 02_jsonToBidsPaths.R` from a shell command line)
######################################################################################################
# Purpose of this script:
# 
# Using the output from 01_processJson.py, examine the task name, acquisition time, and scan date that
# were extracted from the JSON associated with each NIFTI, as well some basic information contained
# in the file path itself to determine what the NIFTI's BIDS-formatted filepath and filename should be.
#
# This information is output into a another .csv, which has a field for the original filepath, and
# a new field for the bids-formatted filepath (and filename). A final bidsifying script will then
# essentially move the nifti from its original (current) path, to the bids-formatted path we are
# creating now (while also renaming the file and creating each intermediary folder as needed).
#  
# ---------------- ----------------- ------------------- ---------------------- --------------------------
# For questions contact: Ian J. Douglas, idouglas@utexas.edu; idmail92@gmail.com; ijd2109@columbia.edu
# Check for updates at https://github.com/ijd2109/Utilities/tree/master/BIDSifying
# -------------------------- ---------------------- ------------------- ----------------- ----------------
# This script was written with R version 3.6.1, tested on 4.0.0 (works).
# Written with tidyverse version 1.3.0 
#

library(tidyverse)

# 1. Read in the csv file that resulted from running 01_processJson.py
df <- read.csv("jsonSidecarDataProcessed.csv", stringsAsFactors = F)

# 2. Interpret the information that was extracted from the json's TaskName field.
#### In the csv we read in, this is stored in a variable called task_name.
#### This part needs to be hard-coded, using prior knowledge of the meaning of
#### the different TaskName's that were used by the researrcher during scanning
#### to indicate the different tasks or sometimes runs and timepoints in the study.
#### We are free to create new, interpretable task names at this stage too.

# For example, if my study has a task called STROOP_TASK, one called REST, and
# one called MPRAGE, and this information subsequently made its way into the TaskName
# field of the .json associated with each scan, then the following code should look like:
df1 <- mutate(df, json_task = case_when(
  grepl("STROOP_TASK", task_name) ~ "stroop", # here we freely invent 'stroop' for the new name
  grepl("REST", task_name) ~ "rest",
  grepl("MPRAGE", task_name, ignore.case = T) ~ 'mprage',
  TRUE ~ NA_character_ # if no match is found, return NA as character-type data
))
## 2a. Using the filepath, and PRIOR KNOWLEDGE of where the subject ID exists in that filepath:
#### Use some regular expression string operations to extract the subject ID.
#### This will be study-specific, but the input is always the filepath where the NIFTI currently exists
#### And the output is jusut the numbers that identify the subject uniquely.
#### Example, a study called Cool Study might have subject identifiers: CS001, CS002, ... CS00N.
#### We want to extract ONLY 001, 002 ... NNN
df1$sub <- sapply(str_split(df1$path, "/"), function(x) x[4]) # just an example splitting the paths at "/"
## 2b. Generate the BIDS-format subdirectories.
#### In BIDS, we will need to have seperate subdirectories for functional data, anatomical scans, and sometimes fieldmaps, etc
#### So based upon the TaskName that we extracted above, we will assign this subdirectory, and call it TaskType
#### mprage is an anatomical scan and the BIDS-format subdirectory is therefore /anat/
### Restingstate and task scans are functional MRI, so they go into /func/ folders.
df1$taskType <- ifelse(grepl("mprage", df1$json_task), "anat", "func") # and NA will return NA again.

# 3. Compute the run number for each scan.
#### The run # is simply the order in which the scans were completed by the subject.
#### A subject may do multiple runs of the same task. Therefore, within each subject, and within neach type of task:
#### label the scans in order of Acquisition Time. Here it is also helpful to further group by the date on which
#### the scan was completed, in the event that there are multiple days or timepoints on which a subject does the same task.
df2 <- df1 %>%
  group_by(sub, date, json_task) %>%
  arrange(scan_time) %>%
  mutate(run = 1:n()) %>% # now that they are in order, labelling them 1, 2, 3, ... n is their run number!
  ### One last step here:
  # BIDS actually requires that the TaskName within the json file actually is: "<TASK_NAME><RUN#>" (e.g., rest1)
  # now that the run is generated, we create the json meta-data for the TaskName field.
  # Later we will need to insert this back into the json
  mutate(jsonTaskName = paste0(json_task, run))

# 4. Define a function to make the BIDS file paths by joining all this information from above, seperated by "/"
#### Note, this assumes a Unix or Mac file naming convention, where folders are seperated in file paths by "/"
makeBIDS = function(sub_id, session, task, run, taskType)
{
  subject <- paste0("sub-", sub_id) # generate "sub-001" from "001"
  ses <- paste0("ses-", session) # generate "ses-1" from "1" (only needed if multiple longitudinal timepoints exist)
  .run <- paste0("run-", run) # generate "run-1" from "1"
  root <- "/<my_awsome_lab>/<my_awesome_study>/" # create the full path to BIDS-formatted directory for this study
  if (is.na(task)) return(NA) else {
    if (taskType == 'anat') 
    { # for the anatomical scans:
      bidsPath <- paste(root, subject, ses, taskType, paste(subject, ses, "mprage.nii.gz", sep = "_"), sep = "/")
    } else { # for the fMRI:
      bidsPath <- paste(root, subject, ses, taskType, # <-- directory path; and filename:
                        paste(subject, ses, paste0("task-", task), .run, "bold.nii.gz", sep = "_"), sep = "/")
    } # if there are other file types, such as fieldmaps, etc, add another else statement
    return(bidsPath)
  }
}



# 5. Run on each row of the data frame
df3 <- df2 %>%
  # first just code everything as session 1
  # If your study is longitudinal, this would have to be 1, 2, 3 ... t for each timepoint, and should be coded in step 3
  mutate(session = 1) %>%
  rowwise() %>% # instruct R to run make BIDS on each row of the data; run function:
  mutate(BIDS_path = makeBIDS(sub_id = sub, session = session, task=json_task, run=run)) %>% ungroup()
# The variable BIDS_path has now been created, and contains a character string for each scan, which reflects the BIDS-formatted filepath
# These filepaths don't currently lead to anywhere, and the intermediary folders don't exist. 
# Instead, 03_makeBIDSfileSystem.py takes the BIDS_path information, creates the path and moves the NIFTI (and json).

# 6. Write out the csv contianing the information to be read-in by 03_makeBIDSfileSystem.py
write.csv(df3, "bidsFilePaths.csv", row.names = F)