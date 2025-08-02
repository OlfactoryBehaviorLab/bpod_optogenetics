# Dewan Lab Bpod Optogenetics Protocols
## Setup

## HARDWARE SETUP:
1) Set the Galvostation up using the direct patch cords and included documentation
2) Plug the Bpod into a free USB port
3) Plug the PulsePal into a free USB port
4) Connect **PulsePal** `Output Channel 1` to the input on the rear of the **laser driver** using a BNC Cable
5) Connect **PulsePal** `Output Channel 2` to the input of the **Galvostation** using a BNC Cable
6) Connect **Bpo**d `TTL OUT 1` to `Trigger 1` of the **PulsePal**
7) (Optional) If using the camera, connect **Bpod** `TTL OUT 2` to `Line 2` on the **FLIR Camera Breakout Box**

## MATLAB Software:
1) Install MATLAB and ensure it is activated
2) Please visit the [Bpod Wiki](https://sanworks.github.io/Bpod_Wiki/install-and-update/installing-bpod/) for instructions installing the `Bpod_Gen2` software
3) Please visit the [PulsePal Wiki](https://sites.google.com/site/pulsepalwiki/matlab-gnu-octave/installation?authuser=0) for instructions installing the PulsePal MATLAB software
    - Ignore instructions regarding the PsychToolbox serial interface
4) Ensure `bpod_galvostation` is downloaded and included in the MATLAB path
    - `bpod_galvostation` can be downloaded from [here](https://github.com/olfactorybehaviorlab/bpod_galvostation)

## (OPTIONAL) Camera Software:
If needed, please visit [dewan_flir_camera](https://github.com/olfactorybehaviorlab/dewan_flir_camera) for instructions on setting up the Blackfly S USB Camera

