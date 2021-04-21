# Cinematics Buddy Maxscript

*If you are reading this file in notepad, I would recommend going to [this link](https://github.com/CinderBlocc/CinematicsBuddyMaxscript/tree/master/bakkesmod/data/CinematicsBuddy/Plugins/3dsMax) to view the formatted readme page.*

## OVERVIEW
CinematicsBuddy Maxscript is part of the overall [Cinematics Buddy tool](https://github.com/CinderBlocc/CinematicsBuddy). This script is capable of importing an animation file that was recorded inside Rocket League and reconstructing it with rough meshes inside 3ds Max.

## IMPORT ANIMATION FILE

Importing a file will reconstruct the animation inside the viewport using rough meshes to approximate the game models. A hidden object called "MetadataDummy" is also created. That object stores all the necessary data for CinematicsBuddy to work inside 3ds Max, so don't delete it.

- `Choose File` - This is the only enabled button when the script is first run. Clicking on it will open a file explorer dialog for you to find the animation file you want to import. After choosing a valid file, the other UI elements will be enabled.
- `"Import" Groupbox` - Checkboxes to indicate which types of objects you want to import from the animation file. If a scene has already been imported, **Ball** and **Cars** will not be available to reimport. Only **Camera** will be available.
- `Camera Name` - After you have chosen the file, it will parse the header and pull the camera name from the file. This textbox lets you edit the camera name before clicking **Confirm** and creating the camera.
- `Confirm` - Locks in all of your choices, then reads all the keyframes from the file and reconstructs the scene. 3ds Max may freeze temporarily during this process, so be patient until it finishes the process.


###### Multi-Camera Sync

After you've imported a scene, you can import additional camera angles that were recorded within the same time range of the replay in Rocket League. The additional angles will do their best to automatically sync the animations. For example, if the first scene you imported ranged from frame 0 to frame 1000 of the in-game replay, and your second camera was recorded from frame 250 to frame 1250, the second camera will start playing its animation a quarter of the way through the scene and end at the same time as the original scene - its final range would be 250 - 1000.

The sync won't always be perfect, so each camera has a "Sync Shift" modifier you can use to shift all the keyframes by a specified amount of time.

The sync assumes that all camera angles were recorded at the same speed in game. It doesn't attempt to compensate if the speeds are different.
