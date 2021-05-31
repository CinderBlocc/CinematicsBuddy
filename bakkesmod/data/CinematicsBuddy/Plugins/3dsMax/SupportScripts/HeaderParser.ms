-- HeaderParser reads through the whole file header and extracts necessary data.

-- Import UtilityFunctions script so its functions can be called
FileIn(CBSupportScripts + "UtilityFunctions.ms")


-- STRUCT DEFINITIONS --
struct StructFileMetadata
(
	FileName,
	FilePath
)

struct StructRecordingMetadata
(
	PluginVersion = "",
	CameraName = "",
	FPS = -1.0,
	Frames = -1,
	Duration = -1.0
)

struct StructReplayMetadata
(
	ReplayName = "NULL",
	ID = "NULL",
	Date = "NULL",
	FPS = 0,
	Frames = 0
)

struct StructCarSeen
(
	CarIndex = -1,
	PlayerID = "NO ID",
	BodyID = -1,
	FrontWheelRadius = -1.0,
	BackWheelRadius = -1.0
)

struct StructHeaderData
(
	FileMetadata = StructFileMetadata(),
	RecordingMetadata = StructRecordingMetadata(),
	ReplayMetadata = StructReplayMetadata(),
	CarsSeen = #()
)


-- UTILITY FUNCTION DEFINITIONS --
function DoesSectionExist ImportedFile SectionName = 
(
	local StartingLocation = FilePos ImportedFile
	local HeaderLine = ReadLine ImportedFile
	local TrimmedLine = TrimLeft HeaderLine
	
	-- If one section is missed, the blank space between each section can throw everything off
	-- Iterate until a non-blank line has been found
	if TrimmedLine == "" do
	(
		return DoesSectionExist ImportedFile SectionName
	)
	
	local bDoesSectionExist = MatchPattern TrimmedLine pattern:SectionName
	
	if bDoesSectionExist == false do
	(
		Seek ImportedFile StartingLocation
		return false
	)
	
	return true
)


-- SUPPORT FUNCTION DEFINITIONS --
function GetFileMetadata ChosenFile = 
(
	local FileMetadata = StructFileMetadata()
	
	-- Split file path by its folder names
	local ChosenFileString = ChosenFile as string
	local ChosenFileElements = FilterString ChosenFileString "\\"
	
	-- Compile the folders into a format for the textbox
	FileMetadata.FilePath = ""
	local FolderNumber = 1
	while FolderNumber < ChosenFileElements.count do
	(
		-- Add a new line between each entry
		if FolderNumber > 1 do
		(
			FileMetadata.FilePath += "\n"
		)
		
		-- Append the current directory to the file path and move to the next folder
		FileMetadata.FilePath += ChosenFileElements[FolderNumber]
		FolderNumber += 1
	)
	
	-- Store the file name
	FileMetadata.FileName = ChosenFileElements[FolderNumber]	
	
	return FileMetadata
)

function GetRecordingMetadata ImportedFile =
(
	local RecordingMetadata = StructRecordingMetadata()
	
	-- Skip "RECORDING METADATA" header
	if (DoesSectionExist ImportedFile "*RECORDING METADATA*") == false do
	(
		format "Could not find RECORDING METADATA section\n"
		return ReplayMetadata
	)
	
	while not eof ImportedFile do
	(
		local ThisLine = ReadLine ImportedFile
		if ThisLine.count == 0 do exit
		
		local SplitLine = GetSplitDataLine(ThisLine)
		case SplitLine.LineLabel of
		(
			"Version":     RecordingMetadata.PluginVersion = SplitLine.LineValue
			"Camera":      RecordingMetadata.CameraName    = SplitLine.LineValue
			"Average FPS": RecordingMetadata.FPS           = SplitLine.LineValue as float
			"Frames":      RecordingMetadata.Frames        = SplitLine.LineValue as integer
			"Duration":    RecordingMetadata.Duration      = SplitLine.LineValue as float
		)
	)
	
	return RecordingMetadata
)

function GetReplayMetadata ImportedFile =
(
	local ReplayMetadata = StructReplayMetadata()
	
	-- Skip "REPLAY METADATA" header
	if (DoesSectionExist ImportedFile "*REPLAY METADATA*") == false do
	(
		format "Could not find REPLAY METADATA section\n"
		return ReplayMetadata
	)
	
	while not eof ImportedFile do
	(
		local ThisLine = ReadLine ImportedFile
		if ThisLine.count == 0 do exit
		
		local SplitLine = GetSplitDataLine(ThisLine)
		case SplitLine.LineLabel of
		(
			"Name":   ReplayMetadata.ReplayName = SplitLine.LineValue
			"ID":     ReplayMetadata.ID         = SplitLine.LineValue
			"Date":   ReplayMetadata.Date       = SplitLine.LineValue
			"FPS":    ReplayMetadata.FPS        = SplitLine.LineValue as float
			"Frames": ReplayMetadata.Frames     = SplitLine.LineValue as integer
		)
	)
	
	return ReplayMetadata
)

function GetCarSeen ImportedFile = 
(
	local CarSeen = StructCarSeen()
	
	-- Get the CarsSeen index for this car. Return if it is past the last car in the list
	local IndexLine = ReadLine ImportedFile
	local bIsEndOfList = MatchPattern IndexLine pattern:"*}*"
	if bIsEndOfList then
	(
		return undefined
	)
	else
	(
		-- Get the index of this car from the array of CarsSeen (starting index 0)
		local SplitIndexLine = GetSplitDataLine(IndexLine)
		CarSeen.CarIndex = SplitIndexLine.LineLabel as integer
	)
	
	-- Get the other data for this car
	while not eof ImportedFile do
	(
		local ThisLine = ReadLine ImportedFile
		if ThisLine.count == 0 do exit
		
		local SplitLine = GetSplitDataLine(ThisLine)
		case SplitLine.LineLabel of
		(
			"ID":                 CarSeen.PlayerID         = SplitLine.LineValue
			"Body":               CarSeen.BodyID           = SplitLine.LineValue as integer
			"Front Wheel Radius": CarSeen.FrontWheelRadius = SplitLine.LineValue as float
			"Back Wheel Radius":  CarSeen.BackWheelRadius  = SplitLine.LineValue as float
			"}": exit
		)
	)
	
	return CarSeen
)

function GetCarsSeen ImportedFile =
(
	local CarsSeen = #()
	
	-- Skip "CARS SEEN" header and opening brace
	if (DoesSectionExist ImportedFile "*CARS SEEN*") == false do
	(
		format "Could not find CARS SEEN section\n"
		return CarsSeen
	)
	ReadLine ImportedFile
	
	while true do
	(
		local CarSeen = GetCarSeen(ImportedFile)
		if CarSeen == undefined do exit
		append CarsSeen CarSeen
	)
	
	return CarsSeen
)


-- MAIN FUNCTION DEFINITION --
function GetHeaderData ImportedFile ChosenFile = 
(
	local HeaderData = StructHeaderData()
	HeaderData.FileMetadata = GetFileMetadata(ChosenFile)
	HeaderData.RecordingMetadata = GetRecordingMetadata(ImportedFile)
	HeaderData.ReplayMetadata = GetReplayMetadata(ImportedFile)
	HeaderData.CarsSeen = GetCarsSeen(ImportedFile)
	
	return HeaderData
)
