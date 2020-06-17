# -*- coding: utf-8 -*-
"""
Created on Tue Apr  7 15:41:18 2020

@author: Ian G. Malone
https://github.com/IanGMalone

The purpose of this script is to process a batch of Spike2 .mat HDF5 files containing EMG data of motor-evoked potentials. Relevant data in the Spike2 files are left EMG, right EMG, and stimulus waveforms. The outputs include a dataframe of the motor-evoked potentials as well as a dataframe of the calculated stimulus-triggered averages.

This script works with MATLAB files of version >= 7.3

To use:
    Save all .smr or .smrx files as .mat files
    Make sure they are .mat version 7.3 or later
    Uncheck 'use source name in MatLab variable names'
    Check 'use source channel name in MatLab variable names'
    Run this script on the parent folder containing these .mat files
"""



# import libraries
import numpy as np
from scipy import signal
import pandas as pd
import h5py
import os
from datetime import datetime



# define functions
def file_to_df(path, file_name, df, col_names=['Animal', 'Day', 'Side', 'Stim_Amplitude', 'Sample', 'EMG_Amplitude']
):
    '''Takes .mat file containing MEP data and returns a dataframe of that data'''

    # load file and extract keys
    filepath = path + file_name
    raw_data = h5py.File(filepath)
    all_keys = list(raw_data.keys())
    
    # define variables of interest
    leftEMG_vars = ['LDia', 'LDIA', 'lEMG_raw']
    rightEMG_vars = ['RDia', 'RDIA', 'rEMG_raw']
    stim_vars = ['StimWav1', 'Stim', 'stim']
    # if the below lines return errors, the above lines are probably not capturing all possible channel names. The above lists must reflect all Spike2 channel names
    leftEMG = [key for var in leftEMG_vars for key in all_keys if var in key][0]
    rightEMG = [key for var in rightEMG_vars for key in all_keys if var in key][0]
    stim_wave = [key for var in stim_vars for key in all_keys if var in key][0]

    # unpack variables from .mat file
    animal = file_name.split('_')[0]
    day = file_name.split('_')[1]
    stim = raw_data[stim_wave]['values'][0]
    samp_freq = int(round(1/(raw_data[stim_wave]['interval'][0][0])))
    rEMG = raw_data[rightEMG]['values'][0]
    lEMG = raw_data[leftEMG]['values'][0]
    # # below is for non-hd5 files
    # stim = stim[0][0].flatten()
    # samp_freq = 1/float(samp_freq[0][0].flatten())
    # rEMG = rEMG[0][0].flatten()
    # lEMG = lEMG[0][0].flatten()
     
    # find location of stimulation pulses (sample number)
    # VERIFY THIS SECTION!!!!!!!
    stim_peaks = signal.find_peaks(stim, height=0.09, distance=6)
    peak_locs = stim_peaks[0]
    peak_heights = stim_peaks[1]['peak_heights']
    
    # get chunks of meps and make dataframe
    df_mep = pd.DataFrame(columns=col_names)
    mep_time_ms = 12 #make this an argument?!!!!!!!
    mep_sample_length = round((mep_time_ms/1000)*samp_freq)

    for i in np.arange(len(peak_locs)):
        df_mep = df_mep.append(mep_to_df(animal, day, 'Left', peak_heights[i], lEMG[peak_locs[i]:peak_locs[i]+mep_sample_length], col_names), ignore_index=True)
        df_mep = df_mep.append(mep_to_df(animal, day, 'Right', peak_heights[i], rEMG[peak_locs[i]:peak_locs[i]+mep_sample_length], col_names), ignore_index=True)
    
    
    # This section is here due to early animals having a different sampling frequency
    # VERIFY THIS !!!!!!!!
    early_list= ['n01', 'n02', 'n03', 'n04', 'n05', 'n06', 'n07', 'n08',\
             'n09', 'n10', 'n11', 'n12', 'n13']

    if animal in early_list:
        df_mep[col_names[3]] = round_to_5(df_mep[col_names[3]]*100)
    else:
        df_mep[col_names[3]] = round_to_5(df_mep[col_names[3]]*1000)
        
    return df_mep
    


def list_files(rootdir, extension='.mat'):
    '''Return list of all files with specific extension in given directory (subfolders included)'''
    
    list_of_files=[]
    
    for subdir, dirs, files in os.walk(rootdir):
        for file in files:
            if file.endswith(extension):
                list_of_files.append(file)

    return list_of_files



def mep_to_df(animal, day, side, amp, mep, colnames=['Animal', 'Day', 'Side', 'Stim_Amplitude', 'Sample', 'EMG_Amplitude']):
    '''Make data frame given various MEP information'''
    
    animal_array = np.repeat(animal, len(mep))
    day_array = np.repeat(day, len(mep))
    side_array = np.repeat(side, len(mep))
    amp_array = np.repeat(amp, len(mep))
    samples = np.arange(len(mep))
    
    d = {colnames[0]:animal_array, colnames[1]:day_array, colnames[2]:side_array, colnames[3]:amp_array, colnames[4]:samples, colnames[5]:mep}
    df = pd.DataFrame(d, columns=colnames)
    
    return df



def round_to_5(number):
    '''Round an input number to the nearest multiple of 5'''
    
    num_out = round(number/5)*5
    
    return num_out









# do processing on files
startTime = datetime.now()

rootdir = 'C:/Users/iangm/Desktop/MEPmat_py_analyze/'
cols = ['Animal', 'Day', 'Side', 'Stim_Amplitude', 'Sample', 'EMG_Amplitude']
df_MEP = pd.DataFrame(columns=cols)

for f in list_files(rootdir):
    df_MEP = df_MEP.append(file_to_df(rootdir, f, df_MEP, cols))

endTime = datetime.now()
totalTime = endTime - startTime
print('Total time: ', totalTime)



# create STA dataframe from rectified MEP dataframe
df_MEP['EMG_Amplitude'] = df_MEP['EMG_Amplitude'].abs()
df_STA = df_MEP.groupby(['Animal', 'Day', 'Side', 'Stim_Amplitude', 'Sample'], as_index=False)['EMG_Amplitude'].mean()
df_STA.rename(columns={'EMG_Amplitude': 'STA_Amplitude'}, inplace=True)

# save dataframes to CSV files
df_MEP.to_csv(r'C:\Users\iangm\Desktop\df_MEP_2020_06_14_clean.csv', index = False)
df_STA.to_csv(r'C:\Users\iangm\Desktop\df_STA_2020_06_14_clean.csv', index = False)






# you probably need to convert from sample to time
    # smoothing with bin of samples would result in different smoothing between groups

# split functions so they each do 1 thing

# should this whole analysis script be a class or something... something that you call?

# you need to make an informed choice of moving average window size
    # look at rat SCI MEP latencies



# ----------------------testing-----------------------




# # do processing on files
# startTime = datetime.now()

# rootdir = 'C:/Users/iangm/Google Drive/UF/Lab/Data & Figures/Python Scripts/MEPs_to_analyze/'
# cols = ['Animal', 'Day', 'Side', 'Stim_Amplitude', 'Sample', 'EMG_Amplitude']
# df_test_MEP = pd.DataFrame(columns=cols)

# for f in list_files(rootdir):
#     df_test_MEP = df_test_MEP.append(file_to_df(rootdir, f, df_test_MEP, cols))
#     print('Another file done.')

# endTime = datetime.now()
# totalTime = endTime - startTime
# print('Total time: ', totalTime)



