# -*- coding: utf-8 -*-
"""
Created on Mon Jun 15 19:38:32 2020

@author: Ian G. Malone
https://github.com/IanGMalone

The purpose of this script is to load a .smrx file in order to plot raw 
ephys data.
"""


import numpy as np
from scipy import signal
#import pandas as pd
import h5py
import matplotlib.pyplot as plt
import seaborn as sns
sns.set(style='ticks')


path = 'C:/Users/iangm/Desktop/'
file_name = 'n10_1_mep.mat'


# load file and extract keys
filepath = path + file_name
raw_data = h5py.File(filepath)
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
sample = np.arange(0, len(rEMG))
time = sample/samp_freq
 
# find location of stimulation pulses (sample number)
stim_peaks = signal.find_peaks(stim, height=0.09, distance=6)
peak_locs = stim_peaks[0]
peak_heights = stim_peaks[1]['peak_heights']


mep_time_ms = 12 
mep_sample_length = round((mep_time_ms/1000)*samp_freq)


#Plot frequency and phase response
def mfreqz(b,a=1):
    w,h = signal.freqz(b,a)
    h_dB = 20 * np.log10 (abs(h))
    plt.subplot(211)
    plt.plot(w/max(w),h_dB)
    plt.ylim(-150, 5)
    plt.ylabel('Magnitude (db)')
    plt.xlabel(r'Normalized Frequency (x$\pi$rad/sample)')
    plt.title(r'Frequency response')
    plt.subplot(212)
    h_Phase = np.unwrap(np.arctan2(np.imag(h),np.real(h)))
    plt.plot(w/max(w),h_Phase)
    plt.ylabel('Phase (radians)')
    plt.xlabel(r'Normalized Frequency (x$\pi$rad/sample)')
    plt.title(r'Phase response')
    plt.subplots_adjust(hspace=0.5)

#Plot step and impulse response
def impz(b,a=1):
    l = len(b)
    impulse = np.repeat(0.,l); impulse[0] =1.
    x = np.arange(0,l)
    response = signal.lfilter(b,a,impulse)
    plt.subplot(211)
    plt.stem(x, response)
    plt.ylabel('Amplitude')
    plt.xlabel(r'n (samples)')
    plt.title(r'Impulse response')
    plt.subplot(212)
    step = np.cumsum(response)
    plt.stem(x, step)
    plt.ylabel('Amplitude')
    plt.xlabel(r'n (samples)')
    plt.title(r'Step response')
    plt.subplots_adjust(hspace=0.5)
    
n = 11 # filter length
fir_coeffs = signal.firwin(n, cutoff = (np.pi/5), window = "hamming")
#Frequency and phase response
#mfreqz(fir_coeffs)

y_raw = rEMG[10000:12000]
y_res = signal.upfirdn(fir_coeffs, y_raw, up=5, down=4)

#it's not right... some sort of aliasing is happening. goes away at lower cutoff freq

plt.subplot(211)
plt.stem(np.arange(len(y_raw)),y_raw)
plt.subplot(212)
plt.stem(np.arange(len(y_res)),y_res)
plt.show()
