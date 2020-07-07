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
from scipy.signal import butter, lfilter, freqz


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

#### filtering


def butter_lowpass(cutoff, fs, order=5):
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype='low', analog=False)
    return b, a

def butter_lowpass_filter(data, cutoff, fs, order=5):
    b, a = butter_lowpass(cutoff, fs, order=order)
    y = lfilter(b, a, data)
    return y


# Filter requirements.
cut_norm_rad = (np.pi)/5 # desired normalized cutoff freq, rad/s
order = 10
fs = 20000       # sample rate, Hz
cutoff = int(round((cut_norm_rad * fs) / (2*np.pi))) # desired cutoff freq, Hz

# Get the filter coefficients so we can check its frequency response.
b, a = butter_lowpass(cutoff, fs, order)

# Plot the frequency response.
w, h = freqz(b, a, worN=8000)
plt.subplot(2, 1, 1)
plt.plot(0.5*fs*w/np.pi, np.abs(h), 'b')
plt.plot(cutoff, 0.5*np.sqrt(2), 'ko')
plt.axvline(cutoff, color='k')
plt.xlim(0, 0.5*fs)
plt.title("Lowpass Filter Frequency Response")
plt.xlabel('Frequency [Hz]')
plt.grid()

### my code

y_raw = rEMG[10000:11000]
y_filt = butter_lowpass_filter(y_raw, cutoff, fs, order)

# =============================================================================
# 
# # Demonstrate the use of the filter.
# # First make some data to be filtered.
# T = 5.0         # seconds
# n = int(T * fs) # total number of samples
# t = np.linspace(0, T, n, endpoint=False)
# # "Noisy" data.  We want to recover the 1.2 Hz signal from this.
# data = np.sin(1.2*2*np.pi*t) + 1.5*np.cos(9*2*np.pi*t) + 0.5*np.sin(12.0*2*np.pi*t)
# 
# # Filter the data, and plot both the original and filtered signals.
# y = butter_lowpass_filter(data, cutoff, fs, order)
# =============================================================================

plt.subplot(2, 1, 2)
plt.plot(range(10000,11000), y_raw, 'b-', label='data')
plt.plot(range(10000,11000), y_filt, 'g-', linewidth=2, label='filtered data')
plt.xlabel('Time [sec]')
plt.grid()
plt.legend()

plt.subplots_adjust(hspace=0.35)
plt.show()



y_res = signal.upfirdn(fir_coeffs, y_raw, up=5, down=4, mode='smooth')

# shift signal to compensate for delay





# =============================================================================
#     
# sns.lineplot(x=time[0:500000], y=lEMG[0:500000])
# plt.show()
# 
# length=500000
# data = np.array([time[0:length], lEMG[0:length], rEMG[0:length]])
# data = np.transpose(data)
# df = pd.DataFrame(data=data, index=np.arange(length), columns=["Time", "Left Diaphragm EMG", "Right Diaphragm EMG"])
# 
# meltdf = pd.melt(df, id_vars=['Time'], value_vars=['Left Diaphragm EMG', 'Right Diaphragm EMG'])
# meltdf.rename(columns={'variable':'side', 'value':'EMG Amplitude (V)'}, inplace=True)
# 
# 
# g = sns.FacetGrid(meltdf, row="side", height=1.7, aspect=4,)
# g.map(sns.lineplot, 'Time', 'EMG Amplitude (V)');
# 
# 
# meltdf.to_csv(r'C:\Users\iangm\Desktop\dffff.csv', index = False)
# =============================================================================
