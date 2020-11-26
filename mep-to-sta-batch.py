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




#### import libraries
import numpy as np
from scipy import signal
import pandas as pd
import h5py
import os
from datetime import datetime
import time

#################you should probably downsample these files before saving them as MEP

#!!!! change sample to time?
#### define functions
def file_to_df(path, file_name, df, low_amp_list, mep_time_ms, col_names=['Animal', 'Day', 'Side', 'Stim_Amplitude', 'Sample', 'EMG_Amplitude']):
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
    animal = file_name.split('_')[3]
    day = file_name.split('_')[4].split('.')[0]
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
    #!!!!!!! VERIFY THIS SECTION
    stim_peaks = signal.find_peaks(stim, height=0.09, distance=6)
    peak_locs = stim_peaks[0]
    peak_heights = stim_peaks[1]['peak_heights']
    
    # get chunks of meps and make dataframe
    df_mep = pd.DataFrame(columns=col_names)
    #!!!!! make ms an argument?
    # Animals <= N13 were sampled at 20 kHz, animals > N13 were at 25 kHz

    mep_sample_length = round((mep_time_ms/1000)*samp_freq)

    for i in np.arange(len(peak_locs)):
        df_mep = df_mep.append(mep_to_df(animal, day, 'Left', peak_heights[i], lEMG[peak_locs[i]:peak_locs[i]+mep_sample_length], col_names), ignore_index=True)
        df_mep = df_mep.append(mep_to_df(animal, day, 'Right', peak_heights[i], rEMG[peak_locs[i]:peak_locs[i]+mep_sample_length], col_names), ignore_index=True)
    
    # 400 uA is 4.0 for animals <= N13, 0.4 for animals > N1
    if animal in low_amp_list:
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




#### do processing
startTime = datetime.now()

# specify locations and files and make empty dataframe
rootdir = 'C:\\Users\\iangm\\Desktop\\nov_analysis\\'
cols = ['Animal', 'Day', 'Side', 'Stim_Amplitude', 'Sample', 'EMG_Amplitude']
df_MEP = pd.DataFrame(columns=cols)
low_amp_list = []
mep_time_ms = 30

# append dataframes for all files to make one big dataframe
for f in list_files(rootdir):
    df_MEP = df_MEP.append(file_to_df(rootdir, f, df_MEP, low_amp_list, mep_time_ms, cols))

# measure how long the big dataframe creation took to execute
endTime = datetime.now()
totalTime = endTime - startTime
print('Total time: ', totalTime)

# create STA dataframe
df_STA = df_MEP
df_STA['EMG_Amplitude'] = df_STA['EMG_Amplitude'].abs()
df_STA = df_STA.groupby(['Animal', 'Day', 'Side', 'Stim_Amplitude', 'Sample'], as_index=False)['EMG_Amplitude'].mean()
df_STA.rename(columns={'EMG_Amplitude': 'STA_Amplitude'}, inplace=True)

# save dataframes to CSV files
date_str = time.strftime("%Y_%m_%d")
df_MEP.to_csv(r'C:\Users\iangm\Desktop\df_MEP_' + date_str + '.csv', index = False)
df_STA.to_csv(r'C:\Users\iangm\Desktop\df_STA_' + date_str + '.csv', index = False)





#### will this work? we need a lowpass anti aliasing filter
#lowpass at 12500 and at 10000 (maybe go even lower to like 8000)
#do an fft to see what frequencies are in the signal
#upsample then downsample so you get downsampling of non integer ration (1.25)


def resample(smp, scale=1.0):
    """Resample a sound to be a different length
    Sample must be mono.  May take some time for longer sounds
    sampled at 44100 Hz.

    Keyword arguments:
    scale - scale factor for length of sound (2.0 means double length)
    """
    # f*ing cool, numpy can do this with one command
    # calculate new length of sample
    n = round(len(smp) * scale)
    # use linear interpolation
    # endpoint keyword means than linspace doesn't go all the way to 1.0
    # If it did, there are some off-by-one errors
    # e.g. scale=2.0, [1,2,3] should go to [1,1.5,2,2.5,3,3]
    # but with endpoint=True, we get [1,1.4,1.8,2.2,2.6,3]
    # Both are OK, but since resampling will often involve
    # exact ratios (i.e. for 44100 to 22050 or vice versa)
    # using endpoint=False gets less noise in the resampled sound
    return np.interp(
        np.linspace(0.0, 1.0, n, endpoint=False), # where to interpret
        np.linspace(0.0, 1.0, len(smp), endpoint=False), # known positions
        smp, # known data points
        )

'test commit with no stage'






    
#### questions ####
#!!!! important
# do you average evoked potentials to make STAs first?
# or do you smooth (moving average), rectify, etc?
# moving average window latencies
# split functions so they each do 1 thing



#### to do
# resample
# threshold MEPs
# cwt on MEP and compare
# classify if animal will recover based on cwt characteristics (vocalization paper)
# feed in all the CWT meps from all days and have human-labelled target variable
# target: 1 = faciliated in the end, 0 = didnt




#### scrap ####
# df_MEP['EMG_Amplitude'] = df_MEP['EMG_Amplitude'].abs()


