# -*- coding: utf-8 -*-
"""
Created on Mon Jun 15 19:38:32 2020

@author: Ian G. Malone

The purpose of this script is to load a .smrx file in order to plot raw 
ephys data.
"""


import numpy as np
from scipy import signal
import pandas as pd
import h5py
import os
import seaborn as sns
from datetime import datetime
sns.set(style='ticks')



path = 'C:/Users/iangm/Desktop/'
file_name = 'n19_4_mep.mat'


# load file and extract keys
filepath = path + file_name
raw_data = h5py.File(filepath)
all_keys = list(raw_data.keys())

# define variables of interest
leftEMG_vars = ['LDia', 'LDIA', 'lEMG_raw']
rightEMG_vars = ['RDia', 'RDIA', 'rEMG_raw']
stim_vars = ['StimWav1', 'Stim', 'stim']
# if the below lines return errors, the above lines are probably not capturing all possible channel names
leftEMG = [key for v in leftEMG_vars for key in all_keys if v in key][0]
rightEMG = [key for v in rightEMG_vars for key in all_keys if v in key][0]
stim_wave = [key for v in stim_vars for key in all_keys if v in key][0]

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
stim_peaks = signal.find_peaks(stim, height=0.09, distance=6)
peak_locs = stim_peaks[0]
peak_heights = stim_peaks[1]['peak_heights']
    