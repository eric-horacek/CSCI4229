#CSCI 4229 Semester Project

Semester Project for Willem Schreuder's **CSCI 4229 Computer Graphics** Class

By **Eric Horacek** and **Devon Tivona**

##Dependencies & Setup

This is an Xcode Project, so it must be compiled on a system running Mac OSX with an install of Xcode that has an iOS SDK of 5.0 or greater. This project uses the [NinevehGL](http://nineveh.gl) graphics framework, which is included in the `Vendor` folder.

This project uses **CocoaPods** to manage its dependencies. You must have the `pod` ruby gem installed to properly install and build this project's dependencies. To set up this project, run `$ pod install` in the root directory of this repo. See [cocoapods.org](http://cocoapods.org) for more information on this process.

##Building & Running

After you set up the project using the `pod` ruby gem, open the `CSCI4229.xcworkspace` in Xcode, and then build and run the CSCI4229 target using `command-R`.

##Performance

Because this project and **NinevehGL** graphics library are meant to run on-device, this project will run slowly and will be somewhat hard to operate in the iPhone Simulator. You must run it on an iPhone or iPad for it to reach ~60 FPS. Additionally, the movement controls require input from multiple fingers simultaneously to explore the 3D world, which is nearly impossible on the iPhone Simulator.

##Navigation Paradigm

The navigation paradigm for this 3D world centers around two touch-based "joysticks" in the bottom left and bottom right of the screen (see the **Screenshots** section).

* The joystick on the left **translates** the camera within the x-y plane.
* The joystick on the right **rotates** the camera within the x-y plane.

This navigation paradigm is very similar to that of video-game console console controllers (e.g. Xbox 360, PS3, etc.).

##Screenshots

![11/26/2012](https://raw.github.com/eric-horacek/CSCI4229/master/Screenshots/11-26-2012.png)

##Remaining Work (For 11/26/12 Project Review)

There still needs to be more time spent populating the environment with more 3D features (trees, buildings, points of interest, etc.). Additionally, we would still like to do rudimentary physics that provide collision detection between the camera and the ground. We'd also like for the user to be able to use an alternate interface paradigm to navigate the 3D world rather than just first-person (such as with an avatar from the 3rd person).
