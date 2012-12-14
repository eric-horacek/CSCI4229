#CSCI 4229 Semester Project

Semester Project for Willem Schreuder's **CSCI 4229 Computer Graphics** Class

By **Eric Horacek** and **Devon Tivona**

##Dependencies & Setup

This is an Xcode Project, so it must be compiled on a system running Mac OSX with an install of Xcode that has an iOS SDK of 5.0 or greater. This project uses the [Cocos3D](http://http://brenwill.com/cocos3d/) plugin for the [Cocos2D](http://www.cocos2d-iphone.org) framework, both of which are included in the project. These frameworks are thin wrappers around OpenGL ES 2.0 that allow us to write graphics code in Objective-C, automatically load models from .POD files, and establish dependence hierarchies between graphics objects.

This project uses **CocoaPods** to manage its dependencies. You must have the `pod` ruby gem installed to properly install and build this project's dependencies. To set up this project, run `$ pod install` in the root directory of this repo. See [cocoapods.org](http://cocoapods.org) for more information on this process.

##Building & Running

After you set up the project using the `pod` ruby gem, open the `CSCI4229.xcworkspace` in Xcode, and then build and run the CSCI4229 target using `command-R`.

##Navigation Paradigm

To navigate the avatar around the 3D world, simply tap on the ground where you want him to go. A particle system will appear where the user taps, and then the avatar will travel to that location. Moreover, the program uses the A* Shortest Path algorithm to prevent the avatar from running into various objects around the scene when he is navigating the select location.

##Cameras

There are two ways to view the world in this technology demo. The default camera is a third-person camera that follows the avatar around as he moves. A drag gesture while in this view will rotate the camera round the avatar, so that you can see the entire world. When in this camera mode, you can use a pinch gesture to zoom in and out on the camera.

If you zoom in far enough, the camera will switch to a first-person mode, allowing you to see the world from the avatar's perspective. When you are in this camera perspective, a drag gesture will allow you to look around the world. To return to third person mode, use a pinch gesture.

When in third-person mode, you may also tap the avatar to enter first-person mode.

##Performance

Because this project and **Cocos3D** graphics library are meant to run on-device, this project will run slowly and will be somewhat hard to operate in the iPhone/iPad Simulator. You must run it on an iPhone or iPad for it to reach ~60 FPS. Additionally, the movement controls require input from multiple fingers simultaneously to explore the 3D world, which is nearly impossible on the iPhone Simulator.

##Screenshots

![12/9/2012](https://raw.github.com/eric-horacek/CSCI4229/master/Screenshots/12-9-2012.png)