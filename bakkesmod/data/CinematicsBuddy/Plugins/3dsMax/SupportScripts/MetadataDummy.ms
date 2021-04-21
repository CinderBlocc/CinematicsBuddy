-- MetadataDummy stores all information necessary for CinematicsBuddy to function.

function CreateMetadataDummy HeaderData =
(	
	-- Create new dummy object
	MetadataDummy = Dummy name:"MetadataDummy" pos:[0,0,0]
	
	-- Add modifier to hold replay metadata
	AddModifier MetadataDummy (EmptyModifier())
	local TheModifier = MetadataDummy.modifiers[1]
	TheModifier.name = "Metadata"
	MetadataModifier = attributes Metadata
	(
		-- "About" button to describe MetadataDummy's purpose
		rollout ro_description "Description"
		(
			button ButtonDescription "About MetadataDummy" width:150
			
			on ButtonDescription pressed do
			(
				local DescriptionText = "METADATA DUMMY\n"
				DescriptionText += "\n"
				DescriptionText += "This object's purpose is to store information about the scene elements related to Cinematics Buddy.\n"
				DescriptionText += "The information stored in these fields was read from the imported file and should not be edited.\n"
				DescriptionText += "That is why all of the fields are disabled.\n"
				DescriptionText += "\n"
				DescriptionText += "-- DO NOT DELETE THIS OBJECT --\n"
				DescriptionText += "\n"
				DescriptionText += "This object is important for some aspects of the Cinematics Buddy script. If it is deleted, some functionality will break."
				
				MessageBox DescriptionText
			)
		)
		
		-- File metadata
		parameters fileparams rollout:ro_file
		(
			FileName type:#string ui:TextboxFileName
			FilePath type:#string ui:TextboxFilePath
		)
		rollout ro_file "Imported File Metadata"
		(
			edittext TextboxFileName "Name " pos:[5,5]  width:152 readonly:true labelontop:true
			edittext TextboxFilePath "Path"  pos:[5,45] width:152 height:100 readonly:true labelontop:true
		)
		
		-- Keyframe metadata
		parameters keyframeparams rollout:ro_keyframes
		(
			ReplayCurrentFrame type:#integer ui:SpinnerReplayCurrentFrame
			ReplayStartFrame   type:#integer ui:SpinnerReplayStartFrame
			ReplayEndFrame     type:#integer ui:SpinnerReplayEndFrame
		)
		rollout ro_keyframes "Keyframe Metadata"
		(
			spinner  SpinnerReplayCurrentFrame "Current Frame:   " pos:[ 2, 5]  range:[0,1000000,0] type:#integer width:155 enabled:false
			spinner  SpinnerReplayStartFrame   "Start Frame:  "    pos:[-12,27] range:[0,1000000,0] type:#integer width:169 enabled:false
			spinner  SpinnerReplayEndFrame     "End Frame:    "    pos:[-12,50] range:[0,1000000,0] type:#integer width:169 enabled:false
		)
		
		-- Replay metadata
		parameters replayparams rollout:ro_replay
		(
			ReplayName         type:#string  ui:TextboxReplayName
			ReplayID           type:#string  ui:TextboxReplayID
			ReplayDate         type:#string  ui:TextboxReplayDate
			ReplayFPS          type:#float   ui:SpinnerReplayFPS
			ReplayFrames       type:#integer ui:SpinnerReplayFrames
		)
		rollout ro_replay "Replay Metadata"
		(
			edittext TextboxReplayName         "Name: "            pos:[5,5]  width:152 readonly:true
			edittext TextboxReplayID           "ID:      "         pos:[5,27] width:152 readonly:true
			edittext TextboxReplayDate         "Date:  "           pos:[5,49] width:152 readonly:true
			spinner  SpinnerReplayFPS          "FPS:     "         pos:[-18,71]  range:[0,10000,0]   type:#float   width:175 enabled:false
			spinner  SpinnerReplayFrames       "Replay Frames:  "  pos:[ 2, 93]  range:[0,1000000,0] type:#integer width:155 enabled:false
		)
		
		-- Cars metadata
		parameters carparams rollout:ro_cars
		(
			CarNames             type:#string ui:TextBoxCarName
			CarBodyIDs           type:#string ui:TextboxCarBodyID
			CarBackWheelRadii    type:#string ui:TextboxBackWheelRadius
			CarFrontWheelRadii   type:#string ui:TextboxFrontWheelRadius
		)
		rollout ro_cars "Car Metadata"
		(
			edittext TextboxCarName          "Name"               width:152 height:100 pos:[5,2]   readonly:true labelontop:true
			edittext TextboxCarBodyID        "Body ID"            width:152 height:100 pos:[5,125] readonly:true labelontop:true
			edittext TextboxBackWheelRadius  "Back Wheel Radius"  width:152 height:100 pos:[5,250] readonly:true labelontop:true
			edittext TextboxFrontWheelRadius "Front Wheel Radius" width:152 height:100 pos:[5,375] readonly:true labelontop:true
		)
		
		-- Arena and ball metadata
		parameters otherassets rollout:ro_otherassets
		(
			OtherArenaName type:#string ui:TextboxArenaName
			OtherBallName  type:#string ui:TextboxBallName
		)
		rollout ro_otherassets "Other Assets"
		(
			edittext TextboxArenaName "Arena:"    pos:[5,5]  width:152 readonly:true
			edittext TextboxBallName  "Ball:    " pos:[5,27] width:152 readonly:true
		)
	)
	CustAttributes.Add TheModifier MetadataModifier
	
	-- Assign FileMetadata information
	TheModifier.FileName = HeaderData.FileMetadata.FileName
	TheModifier.FilePath = HeaderData.FileMetadata.FilePath
	
	-- Assign ReplayMetadata information
	TheModifier.ReplayName   = HeaderData.ReplayMetadata.ReplayName
	TheModifier.ReplayID     = HeaderData.ReplayMetadata.ID
	TheModifier.ReplayDate   = HeaderData.ReplayMetadata.Date
	TheModifier.ReplayFPS    = HeaderData.ReplayMetadata.FPS
	TheModifier.ReplayFrames = HeaderData.ReplayMetadata.Frames
	
	-- Compile strings to assign them in car metadata
	local CarNamesString = ""
	local CarBodyIDsString = ""
	local CarBackWheelRadiiString = ""
	local CarFrontWheelRadiiString = ""
	local bFirstCar = true
	for TheCar in HeaderData.CarsSeen do
	(
		-- Add a new line between each entry (after the first entry)
		if bFirstCar == false do
		(
			CarNamesString           += "\n"
			CarBodyIDsString         += "\n"
			CarBackWheelRadiiString  += "\n"
			CarFrontWheelRadiiString += "\n"
		)
		bFirstCar = false
		
		-- Add this car's info to the respective textbox
		CarNamesString           += TheCar.PlayerID
		CarBodyIDsString         += TheCar.BodyID as string
		CarBackWheelRadiiString  += TheCar.BackWheelRadius as string
		CarFrontWheelRadiiString += TheCar.FrontWheelRadius as string
	)
	
	-- Put strings in their respective textboxes
	TheModifier.CarNames             = CarNamesString
	TheModifier.CarBodyIDs           = CarBodyIDsString
	TheModifier.CarBackWheelRadii    = CarBackWheelRadiiString
	TheModifier.CarFrontWheelRadii   = CarFrontWheelRadiiString
	
	-- Ensure MetadataDummy is hidden
	deselect MetadataDummy
	freeze MetadataDummy
	hide MetadataDummy
	
	return MetadataDummy
)
	