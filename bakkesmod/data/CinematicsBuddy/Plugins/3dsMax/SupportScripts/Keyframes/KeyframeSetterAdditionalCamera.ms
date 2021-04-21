-- KeyframeSetterAdditionalCamera handles importing an additional camera and attempts to sync it with the rest of the scene

-- Import KeyframeSetter script so ApplyCameraAnimation can be called
FileIn(CBSupportScripts + "Keyframes\\KeyframeSetter.ms")

-- STRUCT DEFINITIONS --
struct StructSyncData
(
	FirstValidKeyframe,
	AnimationStartTime,
	bStartedLate
)

-- SUPPORT FUNCTION DEFINITIONS --
function FindSyncData ImportedFile MetadataDummy = 
(
	local SyncData = StructSyncData()
	SyncData.FirstValidKeyframe = undefined
	SyncData.AnimationStartTime = -1
	SyncData.bStartedLate = false
	
	local TheModifier = MetadataDummy.modifiers[1]
	
	-- Determine the relative time position of the new camera
	local FirstKeyframe = GetKeyframe(ImportedFile)
	if FirstKeyframe == undefined then
	(
		return SyncData
	)
	else
	(
		local FirstKeyframeTime = FirstKeyframe.TimeKeyframe.ReplayFrame
		
		-- New animation starts before MetadataDummy's animation
		if FirstKeyframeTime < TheModifier.ReplayStartFrame do
		(
			-- Read through the new camera's keyframes until an eligible keyframe is found
			while not eof ImportedFile do
			(
				local NextKeyframe = GetKeyframe(ImportedFile)
				if NextKeyframe != undefined then
				(
					if IsValidKeyframe NextKeyframe MetadataDummy do
					(
						SyncData.FirstValidKeyframe = NextKeyframe
						SyncData.AnimationStartTime = 0
						return SyncData
					)
				)
				else
				(
					return SyncData
				)
			)
		)
		
		-- New animation starts after MetadataDummy's animation
		if FirstKeyframeTime > TheModifier.ReplayStartFrame do
		(
			-- Find the moment that MetadataDummy's ReplayCurrentFrame matches the start time of the new camera
			local MDTimeController = TheModifier.ReplayCurrentFrame.Controller
			local KeyframeIndex = 1
			while KeyframeIndex < MDTimeController.Keys.Count do
			(
				local MDTimeKeyframe = GetKey MDTimeController KeyframeIndex
				KeyframeIndex += 1
				
				if MDTimeKeyframe.Value >= FirstKeyframeTime do
				(
					SyncData.FirstValidKeyframe = FirstKeyframe
					SyncData.AnimationStartTime = MDTimeKeyframe.Time
					SyncData.bStartedLate = true
					return SyncData
				)
			)
		)
		
		-- New animation starts at the same time as MetadataDummy's animation
		if FirstKeyframeTime == TheModifier.ReplayStartFrame do
		(
			SyncData.FirstValidKeyframe = FirstKeyframe
			SyncData.AnimationStartTime = 0
			return SyncData
		)
	)
	
	return SyncData
)

function IsValidKeyframe KeyframeData MetadataDummy = 
(
	local TheModifier = MetadataDummy.modifiers[1]
	
	if KeyframeData.TimeKeyframe.ReplayFrame < TheModifier.ReplayStartFrame do
	(
		return false
	)
	
	if KeyframeData.TimeKeyframe.ReplayFrame > TheModifier.ReplayEndFrame do
	(
		return false
	)
	
	return true
)

function GetKeyframeTime KeyframeData SyncData = 
(
	-- Get the real time gap in seconds between the current keyframe and the first keyframe
	local TimeGap = KeyframeData.TimeKeyframe.RealTime - SyncData.FirstValidKeyframe.TimeKeyframe.RealTime
	
	-- Get time as a factor of frames at 60 fps
	local Converted = TimeGap * 60
	
	-- Shift based on start time from SyncData
	local FinalTime = Converted + SyncData.AnimationStartTime
	
	return FinalTime
)

-- MAIN FUNCTION DEFINITION --
function ApplyCameraOnlyKeyframe KeyframeData SceneObjects SyncData = 
(
	-- Check if this keyframe's animation has gone past the end of the animation range stored in MetadataDummy
	if IsValidKeyframe KeyframeData SceneObjects.MetadataDummy do
	(
		local KeyframeTime = GetKeyframeTime KeyframeData SyncData
		
		set animate on
		ApplyCameraAnimation KeyframeTime KeyframeData SceneObjects.CameraObject
		set animate off
		
		return true
	)
	
	return false
)
