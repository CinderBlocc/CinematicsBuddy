-- CinematicsBuddyMaxscript does the following:
	-- Imports a CinematicsBuddy animation file and rebuilds the scene in the viewport
	-- Exports an animated camera back to Rocket League
	-- Exports rebuilt scene to an animated FBX file to be transferred to other 3D software

-- Information about the script
global CBScriptVersion = "1.0"

-- Get relative paths
global CBScriptLocation = PathConfig.RemovePathLeaf (GetSourceFileName()) + "\\"
global CBSupportScripts = CBScriptLocation + "SupportScripts\\"
global CBAssetsLocation = CBScriptLocation + "..\\CinematicsBuddyAssets\\"
global CBImageAssets = CBAssetsLocation + "Images\\"
global CBModelAssets = CBAssetsLocation + "Models\\"

-- Include and evaluate support files
FileIn(CBSupportScripts + "MetadataDummy.ms")
FileIn(CBSupportScripts + "HeaderParser.ms")
FileIn(CBSupportScripts + "SceneObjectCreator.ms")
FileIn(CBSupportScripts + "Keyframes\\KeyframeManager.ms")

-- Close any existing windows
try(DestroyDialog CinematicsBuddyUI)
catch()

-- MAIN UI CONTAINER --
rollout CinematicsBuddyUI "" width:235 height:168 -- 315 when all rollouts are added
(	
	-- Add banner image
	local BannerImageBitmap = OpenBitMap(CBImageAssets + "CinematicsBuddyBanner.jpg")
	imgtag BannerImage bitmap:BannerImageBitmap pos:[5,5] width:225 height:30.7 opacity:1.0
	
	-- Create a subrollout that contains all the other subrollouts
	subrollout RolloutContainer "Rollout Container" pos:[0,35] width:239 height:108 -- 255 when all rollouts are added
	
	-- Add colored label showing script version
	local VersionText = "Version: " + CBScriptVersion
	hyperlink VersionLabel VersionText color:[125,200,175] enabled:false align:#center
)

-- File importing and scene creation --
struct StructImportTypes
(
	bImportCamera,
	bImportBall,
	bImportCars
)
rollout Initialize "Import Animation File"
(	
	-- Choose which items should be included in the import. If a scene already exists, only allow camera importing
	groupbox GroupboxImportTypes "" pos:[3,-3] width:71 height:76
	label LabelImportTypes "Import" pos:[20,5] enabled:false
	checkbox CheckboxCamera "Camera" checked:true pos:[8,20] enabled:false tooltip:"Test tooltip"
	checkbox CheckboxBall "Ball" checked:true pos:[8,37] enabled:false
	checkbox CheckboxCars "Cars" checked:true pos:[8,54] enabled:false
	
	-- Buttons to choose file and confirm or cancel import
	local TooltipFileImport = "Select a Cinematics Buddy animation file that was exported from Rocket League"
	local TooltipConfirm = "Clicking this button will parse the chosen file and import the objects selected by the Import checkboxes. It will also set the FPS to 60 and set the system and display units to centimeters."
	button ButtonFileImport "Choose File" pos:[78,3] width:71 height:28 tooltip:TooltipFileImport
	button ButtonConfirmImport "Confirm" pos:[152,3] width:71 height:28 enabled:false tooltip:TooltipConfirm
	
	-- Give the camera a name. It will be automatically pulled from the file when it is chosen, but the user can override it here
	groupbox GroupboxCameraName "" pos:[78,28] width:145 height:45
	label LabelCameraName "Camera Name" pos:[120,35] enabled:false
	edittext TextboxCameraName "" pos:[80,51] width:137 enabled:false
	
	-- FUNCTIONS --
	function DisableCheckboxes =
	(
		CheckboxBall.checked = false
		CheckboxCars.checked = false
		CheckboxBall.enabled = false
		CheckboxCars.enabled = false
	)
	
	-- LOCAL STORAGE --
	local ImportedFile
	local HeaderData
	
	-- BUTTON METHODS --
	on ButtonFileImport pressed do
	(
		local ChosenFile = GetOpenFileName caption:"Select file to import"
		if ChosenFile != undefined do
		(
			-- Open file and read header lines
			ImportedFile = OpenFile ChosenFile
			HeaderData = GetHeaderData ImportedFile ChosenFile
			
			if HeaderData != undefined do
			(
				--Assign camera name to textbox so user can edit it if they want
				TextboxCameraName.text = HeaderData.RecordingMetadata.CameraName
				
				-- Enable the rest of the UI
				LabelImportTypes.enabled = true
				CheckboxCamera.enabled = true
				CheckboxBall.enabled = true
				CheckboxCars.enabled = true
				ButtonConfirmImport.enabled = true
				LabelCameraName.enabled = true
				TextboxCameraName.enabled = true
				
				if $MetadataDummy != undefined do
				(
					DisableCheckboxes()
				)
			)
		)
	)
	
	on ButtonConfirmImport pressed do
	(
		undo "CinematicsBuddy Import" on
		(
			-- Configure unit and timeline settings
			FrameRate = 60
			TimeDisplayMode = #Frames
			Units.DisplayType = #Metric
			Units.SystemType = #Centimeters
			
			-- Find the "BEGIN ANIMATION" header
			while not eof ImportedFile do
			(
				local ThisLine = ReadLine ImportedFile
				local bFoundHeader = MatchPattern ThisLine pattern:"*BEGIN ANIMATION*"
				if bFoundHeader == true do exit
			)
			
			-- Gather which objects should be imported
			local ImportTypes = StructImportTypes()
			ImportTypes.bImportCamera = CheckboxCamera.checked
			ImportTypes.bImportBall   = CheckboxBall.checked
			ImportTypes.bImportCars   = CheckboxCars.checked
			
			-- Apply animations
			if $MetadataDummy == undefined then
			(
				-- MetadataDummy does not exist yet, so this is the first import for this scene. Import all checked objects --
				
				-- Create MetadataDummy to store scene information
				local MetadataDummy = CreateMetadataDummy(HeaderData)
				
				-- Create scene objects
				local SceneObjects = CreateSceneObjects ImportTypes MetadataDummy TextboxCameraName.text
				
				-- Loop through all keyframes and apply them
				local NumKeyframesFound = 0
				local MaxAnimationRange = 0
				while ApplyNextKeyframe ImportedFile SceneObjects ImportTypes &NumKeyframesFound &MaxAnimationRange do ()
				
				-- Set the animation range to the max keyframe
				format "Keyframes Found: %\n" NumKeyframesFound
				format "Animation Duration: %\n" MaxAnimationRange
				local MaxAnimationRangeFrames = MaxAnimationRange * 60
				AnimationRange = (interval 0 MaxAnimationRangeFrames)
			)
			else
			(
				-- MetadataDummy already exists, so this is not the first import for this scene. Import only the camera if it is checked --
				
				if ImportTypes.bImportCamera == true do
				(
					local SceneObjects = StructNewCamera()
					SceneObjects.MetadataDummy = $MetadataDummy
					SceneObjects.CameraObject = CreateCamera(TextboxCameraName.text)
					
					-- Find the sync point and then apply keyframes from that point forward
					local SyncData = FindSyncData ImportedFile SceneObjects.MetadataDummy
					if SyncData.FirstValidKeyframe != undefined then
					(
						-- Apply the first keyframe
						ApplyCameraOnlyKeyframe SyncData.FirstValidKeyframe SceneObjects SyncData		
						
						-- Loop through all remaining valid keyframes and apply only the camera information
						while ApplyNextCameraKeyframe ImportedFile SceneObjects SyncData do ()
						
						-- Maxscript automatically applies a keyframe at time 0 which is undesired if camera animation starts late
						if SyncData.bStartedLate == true do
						(
							local TheCamera = SceneObjects.CameraObject
							DeleteKey TheCamera.Position.X_Position.Controller 1
							DeleteKey TheCamera.Position.Y_Position.Controller 1
							DeleteKey TheCamera.Position.Z_Position.Controller 1
							DeleteKey TheCamera.Rotation.X_Rotation.Controller 1
							DeleteKey TheCamera.Rotation.Y_Rotation.Controller 1
							DeleteKey TheCamera.Rotation.Z_Rotation.Controller 1
							DeleteKey TheCamera.FOV.Controller 1
						)
					)
					else
					(
						MessageBox("Cannot sync camera. No keyframes found within MetadataDummy's replay animation range.")
					)
				)
			)
		)
		
		if $MetadataDummy != undefined do
		(
			DisableCheckboxes()
		)
		
		ButtonConfirmImport.enabled = false
		Close ImportedFile
	)
)

/* @TODO: Implement this section at a later date
-- Export selected camera's animation to Rocket League --
rollout ExportCamera "Export Camera To Rocket League"
(
	-- @TODO: Keep the export button disabled unless there is text in the textbox and a SINGLE camera is selected
		-- Check every time the textbox value changes and every time a selection changes?
		-- If multiple objects selected, grey out box
		-- This seems helpful: https://forums.cgsociety.org/t/maxscript-detecting-selectionset-change/663841/3
	-- @TODO: Bake camera animation down if it has any constraints
	
	local TooltipExportCamera = "File will export to /bakkesmod/data/CinematicsBuddy/AnimationImports/"
	label LabelInstructions1 "1. Select a camera" pos:[3,1]
	label LabelInstructions2 "2. Provide a file name" pos:[3,14]
	edittext TextboxFileName "" pos:[0,30] width:148
	button ButtonExportCamera "3. Export" pos:[152,3] width:70 height:45 enabled:false tooltip:TooltipExportCamera
	
	on ButtonExportCamera pressed do
	(
		
	)
)
*/

/* @TODO: Implement this section at a later date
-- Export all mesh and camera animations to an external software --
rollout ExportAll "Export All To Other 3D Program"
(
	-- @TODO: When attempting to export FBX to other package, parenting might not export correctly.
		-- Create a clone of the car mesh, then bake all of the position/rotation data onto the mesh.
		-- Add all the cloned cars to the selection, along with the field, ball, and camera. Export selected to FBX.
			-- Let the user choose the FBX settings? If so, make sure the dialog pops up
		-- Doesn't the FBX prompt give an option to bake animations? Maybe making a clone won't be necessary
			-- This seemed to work when manually going through the "export selected" process, so maybe it would be just that easy programmatically
	
	local TooltipChooseDirectory = "Opens a file explorer for you to choose the output directory. The file will be saved as FBX. The cars, ball, and all cameras will be exported.\n\nNOTE 1: This only exports CinematicsBuddy scene assets, not all elements in the scene.\n\nNOTE 2: Generally this should only be used just after importing the scene so that the raw CinematicsBuddy content can be exported. Behavior is undefined if you edit the scene before exporting."
	button ButtonChooseDirectory "Export" pos:[152,3] width:70 height:35 tooltip:TooltipChooseDirectory
	label LabelUpAxis "Up Axis" pos:[58,2]
	dropdownlist DropdownUpAxis "" items:#("Y-Up", "Z-Up") pos:[3,17] width:145
	
	on ButtonChooseDirectory pressed do
	(
		
	)
)
*/

-- Create the window and add the subrollouts
CreateDialog  CinematicsBuddyUI style: #(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox)
AddSubrollout CinematicsBuddyUI.RolloutContainer Initialize
--AddSubrollout CinematicsBuddyUI.RolloutContainer ExportCamera
--AddSubrollout CinematicsBuddyUI.RolloutContainer ExportAll
