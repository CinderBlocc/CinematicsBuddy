-- KeyframeSetter applies data from a keyframe to the CinematicsBuddy objects in the scene.

-- Import UtilityFunctions script so its functions can be called
FileIn(CBSupportScripts + "UtilityFunctions.ms")

-- SUPPORT FUNCTION DEFINITIONS --
function ApplyMetadataDummyAnimation KeyframeTime KeyframeData MetadataDummy bFirstKeyframe = 
(
	local TheModifier = MetadataDummy.modifiers[1]
	local TheReplayFrame = KeyframeData.TimeKeyframe.ReplayFrame
	
	-- Set the start and end frame range values (not animated)
	if bFirstKeyframe == true then
	(
		TheModifier.ReplayStartFrame = TheReplayFrame
		TheModifier.ReplayEndFrame   = TheReplayFrame
	)
	else
	(
		if TheReplayFrame < TheModifier.ReplayStartFrame do (TheModifier.ReplayStartFrame = TheReplayFrame)
		if TheReplayFrame > TheModifier.ReplayEndFrame   do (TheModifier.ReplayEndFrame   = TheReplayFrame)
	)
	
	-- Set the animation values
	at time KeyframeTime
	(
		TheModifier.ReplayCurrentFrame = TheReplayFrame
	)
)

function ApplyCameraAnimation KeyframeTime KeyframeData CameraObject = 
(
	-- Set the animation values
	at time KeyframeTime
	(
		CameraObject.rotation = KeyframeData.CameraKeyframe.CameraRotation
		CameraObject.pos      = KeyframeData.CameraKeyframe.CameraLocation
		CameraObject.fov      = KeyframeData.CameraKeyframe.CameraFieldOfView
		
		CameraObject.rotation.z_rotation.controller.value -= 90
		CameraObject.rotation.x_rotation.controller.value += 90
	)
)

function ApplyBallAnimation KeyframeTime KeyframeData BallDummy = 
(
	-- Set the animation values
	at time KeyframeTime
	(
		BallDummy.rotation = KeyframeData.BallKeyframe.BallRotation
		BallDummy.pos      = KeyframeData.BallKeyframe.BallLocation
	)
)

function FindCarKeyframe KeyframeData CarDummyModifier = 
(
	-- Loop through the array of car keyframes to find one with an index that matches CarDummy's index
	for CarKeyframe in KeyframeData.CarKeyframes do
	(
		if CarKeyframe.CarSeenIndex == CarDummyModifier.CarsSeenIndex do
		(
			return CarKeyframe
		)
	)
	
	return undefined
)

function ApplyCarAnimation KeyframeTime KeyframeData CarDummy = 
(
	local TheModifier = CarDummy.modifiers[1]
	local TheCarKeyframe = FindCarKeyframe KeyframeData TheModifier
	
	-- Set the animation values
	at time KeyframeTime
	(
		if TheCarKeyframe == undefined then
		(
			-- FREEZE AT ORIGIN --
			
			-- Physical attributes
			CarDummy.rotation = Quat 0 0 0 0
			CarDummy.pos      = Point3 0 0 0
			
			-- Modifier attributes (Maxscript starts arrays at 1)
			TheModifier.bIsDemolished = true
			TheModifier.bIsBoosting   = false
			TheModifier.Wheel0_SteerAmount    = 0
			TheModifier.Wheel0_SuspensionDist = 0
			TheModifier.Wheel0_SpinSpeed      = 0
			TheModifier.Wheel1_SteerAmount    = 0
			TheModifier.Wheel1_SuspensionDist = 0
			TheModifier.Wheel1_SpinSpeed      = 0
			TheModifier.Wheel2_SteerAmount    = 0
			TheModifier.Wheel2_SuspensionDist = 0
			TheModifier.Wheel2_SpinSpeed      = 0
			TheModifier.Wheel3_SteerAmount    = 0
			TheModifier.Wheel3_SuspensionDist = 0
			TheModifier.Wheel3_SpinSpeed      = 0
		)
		else
		(
			-- APPLY THE REAL ANIMATION --
			
			-- Physical attributes
			CarDummy.rotation = TheCarKeyframe.CarRotation
			CarDummy.pos      = TheCarKeyframe.CarLocation
			
			-- Modifier attributes (Maxscript starts arrays at 1)
			TheModifier.bIsDemolished = false
			TheModifier.bIsBoosting   = TheCarKeyframe.bIsBoosting
			TheModifier.Wheel0_SteerAmount    = TheCarKeyframe.WheelKeyframes[1].SteerAmount
			TheModifier.Wheel0_SuspensionDist = TheCarKeyframe.WheelKeyframes[1].SuspensionDistance
			TheModifier.Wheel0_SpinSpeed      = TheCarKeyframe.WheelKeyframes[1].SpinSpeed
			TheModifier.Wheel1_SteerAmount    = TheCarKeyframe.WheelKeyframes[2].SteerAmount
			TheModifier.Wheel1_SuspensionDist = TheCarKeyframe.WheelKeyframes[2].SuspensionDistance
			TheModifier.Wheel1_SpinSpeed      = TheCarKeyframe.WheelKeyframes[2].SpinSpeed
			TheModifier.Wheel2_SteerAmount    = TheCarKeyframe.WheelKeyframes[3].SteerAmount
			TheModifier.Wheel2_SuspensionDist = TheCarKeyframe.WheelKeyframes[3].SuspensionDistance
			TheModifier.Wheel2_SpinSpeed      = TheCarKeyframe.WheelKeyframes[3].SpinSpeed
			TheModifier.Wheel3_SteerAmount    = TheCarKeyframe.WheelKeyframes[4].SteerAmount
			TheModifier.Wheel3_SuspensionDist = TheCarKeyframe.WheelKeyframes[4].SuspensionDistance
			TheModifier.Wheel3_SpinSpeed      = TheCarKeyframe.WheelKeyframes[4].SpinSpeed
		)
	)
)

function ApplyCarAnimations KeyframeTime KeyframeData CarDummies = 
(
	for CarDummy in CarDummies do
	(
		ApplyCarAnimation KeyframeTime KeyframeData CarDummy
	)
)

-- MAIN FUNCTION DEFINITIONS --
function ApplyKeyframe KeyframeData SceneObjects ImportTypes bFirstKeyframe = 
(
	-- Get keyframe time as a factor of frames at 60 fps
	local KeyframeTime = KeyframeData.TimeKeyframe.RealTime * 60
	
	set animate on
	ApplyMetadataDummyAnimation KeyframeTime KeyframeData SceneObjects.MetadataDummy bFirstKeyframe
	
	if ImportTypes.bImportCamera == true do
	(
		ApplyCameraAnimation KeyframeTime KeyframeData SceneObjects.CameraObject
	)
	
	if ImportTypes.bImportBall == true do
	(
		ApplyBallAnimation KeyframeTime KeyframeData SceneObjects.BallDummy
	)
	
	if ImportTypes.bImportCars == true do
	(
		ApplyCarAnimations KeyframeTime KeyframeData SceneObjects.CarDummies
	)
	set animate off
)
