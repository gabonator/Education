# Gabriel valky

In this list you will see some interesting projects I was working on

## 2020

### Voice controlled beer hoist
- Hardware / software project with offline hotword voice analyser running on Raspberry pi
- Project in progress. Raspberry pi runs snowboy hotword detection library. Recognized commands are sent through bluetooth to arduino based controller which controls hoist. Precise control of hoist is achieved using hall sensor counting the hoists drum turns. 
- [Code](https://github.com/gabonator/Projects/tree/master/BeerHoist)
- Unofficial video:

[![Beer hoist](https://img.youtube.com/vi/QlplAXO4FNo/0.jpg)](https://www.youtube.com/watch?v=QlplAXO4FNo "Beer hoist test")

### Reverse engineering of USB camera protocol
- Reverse engineering, USB protocol, software
- Laboratory grade 10Mpx camera for use in microscopes with no support for OSX
- Protocol was captured on windows machine using their own camera software with Wireshark
- Simple bayer demosaicing and exposure control
- [Code](https://github.com/gabonator/Work-in-progress/blob/master/AmScope/main.cpp)

![Amscope camera](res/2020_amscope.jpg)

## 2019

### Laser projector experiments
- Software project, protocol reverse engineering
- Galvanometer based laser RGB projector system allows remote control using bluetooth. Protocol was reverse engineered by analysing android application supplied by the manufacturer.
- [Protocol reverse engineering](https://github.com/gabonator/Work-in-progress/tree/master/RgbLaserProjector)
- Various 2D / 3D geometry generating algorithms were designed in javascript, the animation was generated offline and then uploaded to the projector
- See online: [wormhole](https://rawgit.valky.eu/gabonator/Work-in-progress/master/LaserApps/wormhole/index.html), [spiral](https://rawgit.valky.eu/gabonator/Work-in-progress/master/LaserApps/spiral3d/index.html)
- [Code](https://github.com/gabonator/Work-in-progress/tree/master/LaserApps)
- Development of interactive version using ILDA interface is in progress...
- Video:
 
[![Beer hoist](https://img.youtube.com/vi/iCVEEQ8QII4/0.jpg)](https://www.youtube.com/watch?v=iCVEEQ8QII4 "Laser projector experiments")

### Lectures for Creative point (Slovak business agency)
- Teaching and lectures
- Teaching how to make simple arduino base projects for attendees with no previous engineering experience, e.g.: [Midi synthesizer with capacitive sensing](https://github.com/gabonator/Education/tree/master/2019/MidiSynth), [Simple IoT weather station](https://github.com/gabonator/Education/tree/master/2019/creativePointWeather), [Laser projector with two servo motors](https://github.com/gabonator/Education/tree/master/2019/Servo)...

### Webusb oscilloscope with DS203
- Microcontroller software project with WebUSB technology
- WebUSB allows web browser to talk to USB peripherals
- [Full project description](https://github.com/gabonator/Education/blob/master/2019/WebUsb/readme.md)
- Video: 

[![WebUsb Oscilloscope video](https://img.youtube.com/vi/aghTg4Pggv4/0.jpg)](https://www.youtube.com/watch?v=aghTg4Pggv4 "WebUsb Oscilloscope")

### Operating system for ARM M3 (STM32F103)
- Microcontroller software project
- [Full project description](https://github.com/gabonator/LA104)
- ![LA104 DS203 operating system](res/2019_laos.jpg)

## 2018

### Rigidity measurement system with CDC
- Hardware / software project with ESP8266 and load sensor
- The rigidity and damping effect of plastic shock absorber for HVAC systems is being analysed. The plastic absorber introduces small hole in its piston to allow the air to flow in and out when the piston is pressed. The manufacturer wanted to examine the behaviour of the absorber and verify if the damping attributes are in allowed range.
- System is based on Load sensor cell which measures what force is produced when the CDC machine pulls the piston in and out. Measured values are transmitted over WiFi to software running on computer (web based application communicating through websockets with the ESP8266 MCU)
- [Code](https://github.com/gabonator/Projects/tree/master/CncRigidityMeas)
- Video: 

[![Rigidity measurement](https://img.youtube.com/vi/K8F_eh5UJhA/0.jpg)](https://www.youtube.com/watch?v=K8F_eh5UJhA "Rigidity measurement")

## 2016

### Tuneller in NaCl
- Software, Pepper NaCl
- Google's Native Client technology allows running native code in web browser
- Multiplayer tunellers game (in C++) was designed and players can join the game just by opening a web page
- NaCl techology later was deprecated by google and replaced by Wasm
- [Code](https://github.com/gabonator/Work-in-progress/tree/master/ChromeNaCl/tuneller)
- Picture of another NaCl game, screenshot TBD: 

![Worms](res/2016_tuneller.jpg)

### Custom MESH wireless stack
- Software, hardware, microcontroller
- Allows building complex mesh networks with CC1101 transceiver
- [Full project description](https://github.com/gabonator/Work-in-progress/tree/master/PanstampSwap)

### Download manager with voice captcha cracker
- Software project, signal analysis
- Integration with Synology disk station
- [Voice recognition](https://github.com/gabonator/Work-in-progress/tree/master/SynologySearchEngine/UlozToCz)
- [Synology download station integration](https://github.com/gabonator/SynologyUlozTo)

## 2014

### HW Reverse engineering of Garmin HUD
- Hardware, reverse engineering
- Garmin HUD display is a device which shows you the driving instructions after pairing with compatible navigation app over bluetooth
- [Code](https://github.com/gabonator/Work-in-progress/tree/master/GarminHud)
- [Hackaday article](http://hackaday.com/2014/03/30/controlling-the-garmin-hud-with-bluetooth/)
- Video:

[![Garmin HUD and Sygic](https://img.youtube.com/vi/WK9IV0syupE/0.jpg)](https://www.youtube.com/watch?v=WK9IV0syupE "Garmin HUD and Sygic")

### DOS Games running in web browser
- Software project, reverse engineering
- Games were disassembled using IDA, generated assemby was fed through processor which turns the instructions into javascript or C++
- Web browser simulates graphics card and programmable interrupt controller and other necessary components
- ![Alley cat](res/2014_cat.png)
- Play online: [Alley cat](https://rawgit.valky.eu/gabonator/Work-in-progress/master/DosGames/CicParser2017/js/test.html), [Star goose](https://rawgit.valky.eu/gabonator/Work-in-progress/master/DosGames/JsGoose/index.html)
- Code: [Alley cat](https://github.com/gabonator/Work-in-progress/tree/master/DosGames/CicParser2017), [Star goose](https://github.com/gabonator/Work-in-progress/tree/master/DosGames/JsGoose)

## 2013

### Label generator for CNC machine
- Software
- CNC G-code generator for engraving labels
- [Projet description and code](https://github.com/gabonator/Projects/tree/master/TypoCnc)
- [Try online](https://rawgit.valky.eu/gabonator/Projects/master/TypoCnc/typo.html)

![Typo carver](res/2013_typocarver.png)

### Geiger tracker
- Hardware / Software project
- Geiger Counter and GPS is attached to a laptop computer and this mobile station measures levels od ionizing radiation during driving and results are visualized in a map
- [See online](https://rawgit.valky.eu/gabonator/Work-in-progress/master/GeigerTracker/visualization/index.html)
- [Code](https://github.com/gabonator/Work-in-progress/tree/master/GeigerTracker/visualization)

![Geiger tracker](res/2013_geiger.png)

### DS203 Oscilloscope firmware
- Software microcontroller project
- DS203 oscilloscope firmware with advanced features
- [Full project description](https://github.com/gabonator/DS203)
- ![DS203 oscilloscope](res/2013_osc.png)

## Papers:
- 2013 [Greenhouse monitoring system](http://gabo.valky.eu/?data/research/elitech2013.txt)
- 2012 [Signal processing and reconstruction](http://iris.elf.stuba.sk/JEEEC/data/pdf/7s_112-19.pdf)
- 2012 [ECG measurement system with novel visualization](http://gabo.valky.eu/data/about/bhi2012_paper.pdf)

## Todo:
- Moooby.tv flash multiplayer games 
- ORK100
- AtomClock
- Webotherm
- add thesis to papers
