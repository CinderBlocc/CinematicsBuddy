-- KeyframeGetter reads data from ImportedFile to extract a keyframe.

-- Import UtilityFunctions script so its functions can be called
FileIn(CBSupportScripts + "UtilityFunctions.ms")
	
-- STRUCT DEFINITIONS --
struct StructTimeKeyframe
(
	RealTime,
	ReplayFrame
)

struct StructCameraKeyframe
(
	CameraLocation,
	CameraRotation,
	CameraFieldOfView
)

struct StructBallKeyframe
(
	BallLocation,
	BallRotation
)

struct StructWheelKeyframe
(
	WheelIndex,
	SteerAmount,
	SuspensionDistance,
	SpinSpeed
)

struct StructCarKeyframe
(
	CarSeenIndex,
	CarLocation,
	CarRotation,
	bIsBoosting,
	WheelKeyframes = #()
)

struct StructKeyframeData
(
	TimeKeyframe,
	CameraKeyframe,
	BallKeyframe,
	CarKeyframes = #()
)

-- SUPPORT FUNCTION DEFINITIONS --
function GetTimeKeyframe ImportedFile = 
(
	local TimeKeyframe = StructTimeKeyframe()
	
	while not eof ImportedFile do
	(
		local ThisLine = ReadLine ImportedFile
		if ThisLine.count == 0 do exit
		
		local SplitLine = GetSplitDataLine(ThisLine)
		case SplitLine.LineLabel of
		(
			"T":  TimeKeyframe.RealTime    = SplitLine.LineValue as float
			"RF": TimeKeyframe.ReplayFrame = SplitLine.LineValue as integer
			"}": exit
		)
	)
	
	return TimeKeyframe
)

function GetCameraKeyframe ImportedFile = 
(
	local CameraKeyframe = StructCameraKeyframe()
	
	while not eof ImportedFile do
	(
		local ThisLine = ReadLine ImportedFile
		if ThisLine.count == 0 do exit
		
		local SplitLine = GetSplitDataLine(ThisLine)
		case SplitLine.LineLabel of
		(
			"L": CameraKeyframe.CameraLocation    = GetLocation3D(SplitLine.LineValue)
			"R": CameraKeyframe.CameraRotation    = GetRotationFromQuat SplitLine.LineValue EQuatType_Camera
			"F": CameraKeyframe.CameraFieldOfView = SplitLine.LineValue as float
			"}": exit
		)
	)
	
	return CameraKeyframe
)

function GetBallKeyframe ImportedFile =
(
	local BallKeyframe = StructBallKeyframe()
	
	while not eof ImportedFile do
	(
		local ThisLine = ReadLine ImportedFile
		if ThisLine.count == 0 do exit
		
		local SplitLine = GetSplitDataLine(ThisLine)
		case SplitLine.LineLabel of
		(
			"L": BallKeyframe.BallLocation = GetLocation3D(SplitLine.LineValue)
			"R": BallKeyframe.BallRotation = GetRotationFromQuat SplitLine.LineValue EQuatType_Ball
			"}": exit
		)
	)
	
	return BallKeyframe
)

function GetWheelKeyframe ImportedFile = 
(
	local WheelKeyframe = StructWheelKeyframe()
	
	-- Pull the wheel index from the first line
	local WheelIndexLine = ReadLine ImportedFile
	local WheelIndexSplit = GetSplitDataLine(WheelIndexLine)
	if WheelIndexSplit.LineLabel == "]" then
	(
		-- The end of the array has been reached
		return undefined
	)
	else
	(
		WheelKeyframe.WheelIndex = WheelIndexSplit.LineLabel as integer
	)
	
	-- Parse the wheel data
	while not eof ImportedFile do
	(
		local ThisLine = ReadLine ImportedFile
		if ThisLine.count == 0 do exit
		
		local SplitLine = GetSplitDataLine(ThisLine)
		case SplitLine.LineLabel of
		(
			"SA": WheelKeyframe.SteerAmount        = SplitLine.LineValue as float
			"SD": WheelKeyframe.SuspensionDistance = SplitLine.LineValue as float
			"SS": WheelKeyframe.SpinSpeed          = SplitLine.LineValue as float
			"}": exit
		)
	)
	
	return WheelKeyframe
)

function GetWheelKeyframes ImportedFile = 
(
	local WheelKeyframes = #()
	
	while true do
	(
		local ThisWheel = GetWheelKeyframe(ImportedFile)
		if ThisWheel == undefined then
		(
			exit
		)
		else
		(
			append WheelKeyframes ThisWheel
		)
	)
	
	return WheelKeyframes
)

function GetBoostBool BoostString = 
(
	-- Maxscript doesn't seem to have an "as boolean" conversion
	local BoostAsInt = BoostString as integer
	
	if BoostAsInt == 1 do
	(
		return true
	)
	
	return false
)

function GetCarKeyframe ImportedFile = 
(	
	local CarKeyframe = StructCarKeyframe()
	
	-- Pull the car seen index from the first line
	local CarIndexLine = ReadLine ImportedFile
	local CarIndexSplit = GetSplitDataLine(CarIndexLine)
	if CarIndexSplit.LineLabel == "}" then
	(
		-- The end of the array has been reached
		return undefined
	)
	else
	(
		CarKeyframe.CarSeenIndex = CarIndexSplit.LineLabel as integer
	)
	
	-- Parse the car data
	while not eof ImportedFile do
	(
		local ThisLine = ReadLine ImportedFile
		if ThisLine.count == 0 do exit
		
		local SplitLine = GetSplitDataLine(ThisLine)
		case SplitLine.LineLabel of
		(
			"L": CarKeyframe.CarLocation    = GetLocation3D(SplitLine.LineValue)
			"R": CarKeyframe.CarRotation    = GetRotationFromQuat SplitLine.LineValue EQuatType_Car
			"B": CarKeyframe.bIsBoosting    = GetBoostBool(SplitLine.LineValue)
			"W": CarKeyframe.WheelKeyframes = GetWheelKeyframes(ImportedFile)
			"}": exit
		)
	)
	
	return CarKeyframe
)

function GetCarsKeyframes ImportedFile = 
(
	local CarKeyframes = #()
	
	while true do
	(
		local ThisCar = GetCarKeyframe(ImportedFile)
		if ThisCar == undefined then
		(
			exit
		)
		else
		(
			append CarKeyframes ThisCar
		)
	)
	
	return CarKeyframes
)

-- MAIN FUNCTION DEFINITION --
function GetKeyframe ImportedFile = 
(
	-- Check if the filestream is already finished
	local bIsFileFinished = eof ImportedFile
	if bIsFileFinished do
	(
		format "GetKeyframe returned undefined - File is finished\n"
		return undefined
	)
	
	-- Check if the first line of the keyframe is empty. If it is, that's the last line of the file
	-- Don't really need to do anything with the first line as it is just the number of the keyframe
	local FirstLine = ReadLine ImportedFile
	if FirstLine.count == 0 do
	(
		format "GetKeyframe returned undefined - First line is empty\n"
		return undefined
	)
	
	-- Both checks above passed. Extract data from keyframe
	local KeyframeData = StructKeyframeData()
	while not eof ImportedFile do
	(
		local ThisLine = ReadLine ImportedFile
		if ThisLine.count == 0 do exit
		
		local SplitLine = GetSplitDataLine(ThisLine)
		case SplitLine.LineLabel of
		(
			"T":  KeyframeData.TimeKeyframe   = GetTimeKeyframe(ImportedFile)
			"CM": KeyframeData.CameraKeyframe = GetCameraKeyframe(ImportedFile)
			"B":  KeyframeData.BallKeyframe   = GetBallKeyframe(ImportedFile)
			"CR": KeyframeData.CarKeyframes   = GetCarsKeyframes(ImportedFile)
			"}":  exit
		)
	)
	
	return KeyframeData
)
