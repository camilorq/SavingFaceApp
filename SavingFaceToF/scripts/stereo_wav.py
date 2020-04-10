#
#    MIT License
#
#    Copyright (c) 2020 Camilo Rojas, Niels Poulsen, James Korrawat, Zhi Wei Gan
#
#    Permission is hereby granted, free of charge, to any person obtaining a copy
#    of this software and associated documentation files (the "Software"), to deal
#    in the Software without restriction, including without limitation the rights
#    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#    copies of the Software, and to permit persons to whom the Software is
#    furnished to do so, subject to the following conditions:
#
#    The above copyright notice and this permission notice shall be included in all
#    copies or substantial portions of the Software.
#
#    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#    SOFTWARE.

# Python 2 example
from struct import pack
import wave
import numpy as np
import math
from scipy.io.wavfile import write
import matplotlib.pyplot as plt


# CONSTANT STEREO

# The sample rate should be exagerated to get a nice sine wave in the output.
samplerate = 500000

# The duration of the sound wave
interval = 0.1

# The length of the chirp
duration = 0.1

# The frequencies of the signals in each channel
f1 = 1400
f2 = 1400

# The shift to apply to the second channel
shift = math.pi

# The time array
t = np.linspace(0., interval, int(interval * samplerate), endpoint=False)
t_or_zero = t * (t <= duration)

# An array to set the shift to 0 once the chirp is over
shift_zero = np.ones(int(interval * samplerate)) * (t <= duration)

amplitude = 1
data_left = amplitude * np.sin(2. * np.pi * f1 * t_or_zero)
data_right = amplitude * np.sin(2. * np.pi * f2 * t_or_zero + shift * shift_zero)
data = np.array([data_left, data_right]).T
print(data.T.shape)
write("../chirp.wav", samplerate, data)

# Plot the wav file, with zoom at the beginning
plt.plot(data[0:200])
plt.show()
