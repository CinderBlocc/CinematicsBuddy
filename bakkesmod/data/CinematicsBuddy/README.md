# Cinematics Buddy Plugin

*If you are reading this file in notepad, I would recommend going to [this link](https://github.com/CinderBlocc/CinematicsBuddyPlugin/tree/master/bakkesmod/data/CinematicsBuddy/README.md) to view the formatted readme page.*

[Video tutorial series here](https://youtube.com/playlist?list=PLnGMqVCpN88qI-OFDpCStYTqO9bwqymq-)

## OVERVIEW
CinematicsBuddy is a tool designed to make life easier for editors and spectators. It provides features for capturing camera / ball / car animation, and overriding inputs for more refined control over the camera with controllers or keyboard and mouse. Below are the instructions for each part of the plugin.

For instructions about third party scripts (such as 3ds Max and After Effect's importers), refer to their respective readme files listed below.
- [3ds Max](https://github.com/CinderBlocc/CinematicsBuddyMaxscript/tree/master/bakkesmod/data/CinematicsBuddy/Plugins/3dsMax/README.md)
- [After Effects](https://github.com/CinderBlocc/CinematicsBuddyAE/tree/main/bakkesmod/data/CinematicsBuddy/Plugins/AfterEffects/README.md)

Each of the settings described below follows this format:
- `Setting UI name` - `Setting internal name` *(default value, minimum, maximum)* Setting description.

## EXPORTING

###### NORMAL RECORDING
- `Automatically Increment File Names` - `CB_bIncrementFileNames` *(true, -, -)* Appends a number to the end of a file name when a recording is saved with the same name as an existing recording. This is to prevent overwriting existing recordings. For example, file names would be as follows: MyRecording, MyRecording_02, MyRecording_03, etc.
- `Save Current Dollycam Path` - `CB_bSaveDollycamPath` *(false, -, -)* If there is a currently active dollycam path, it will be saved next to the recording file. Requires Dollycam 2.1 or later.
- `File Name` - `CB_FileName` *("", -, -)* The name given to the recording file when it is saved.
- `Camera Name` - `CB_CameraName` *("", -, -)* The name given to the camera. **Camera Name does not increment along with the file name.**
- `Special Path` - `Checkbox: CB_bSetFilePath` *(false, -, -) Refer to the next "Special Path" description.*
- `Special Path` - `Textbox: CB_FilePath` *("", -, -)* Allows the user to override the default export path of /bakkesmod/data/CinematicsBuddy/AnimationExports/. The checkbox must be enabled before an override path can be added. A **full path** must be provided. For example: `C:\MyProjectFolder\Recordings\CinematicsBuddyCaptures`. A trailing slash is no longer necessary and back slashes should work as well as forward slashes, even if they get duplicated.
- `Start Recording` - `CBRecordingStart` *(-, -, -)* Starts the recording. **File Name** and **Camera Name** must have text in the textboxes, and **Special Path** must either be empty, or have a valid full path.
- `Stop Recording` - `CBRecordingStop` *(-, -, -)* Stops the recording and immediately saves the file. The file is written in a separate thread and the UI will be greyed out until it has finished.
- `Max Recording Length (Seconds)` - `CB_Recording_MaxLength` *(300, 0, 1000)* Automatically stops and saves the recording after the specified length of time.

###### BUFFER RECORDING
- `Enable Buffer` - `CB_Buffer_bEnabled` *(false, -, -)* Enables constantly recording buffer. Buffer will store the last X seconds of animation history - X is defined by **Max buffer length (seconds)**.
- `Capture Buffer` - `CBBufferCapture` *(-, -, -)* Saves all the data from the buffer to a recording file.
- `Clear Buffer` - `CBBufferClear` *(-, -, -)* Empties all the data out of the buffer.
- `Max Buffer Length (Seconds)` - `CB_Buffer_MaxLength` *(30, 0, 1000)* How much history to save in the buffer.

###### HIDDEN
- There is a notifier that isn't in the UI - `CBConvertUnits` - that you can use to determine where to place objects in a third party program. To use this, move the camera to the location you want to place an object, use the command (either via a keybind, or by typing into the console), and it will copy the converted location to your clipboard. Paste that information into something like notepad, then use that info to set the location of the object.

Example unit conversion output:

    ROCKET LEAGUE: -2280.818, 3792.814, 1229.952
    3DS MAX: -2280.818, -3792.814, 1229.952
    AFTER EFFECTS: 9633.748, -3124.078, -5793.27


## CAMERA OVERRIDES

###### HIDDEN
- There is another notifier that isn't in the UI - `CBCameraReset` - that you can use to set all the acceleration and velocity values to zero. A good example for when to use this would be when setting the camera to a specific location using the [SpectatorControls plugin](https://bakkesplugins.com/plugins/view/107).

###### CHECKBOXES
- `Enable Overrides` - `CB_Camera_bUseCamOverrides` *(false, -, -)* Globally enables or disables the camera overrides feature.
- `Freeze` - `CB_Camera_bFreeze` *(false, -, -)* Blocks inputs to the camera. When enabled, existing momentum will still taper off, but new momentum won't be added.
- `Local Momentum Preservation` - `CB_Camera_bLocalMomentum` *(false, -, -)* Camera either maintains linear momentum, or follows the direction the camera is facing.
- `Local Movement` - `CB_Camera_bUseLocalMovement` *(true, -, -)* Camera moves according to its local axes. For instance if you are looking downward and press forward, the camera will move in the direction you are looking.
- `Local Rotation` - `CB_Camera_bUseLocalRotation` *(false, -, -)* Camera rotates along its local axes. This effect is particularly noticable when the camera is rolled more than 45 degrees and pitch or yaw inputs are given.
- `Invert Pitch (Controller)` - `CB_Camera_bInvertControllerPitch` *(false, -, -)* Inverts the pitch inputs from the controller. Does not affect mouse input.
- `Hard Floors` - `CB_Camera_bHardFloors` *(true, -, -)* Prevents the camera from going below the floor. The floor is specified by the **Floor Height** variable.

###### SLIDERS
- `Floor Height` - `CB_Camera_FloorHeight` *(10, -50, 50)* When **Hard floors** is enabled, this determines how low the camera can go.
- `Movement Speed` - `CB_Camera_MovementSpeed` *(1, 0, 5)* Max speed of camera linear velocity.
- `Movement Acceleration` - `CB_Camera_MovementAccel` *(1, 0, 5)* How long it takes to reach max speed. A higher number will reach max speed faster.
- `Rotation Speed (Mouse)` - `CB_Camera_RotationSpeedMouse` *(1, 0, 3)* Max speed of mouse rotation. These rotations are defined by the mouse's delta movement.
- `Rotation Speed (Non-Mouse)` - `CB_Camera_RotationSpeedGamepad` *(1, 0, 3)* Max speed of non-mouse rotation. These are rotations defined by a rate of rotation. Keyboard inputs also count toward this.
- `Rotation Acceleration (Mouse)` - `CB_Camera_RotationAccelMouse` *(1, 0, 10)* How long it takes mouse rotation to reach max speed. *NOTE: really high acceleration values cause large rotation stutters.*
- `Rotation Acceleration (Non-Mouse)` - `CB_Camera_RotationAccelGamepad` *(1, 0, 10)* How long it takes controller rotation to reach max speed.
- `FOV Rotation Scale` - `CB_Camera_FOVRotationScale` *(.3, 0, 1)* Multiplier for rotation speed as FOV zooms in. The lower this number, the slower the rotation becomes when you zoom in.
- `FOV Minimum` - `CB_Camera_FOVMin` *(20, 5, 170)* The lower limit of FOV.
- `FOV Maximum` - `CB_Camera_FOVMax` *(120, 5, 170)* The upper limit of FOV. *NOTE: If minimum is greater than maximum, it will become the new maximum and vice versa.*
- `FOV Speed` - `CB_Camera_FOVSpeed` *(1, 0, 3)* Max speed of zoom change.
- `FOV Acceleration` - `CB_Camera_FOVAcceleration` *(1, 0, 10)* How long it takes FOV change to reach max speed.
- `FOV Limit Ease` - `CB_Camera_FOVLimitEase` *(.1, 0, .5)* If current FOV is taken as a percentage between Minimum and Maximum, this specifies how close that percentage must be toward the lower or upper bounds before it starts easing into that limit.

###### INPUT SWAPPING
- `Toggle Roll Binding` - `CB_Camera_RollBinding` *(Xbox RB - PS4 R1, -, -)* The button that needs to be held to initiate the **Roll Input Swap**.
- `Roll Input Swap` - `CB_Camera_RollSwap` *(Yaw, -, -)* The input to be swapped with roll. By default, when holding the right bumber, left and right on the right analog stick will roll instead of yaw.
- `Toggle FOV Binding` - `CB_Camera_FOVBinding` *(Xbox LB - PS4 L1, -, -)* The button that needs to be held to initiate the **FOV Input Swap**.
- `FOV Input Swap` - `CB_Camera_FOVSwap` *(Right, -, -)* The input to be swapped with FOV. By default, when holding the left bumber, left and right on the left analog stick will zoom in and out instead of move the camera left and right.

###### CONFIGS
- `Current Config` - `CB_Config_Current` *("", -, -)* A dropdown menu displaying the available configs. Configs are stored as `.cfg` files in /data/CinematicsBuddy/CameraConfigs/ and any subfolders within that folder. Selecting an option from this dropdown will apply the settings from that config file.
- `Update Config List` - `CBConfigUpdateList` *(-, -, -)* Recursively loops through all files in /data/CinematicsBuddy/CameraConfigs/ and its subfolders and adds `.cfg` files to the list.
- `New Config Name` - `CB_Config_NewName` *("", -, -)* The name given to the new file when you click **Save Config**.
- `Save Config` - `CBConfigSave` *(-, -, -)* Saves all camera override settings to a config file. The file's name is specified by **New Config Name** and will be saved in the /data/CinematicsBuddy/CameraConfigs/ folder.