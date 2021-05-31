# Cinematics Buddy After Effects

*If you are reading this file in notepad, I would recommend going to [this link](https://github.com/CinderBlocc/CinematicsBuddyAE/blob/main/bakkesmod/data/CinematicsBuddy/Plugins/AfterEffects/README.md) to view the formatted readme page.*

[Video tutorial series here](https://youtube.com/playlist?list=PLnGMqVCpN88qI-OFDpCStYTqO9bwqymq-)

## IMPORTING ANIMATION FILE

Make sure you have an active comp, then go to `File > Scripts > Run Script File` and navigate to the CinematicsBuddyAE.js script file which is in the `/bakkesmod/data/CinematicsBuddy/Plugins/AfterEffects/` folder. If you have run the script before, you can choose `File > Scripts > Recent Script Files` and find CinematicsBuddyAE.js in that list.

When you run the script, it will immediately open a File Explorer window so you can find an animation file that was recorded from Rocket League. Choose the file you want, then let the script run through its process.

## RECONSTRUCTED SCENE

###### Layers

When the script runs, it will create a lot of layers. The layers are as follows:
- Camera
- Null object for the ball
- Null object for each of the cars that was seen throughout the recording
	- If a car is demolished, its null will be sent to the middle of the field and its opacity will be set to 0. Link things like emitters to the opacity so that it doesn't emit a long thin trail from where the car was to where it currently sits in the middle of the field.
- "Orange/Blue Goal" text layers that should fit just inside the goal posts. Use these to align the timeline better (described later)
- Grids for the walls, ceiling, and floor to help align timeline

###### Alignment

When the scene is reconstructed, it might not line up with the footage. To line it up, select the camera and all of the null objects (ball and cars) and drag them left or right in the timeline until the text and the grids line up with the footage.
