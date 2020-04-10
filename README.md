# Saving Face App

We seek to deploy a sub-$5 system to greatly reduce the risk of users acquiring SARS-CoV-2 or other pathogens through surface transmission (more information about the project here).

Our device measures the distance between a user’s hands and face using ultrasound pulses between hand-worn sensors and receivers on the neck or head (e.g., earbuds, mics). When the user raises their hand to touch their face, their smartphone alerts them with a vibration or audible alarm.

## Technical details

We permanently play an ultrasound tone (17kHz). When the distance mic-earbud (d) is short (under ~15cm, detected when the ultrasound amplitude exceeds a threshold), we play an audible tone (1.4kHz).

The audible tone serves as a warning and as a mechanism to refine the distance estimation. We measure the phase shift of the audible tone, with respect to an initial calibration (d=0). The phase of the tone is measured by finding the maximum in the trace amplitude vs. time (with a precision of 7mm, due to the 44.1kHz sampling frequency).

## Instructions
1. Clone or download this repository.
2. Open the project file SavingFaceToF in xCode.
3. Declare the team and the bundle identifier (in target SavingFaceToF, the tab Signing & Capabilities).
4. Connect the headphones to the iPhone and set to maximum volume.
5. Build and run (make sure your iPhone is connected and it is the target device).
6. Place the earbud (on the wire without the microphone) next to the microphone. Press the button calibrate while in this setup.
7. Voila! The phone will emit an audible alarm when the mic approaches the earbud.

Tested with: Xcode 11.4, iOS 13.3.1 and iPhone 6s.

## Next steps

Our next steps include improving the robustness to interference from other users, removing the current calibration step, achieving functionality with 90% of randomly chosen inexpensive earbuds, and releasing Android and iOS apps.