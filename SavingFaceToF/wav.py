from scipy.io.wavfile import write
import numpy as np


samplerate = 500000 # The sample rate should be exagerated to get a nice sine wave in the output.
interval = 0.1
duration = 0.01
fs = 18000
t = np.linspace(0., interval, int(interval * samplerate), endpoint=False)
t_or_zero = t * (t <= duration)

amplitude = 1000
data = amplitude * np.sin(2. * np.pi * fs * t_or_zero)
# data = np.vstack([data] * 2).T
write("../MicrophoneAnalysis/chirp.wav", samplerate, data)

#np.savetxt('chirp.csv', data, delimiter=',')

import matplotlib.pyplot as plt

plt.plot(data)
plt.show()
