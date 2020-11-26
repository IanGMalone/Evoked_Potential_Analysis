# -*- coding: utf-8 -*-
"""
Created on Thu Nov 19 21:11:37 2020

@author: Ian G. Malone
"""


import numpy as np
from scipy import signal
import pandas as pd
import h5py
from datetime import datetime
import matplotlib.pyplot as plt

# load file and extract keys
path = 'C:\\Users\\iangm\\Desktop\\'
file_name = '2020_11_08_S01_D04__PRACTICE.mat'
filepath = path + file_name
raw_data = h5py.File(filepath, 'r')
all_keys = list(raw_data.keys())

# define variables of interest
leftEMG_vars = ['LDia', 'LDIA', 'lEMG_raw']
rightEMG_vars = ['RDia', 'RDIA', 'rEMG_raw']
stim_vars = ['StimWav1', 'Stim', 'stim']
# if the below lines return errors, the above lines are probably not capturing all possible channel names
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
stim_downsamp = signal.decimate(stim, int(samp_freq/5000))
rEMG_downsamp = signal.decimate(rEMG, int(samp_freq/5000))
lEMG_downsamp = signal.decimate(lEMG, int(samp_freq/5000))

plt.subplot(2,1,1)
plt.plot(stim)
plt.subplot(2,1,2)
plt.plot(stim_downsamp)

plt.subplot(2,3,1)
plt.plot(rEMG[0:500])
plt.subplot(2,3,2)
plt.magnitude_spectrum(rEMG,25000)
plt.xlim([0,2500])
plt.subplot(2,3,3)
plt.phase_spectrum(rEMG,25000)
plt.xlim([0,2500])
plt.subplot(2,3,4)
plt.plot(rEMG_downsamp[0:100])
plt.subplot(2,3,5)
plt.magnitude_spectrum(rEMG_downsamp,5000)
plt.subplot(2,3,6)
plt.phase_spectrum(rEMG_downsamp,5000)

# the above plots look good. downsampling seems to work

# desired_freq = 2000
# secs = len(stim)/samp_freq # Number of seconds in signal X
# samps = int(round(secs*desired_freq))     # Number of samples to downsample
# resample_stim = signal.resample(stim, samps)

# resample_lEMG = signal.resample(lEMG, samps)


###plot lEMG and resampled signal to see if they are similar... if so, look at fft and maybe phase?
### convert to time before plotting so you are comparing the same sections
#### if it looks bad then add anti aliasing filter before downsampling
