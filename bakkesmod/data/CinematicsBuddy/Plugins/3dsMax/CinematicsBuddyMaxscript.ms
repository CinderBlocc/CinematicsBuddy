try(destroyDialog CBMaxWrapper)
catch()
global frameRate = 60
--timeDisplayMode = #frameTicks


/*

	REMOVE ALL RIGGING FROM THIS SCRIPT
		- This way you could remove a lot of sketchy dependencies
		- Have all the data for a car (body location/rotation, and all suspension data) packed into one dummy object
			- Similar to metadatadummy, store everything (except body translation) in attribute sliders
			- Body translation would be directly tied to the translation of the dummy object

*/

/*

		IMPLEMENT OBJECT ORIENTED PROGRAMMING FEATURES
			- i.e. using a Stack to parse/match the parentheses and brackets in the JSON
		SPLIT INTO FILES AND USE EITHER fileIn() OR include() TO SIMPLIFY THE MAIN FILE
			- i.e. maybe put all the UI stuff into a different file? Hopefully that'll work
			- put additional files in a ./source/ folder in the same directory as this file for organization

*/


/*
	- DIRECT TO AE: Game_Extensions_for_Production\CinematicsBuddy\DirectToAE\README.txt for more information

	- Fix array setups so that you dont need to click reset to clear the list of cars
	
	- "Ignore" checkboxes are a bit unituitive at first glance. Change them to "Import" and checked by default
	
	- If length of time between first keyframe and current keyframe in the loop / fps >= 9999 stop import
		- if(keyframeTime/60 >= 9999) stop import
		- This can open up the buffer to whatever length they want
		
	- Add range specifier to AnimationImport along with the FPS specification
		- Let the user choose the range of frames on the timeline they want to use to export the camera back to the game
*/

/*
TO-DO
	- Set units to centimeters automatically


	- IMPLEMENT EXPORT FPS SO YOU DONT HAVE TO DO MANY CALCULATIONS FOR POSITION/ROTATION



	- Use specShortcut to keep car array stable

	- Avoid gimbal lock by assigning an "orientation" track after the animation track
		- https://forums.cgsociety.org/t/adjusting-camera-orientation-causes-weird-jumps-in-rotation/2051361

	- Add global frame/subframe offset to sync to original recording
		- This would change the timing of the animations for the ball, camera, and cars
		- Different from the camera sync offset. That is to properly line up the timestamps if a second camera is imported

	- "Ignore Camera" checkbox needs to function
	
	- Everything in camera list rollout needs to function
	
	- Fix gamma of UI banner. Maybe only in max 2016? (not bugged in 2017, 2018????, 2019)
		- https://forums.cgsociety.org/t/gamma-of-maxscript-bitmaps-in-max-2016-vs-max-2014/1702291
		- https://forums.cgsociety.org/t/imgtag-woes/1534090
	
	- Ion boost impulse should have 2 particle emission points, one at top of booster and one at bottom
		- per frame emit particle and use the two new points to create an additional polygon on a tapeworm

	- About/help dialog pops up when clicking banner
		- image should do something on hover, like add a dropshadow
		- Add a link to a short tutorial series on youtube covering the basics of the plugin's functions
		
	- Add camera to listbox
	
	- Test if you fixed stuttering at slower playback speeds in the replay viewer
	
	- Make sure replay metadata gets the full length of replay names instead of missing parts due to spaces
*/
global importCar

global gameState

global ball
global car = #()
global newCamera
global numCars
global carHelpers = #() -- [carNum][HelperNum: Core, Axels 1-4, Spring 1-4, Cup 1-4, Wheels 1-4       TOTAL: 17 elements]
global carParts = #() -- [carNum][PartNum: Body, Axels 1-4, Spring 1-4, Cup 1-4, Wheels 1-4. Brakepads 1-4        TOTAL: 21 elements]
global carBoosts = #() -- [carNum][boostPortNum]

global importedFile
global rawLineRead
global filteredLine
global subframeScale

global frame

global useCars = true
global useBall = true




global msVersion	= "0.9.7"
global versionMismatch = false





--BEGIN ROLLOUT
rollout CBMaxWrapper "" width:235 height:500
(
	GroupBox imgBox pos:[2,0] width:231 height:62.5
	local imgBM = openBitMap("F:\_YouTube\04_Extra_Assets\Game_Extensions_for_Production\CinematicsBuddy\CinematicsBuddyMaxscriptBanner2.jpg")
	imgTag imgCinematicsBuddy bitmap:imgBM pos:[5,9] width:225 height:51.12
	hyperlink hylinkVersionNum "Version" pos:[83,62] color:[125,200,175] enabled:false
	label lblVersionNum msVersion pos:[122,62]
	subrollout allRollouts "All Rollouts" pos:[0,80] width:239 height:425
)

rollout initialize "Initialize"
(
	button btnCameraImport "Import File" pos:[3,3] width:71 height:28
	button btnConfirmImport "Confirm" pos:[77,3] width:71 height:28 enabled:false
	button btnCancelImport "Cancel" pos:[151,3] width:71 height:28 enabled:false
	spinner spnFpsChange "FPS:" range:[0,999,0] pos:[5,35] width:50 tooltip:"This reads the average FPS from the recording. It is sometimes wrong so adjust accordingly." type:#integer align:#left
	spinner spnFrameCount "Frames:" range:[0,999999,0] pos:[5,54] width:80 type:#integer align:#left
	label lblNumCars "#" pos:[89,35]
	label lblCars "CARS" pos:[101,35]
	label lblCameraNameLabel "Camera:" pos:[5,76]
	edittext textCameraName "" pos:[44,74] width:105
	label lblIgnore "Ignore:" pos:[115,50]
	groupbox gboxIngores "" pos:[155,32] width:66 height:60
	checkbox cboxCamera "Camera" pos:[160,40] width: 60
	checkbox cboxBall "Ball" pos:[160,57]
	checkbox cboxCars "Cars" pos:[160,74]
	
	
	on btnCameraImport pressed do
	(
		filePathName = getOpenFileName caption:"Select file to import"
		if filePathName != undefined do
		(
			importedFile = openFile filePathName
			rawLineRead = readline importedFile
			filteredLine = filterString rawLineRead " ,	"

			cppVersion = filteredLine[2]
			if cppVersion != msVersion do
			(			
				versionMismatch = true
				close importedFile
				messageBox ("The file version is not compatible.\nUse version: " +  cppVersion) beep:true
			)
			
			if cppVersion == msVersion do
			(
				rawLineRead = readline importedFile -- get GameState								USE LATER TO DETERMINE IF CAMERA CAN BE SENT BACK TO REPLAY
				filteredLine = filterString rawLineRead " ,	"
				gameState = filteredLine[2]
				rawLineRead = readline importedFile
				filteredLine = filterString rawLineRead " ,	"
				textCameraName.text = filteredLine[2] -- get camera name
				rawLineRead = readline importedFile
				filteredLine = filterString rawLineRead " ,	"
				spnFpsChange.value = filteredLine[2] as float -- get in game fps
				rawLineRead = readline importedFile
				filteredLine = filterString rawLineRead " ,	"
				spnFrameCount.value = filteredLine[2] as float -- get recorded frames
				rawLineRead = readline importedFile
				filteredLine = filterString rawLineRead " ,	"
				lblNumCars.text = filteredLine[2]
				numCars = filteredLine[2] as integer -- get number of cars
				
				btnCameraImport.enabled = false
				btnConfirmImport.enabled = true
				btnCancelImport.enabled = true
			)
		)
	)
	
	on btnConfirmImport pressed do
	(
		btnCameraImport.enabled = true
		btnConfirmImport.enabled = false
		btnCancelImport.enabled = false
		
		if cboxBall.checked == true do useBall = false
		if cboxCars.checked == true do useBall = false
		
		FPSspinner = spnFpsChange.value as float
		subframeScale = 60/FPSspinner
		animTopRange = subframeScale * spnFrameCount.value
		animationRange = (interval 0 animTopRange) --this may need to adjust later to compensate for syncing new cameras. If the cameras have animation outside the range then change it, otherwise do nothing
		disableSceneRedraw
		
		metadataBool = true
		if metadataBool == true do --this is just to allow toggling of outlining for the metadata section
		(
			metadataDummy = Dummy name:"MetadataDummy" pos:[0,0,0]
			select metadataDummy
			attrHolder = EmptyModifier()
			attrHolder.name = "Metadata"
			addModifier metadataDummy (EmptyModifier())
			metadataDummy.modifiers[1].name = "Metadata"
			metadata = attributes dummymetadata
			(
				parameters params rollout:ro_dummymetadata
				(
					replayName type:#string ui:metaName
					replayID type:#string ui:metaID
					replayDate type:#string ui:metaDate
					replayFPS type:#integer ui:metaFPS
					replayFrames type:#integer ui:metaFrames
					replayCurrentFrame type:#integer ui:metaCurrentFrame
				)
				rollout ro_dummymetadata "Replay Metadata"
				(
					edittext metaName 		"Name: " pos:[5,5] width:152
					edittext metaID 			"ID:      " pos:[5,27] width: 152
					edittext metaDate 		"Date:  " pos:[5,49] width: 152
					spinner metaFPS 		"FPS:     " pos:[-18,71] range:[0,10000,0] type:#float width: 175
					spinner metaFrames 	"Replay Frames:  " pos:[2,93] range:[0,1000000,0] type:#integer width:155
					spinner metaCurrentFrame "Current frame: " pos:[-3,115] range:[0,1000000,0] type:#integer width:160
				)
			)
			custAttributes.add metadataDummy.modifiers[1] metadata
			rawLineRead = readline importedFile -- skip empty line
			rawLineRead = readline importedFile -- skip REPLAY METADATA line
			rawLineRead = readline importedFile
			filteredLine = filterString rawLineRead " ,	"
			/**/metadataDummy.modifiers[1].replayName = filteredLine[2] -- get replay name
			rawLineRead = readline importedFile
			filteredLine = filterString rawLineRead " ,	"
			/**/metadataDummy.modifiers[1].replayID = filteredLine[2] -- get replay ID
			rawLineRead = readline importedFile
			filteredLine = filterString rawLineRead " ,	"
			replayDateString = filteredLine[2]
			if gameState == "REPLAY" do (replayDateString += " " + filteredLine[3]) -- get both parts of replay date
			/**/metadataDummy.modifiers[1].replayDate = replayDateString
			rawLineRead = readline importedFile
			filteredLine = filterString rawLineRead " ,	"
			if filteredLine[2] == "NULL" then metadataDummy.modifiers[1].replayFPS = 0
			/**/else metadataDummy.modifiers[1].replayFPS = filteredLine[2] as float -- get replay fps
			rawLineRead = readline importedFile
			filteredLine = filterString rawLineRead " ,	"
			if filteredLine[2] == "NULL" then metadataDummy.modifiers[1].replayFrames = 0
			/**/else metadataDummy.modifiers[1].replayFrames = filteredLine[2] as integer -- get replay frames
			deselect metadataDummy
			freeze metadataDummy
			hide metadataDummy
		)

		ImportFile "F:\\_YouTube\\04_Extra_Assets\\3D_Models_and_Scenes\\Rocket_League_Models\\Ball.FBX" #noPrompt
		ball = $RL_BALL
		ball.scale = [1,1,1]

		ImportFile "F:\\_YouTube\\04_Extra_Assets\\3D_Models_and_Scenes\\Rocket_League_Models\\Field_Nicer.FBX" #noPrompt
		field = $RL_STADIUM_NICER
		field.scale = [1,1,1]

		--ImportFile "F:\\_YouTube\\04_Extra_Assets\\3D_Models_and_Scenes\\Rocket_League_Models\\Car_Octane_Clean.FBX" #noPrompt
		--newCar = $RL_OCTANE_CLEAN
		carHelpers = #()
		carParts = #()
		for i=1 to numCars do importCar i
		
		/*if numCars > 1 do
		(
			for i=1 to numCars do
			(
				car[i] = instance newCar
				car[i].scale = [1,1,1]
			)
		)
		if numCars == 1 do
		(
			car[1] = instance newCar
			car[1].scale = [1,1,1]
		)
		delete newCar*/
		
		newCamera = freecamera name:textCameraName.text
		set animate on
		
		rawLineRead = readline importedFile -- skip the empty line
		rawLineRead = readline importedFile -- skip the header line
		
		firstLine = true
		previousEuler = eulerangles 0 0 0
		currentEuler = eulerangles 0 0 0
		previousQuat = quat 0 0 0 0
		currentQuat = quat 0 0 0 0
		while not eof importedFile do 
		(
			rawLineRead = readline importedFile
			filteredLine = filterString rawLineRead " ,	"
			if filteredLine[1] == "END" then exit
			
			frame = filteredLine[1] as float*subframeScale
			--format "Frame: %\n" frame
			replayFrame = filteredLine[2] as integer
			camFOV = filteredLine[3] as float
			camPosX = filteredLine[4] as float
			camPosY = filteredLine[5] as float
			camPosZ = filteredLine[6] as float
			camQX = filteredLine[7] as float
			camQY = filteredLine[8] as float
			camQZ = filteredLine[9] as float
			camQW = filteredLine[10] as float
			
			ballPosX = filteredLine[11] as float
			ballPosY = filteredLine[12] as float
			ballPosZ = filteredLine[13] as float
			
			ballQX = filteredLine[14] as float
			ballQY = filteredLine[15] as float
			ballQZ = filteredLine[16] as float
			ballQW = filteredLine[17] as float
			
			at time frame
			(
				if gameState == "REPLAY" do metadataDummy.modifiers[1].replayCurrentFrame = replayFrame
				
				newCamera.rotation = quat -camQY -camQX -camQZ camQW
				
				/* THIS CODE CONSTRAINS THE ANIMATION WITHIN -180 to 180. NOT NECESSARY WHEN USING QUATERNIONS
				currentEuler = eulerAngles newCamera.rotation.x_rotation newCamera.rotation.y_rotation newCamera.rotation.z_rotation
				currentQuat = eulerToQuat currentEuler
				quatRatio = getEulerQuatAngleRatio previousQuat currentQuat previousEuler currentEuler
				
				previousEuler = currentEuler
				previousQuat = eulerToQuat previousEuler
				
				newCamera.rotation.x_rotation.controller.value = currentEuler.x
				newCamera.rotation.y_rotation.controller.value = currentEuler.y
				newCamera.rotation.z_rotation.controller.value = currentEuler.z
				EULER FILTER IMPLEMENTATION? http://web.archive.org/web/20170505034541/http://www.staff.city.ac.uk/~sbbh653/publications/euler.pdf
				*/
				
				newCamera.rotation.z_rotation.controller.value -= 90
				newCamera.rotation.x_rotation.controller.value += 90
				
				newCamera.fov = camFOV
				newCamera.pos = [camPosX, camPosY*-1, camPosZ]				
			)
			
			if cboxBall.checked == false do
			(
				localBallQuat = quat -ballQX ballQY -ballQZ ballQW
				at time frame ball.rotation = localBallQuat
				at time frame ball.transform *= (rotateZmatrix 30)
				at time frame ball.pos = [ballPosX, ballPosY*-1, ballPosZ]
			)
			if cboxCars.checked == false do
			(
				i = 18 --Whatever number qw is for the ball +1
				
				for j=1 to numCars do
				(
					--format "intended carSpecShortcut: %\n" filteredLine[i]
					--format "Spectator Shortcut: %\n" filteredLine[i]
					/*need to make this global*/carSpecShortcut = filteredLine[i] as integer
					i+=1
					isBoosting = filteredLine[i] as integer
					i+=1
					carPosX = filteredLine[i] as float
					i+=1
					carPosY = filteredLine[i] as float
					i+=1
					carPosZ = filteredLine[i] as float
					i+=1
					carQX = filteredLine[i] as float
					i+=1
					carQY = filteredLine[i] as float
					i+=1
					carQZ = filteredLine[i] as float
					i+=1
					carQW = filteredLine[i] as float
					i+=1
					
					local carWheelVariableIDFK
					for w=1 to 4 do
					(
						steerAmount = filteredLine[i] as float
						i+=1
						--wheelRadius = filteredLine[i] as float
						i+=1
						suspensionDistance = filteredLine[i] as float
						i+=1
						spinSpeed = filteredLine[i] as float
						i+=1
						at time frame in coordsys local carHelpers[j][w+13].rotation.z_rotation.controller.value = -steerAmount*57.2958 --rad to deg
						if (w==1 or w==3) then
						(
							--apply the inverse of this to the wheel helper's y axis to offset the angle of the wheels
							at time frame in coordsys local carHelpers[j][w+13].rotation.x_rotation.controller.value = suspensionDistance
							at time frame in coordsys local carHelpers[j][w+1].rotation.x_rotation.controller.value = -suspensionDistance
						)
						else
						(
							at time frame in coordsys local carHelpers[j][w+13].rotation.x_rotation.controller.value = -suspensionDistance
							at time frame in coordsys local carHelpers[j][w+1].rotation.x_rotation.controller.value = suspensionDistance
						)
						
						/*
						radians to degrees --> degrees/second
						need degrees to turn between frame timestamps --> frames/second
						degrees/second//frames/second --> degrees/second * second/frames
						degrees/frames
						FINAL: (radians*57.2958)/fpsValue
						*/
						wheelSpinAmount = (spinSpeed*57.2958)/FPSspinner
						--format "Raw spinSpeed: % -- wheelSpinAmount: %\n" spinSpeed wheelSpinAmount
						at time frame in coordsys local carParts[j][w+17].rotation.y_rotation.controller.value += wheelSpinAmount
					)
					
					localCarQuat = quat -carQX carQY -carQZ carQW
					at time frame carHelpers[j][1].rotation = localCarQuat
					at time frame carHelpers[j][1].pos = [carPosX, carPosY*-1, carPosZ]
					at time frame carHelpers[j][1].boostControlAttributes.isBoosting.controller.value = isBoosting
					j+=1
				)
				
				for j=1 to numCars do -- Link custom attributes to animation controllers
				(
					evt = carBoosts[j][1].getInitialActionList 1
					action = evt.getAction 1
					fsBoost = float_script()
					fsBoost.addTarget "isBoosting" carHelpers[j][1].boostControlAttributes.isBoosting.controller
					fsBoost.addTarget "boostRate" carHelpers[j][1].boostControlAttributes.boostRate.controller
					fsBoost.script = "boostRate * isBoosting"
					action.rate.controller = fsBoost
					
					fsSuspensionPitch = float_script()
					fsSuspensionPitch.addTarget "susMaxAmount" carHelpers[j][1].suspensionControlAttributes.suspensionMaxAmount.controller
					fsSuspensionPitch.addTarget "susPitch" carHelpers[j][1].suspensionControlAttributes.suspensionPitch.controller
					fsSuspensionPitch.script = "(susMaxAmount * susPitch)/57.2958"
					carParts[j][1].rotation.y_rotation.controller = fsSuspensionPitch
					
					fsSuspensionRoll = float_script()
					fsSuspensionRoll.addTarget "susMaxAmount" carHelpers[j][1].suspensionControlAttributes.suspensionMaxAmount.controller
					fsSuspensionRoll.addTarget "susRoll" carHelpers[j][1].suspensionControlAttributes.suspensionRoll.controller
					fsSuspensionRoll.script = "(susMaxAmount * susRoll)/57.2958"
					carParts[j][1].rotation.x_rotation.controller = fsSuspensionRoll
				)
				
			)
			firstLine = false
		)
		
		set animate off
		close importedFile
		enableSceneRedraw
		spnFpsChange.value = 0
		spnFrameCount.value = 0
		textCameraName.text = ""
		btnCameraImport.enabled = true
		btnConfirmImport.enabled = false
		btnCancelImport.enabled = false	
		cboxBall.checked = true
		cboxCars.checked = true
	)
	
	on btnCancelImport pressed do
	(
		close importedFile
		spnFpsChange.value = 0
		spnFrameCount.value = 0
		textCameraName.text = ""
		btnCameraImport.enabled = true
		btnConfirmImport.enabled = false
		btnCancelImport.enabled = false
	)
)

rollout cameraList "Camera List"
(
	listbox lboxCamAngles pos:[3,3] width:140 height:10
	button btnLoadScene "Load Scene" pos:[147,3] width:75 height:35
	button btnDeleteCamera "Delete" pos:[147,41] width:75 height:35
	button btnRenameCamera "Rename" pos:[147,78] width:75 height:35
	spinner spnSync "Sync" pos:[164,121] width:55 type:#integer
	
	
	--------------------------------Camera GroupBox Things--------------------------------
	on btnLoadScene pressed do
	(
	)
	
	on btnDeleteCamera pressed do
	(
	)
	
	on btnRenameCamera pressed do
	(
		/*
		if camera is selected in listbox do
		(
			rollout newCameraName "Camera Name" width:240
			(
				edittext cameraNameInitialize "Name:" pos:[10,10] width:220
				button cameraNameOK "OK" pos:[125,30] width:50
				button cameraNameCancel "Cancel" pos: [180, 30] width: 50
				on cameraNameOK pressed do
				(
					if cameraNameInitialize.text != "" do
					(
						--rename camera using text input--
						--bla bla bla = cameraNameInitialize.text										
						destroyDialog newCameraName
					)
					if cameraNameInitialize.text == "" do
					(
						---bla bla bla = "Unnamed Camera"
						destroyDialog newCameraName
					)				
				)
				on cameraNameCancel pressed do
				(					
					destroyDialog newCameraName
				)
			)
			createdialog newCameraName
			setFocus newCameraName.cameraNameInitialize
		)
		else
		(
			text above progress bar says "No camera is selected"
		)
		*/
	)
	
	on spnSync changed theValue do
	(
		spnSync.value = 0
	)
)

rollout exportToRL "Export Camera To Rocket League"
(
	edittext outputFilename "File Name:" pos:[3,5] width:220
	spinner spnExportFPS "Export FPS:" pos:[37,28] width:70 type:#integer range:[0,300,120]
	button btnExportCamToRL "Export camera to RL" pos:[110,26] width:110 height:22
	
	
	on btnExportCamToRL pressed do
	(
		if $MetadataDummy != undefined then
		(
			if Superclassof $ == camera then
			(
				disableSceneRedraw
				outputFilePath = "G:/Games/steamapps/common/rocketleague/Binaries/Win32/animationimports/" + outputFilename.text as string + ".txt"
				outFile = createfile outputFilePath
				format "REPLAY METADATA\n" to:outFile
				format "Name: %\n" $MetadataDummy.modifiers[1].replayName to:outFile
				format "ID: %\n" $MetadataDummy.modifiers[1].replayID to:outFile
				format "Date: %\n" $MetadataDummy.modifiers[1].replayDate to:outFile
				format "FPS: %\n" $MetadataDummy.modifiers[1].replayFPS to:outFile
				format "Frames: %\n\n" $MetadataDummy.modifiers[1].replayFrames to:outFile
				
				format "Timestamp\tCamera Position\t\t\tCamera Rotation\t\t\t\tFOV\tFocus\n" to:outFile
				
				camExportDummy = freecamera name:"CameraExportDummy" pos:[0,0,0]
				start = animationRange.start
				end = animationRange.end
				undo off
				for i = start to end do at time i
				(
					cbTimestamp = $MetadataDummy.modifiers[1].replayCurrentFrame as string
					format "%\t\t"cbTimestamp to:outFile
					camPos = $.transform.pos * [1,-1,1]
					format "%,%,%\t" camPos.x camPos.y camPos.z to:outFile
					
					camExportDummy.rotation = $.rotation
					camExportDummy.rotation.x_rotation.controller.value -= 90
					camExportDummy.rotation.z_rotation.controller.value += 90
					
					--format "%,%,%,%\t" camExportDummy.rotation.x camExportDummy.rotation.y camExportDummy.rotation.z camExportDummy.rotation.w to:outFile
					format "%,%,%,%\t" -camExportDummy.rotation.y -camExportDummy.rotation.x -camExportDummy.rotation.z camExportDummy.rotation.w to:outFile
					
					
					
					--EXPORT RAW QUAT DATA AND REIMPORT RAW. SEE IF SOMETHING IS GOING WRONG WITH THE RAW DATA
					
					
					
					
					camFOV = $.fov
					format "%\t" camFOV to:outFile
					camFocus = $.mpassEffect.focalDepth
					format "%" camFocus to:outFile
					
					if i < end - 1 do
						format "\n" to:outFile
				)
				delete camExportDummy
				close outFile
				undo on
				enableSceneRedraw
				messageBox ("Finished exporting camera path") beep:true
			)
			else
			(
				messageBox ("Selected object must be a camera") beep:true
			)
		)
		else
		(
			messageBox ("Import a scene first") beep:true
		)
	)
)





function importCar carNum = 
(
	deselect selection
	ImportFile "F:\\_YouTube\\04_Extra_Assets\\3D_Models_and_Scenes\\Rocket_League_Models\\Car_Octane_Rigged.FBX" #noPrompt
	for obj in selection do
	(
		obj.scale = [1, 1, 1]
		carNumString = carNum as string
		baseName = obj.name
		newName = "TEMPIMPORT_" + baseName
		obj.name = newName
	)
	
	--HELPER CREATION
	tempHelpers = #()
	tempHelperName = "TEMPHELPER"
	helperName = tempHelperName + 1 as string
	tempHelpers[1] = PointHelperObj name:helperName cross: true box: false size: 100 wirecolor:[14,255,2] --core helper
	for j=2 to 5 do (
		helperName = tempHelperName + j as string
		tempHelpers[j] = PointHelperObj name:helperName cross: false box: true size: 10 wirecolor:[14,255,2]
	) --axel helper
	for j=6 to 9 do (
		helperName = tempHelperName + j as string
		tempHelpers[j] = PointHelperObj name:helperName cross: false box: true size: 7.5 wirecolor:[14,255,2]
	) --spring helper
	for j=10 to 13 do (
		helperName = tempHelperName + j as string
		tempHelpers[j] = PointHelperObj name:helperName cross: true box: false size: 5 wirecolor:[14,255,2]
	) --cup helper
	for j=14 to 17 do (
		helperName = tempHelperName + j as string
		tempHelpers[j] = PointHelperObj name:helperName cross: false box: true size: 30 wirecolor:[14,255,2]
	) --wheel helper
	append carHelpers tempHelpers
	--format "carHelpers.count = %\n" carHelpers.count as string
	
	--CAR PART STORING
	tempParts = #()
	tempParts[1] = $TEMPIMPORT_RL_OCTANE_CLEAN
	tempParts[2] = $TEMPIMPORT_FL_Axel
	tempParts[3] = $TEMPIMPORT_FR_Axel
	tempParts[4] = $TEMPIMPORT_BL_Axel
	tempParts[5] = $TEMPIMPORT_BR_Axel
	tempParts[6] = $TEMPIMPORT_FL_Spring
	tempParts[7] = $TEMPIMPORT_FR_Spring
	tempParts[8] = $TEMPIMPORT_BL_Spring
	tempParts[9] = $TEMPIMPORT_BR_Spring
	tempParts[10] = $TEMPIMPORT_FL_Cup
	tempParts[11] = $TEMPIMPORT_FR_Cup
	tempParts[12] = $TEMPIMPORT_BL_Cup
	tempParts[13] = $TEMPIMPORT_BR_Cup
	tempParts[14] = $TEMPIMPORT_FL_Brakes
	tempParts[15] = $TEMPIMPORT_FR_Brakes
	tempParts[16] = $TEMPIMPORT_BL_Brakes
	tempParts[17] = $TEMPIMPORT_BR_Brakes
	tempParts[18] = $TEMPIMPORT_FL_Wheel
	tempParts[19] = $TEMPIMPORT_FR_Wheel
	tempParts[20] = $TEMPIMPORT_BL_Wheel
	tempParts[21] = $TEMPIMPORT_BR_Wheel
	append carParts tempParts
	
	--MAKING PFLOW
	--(
	individualCarBoosts = #()
	tempBoost = PF_Source name:"TEMPBOOST1" pos:[-48,9,9] Logo_Size:5 Emitter_Length:6 Emitter_Width:20 X_Coord:20 Y_Coord:0 Quantity_Viewport:100
	append individualCarBoosts tempBoost
	tempBoost = PF_Source name:"TEMPBOOST2" pos:[-48,-9,9] Logo_Size:5 Emitter_Length:6 Emitter_Width:20 X_Coord:50 Y_Coord:0 Quantity_Viewport:100
	append individualCarBoosts tempBoost
	individualCarBoosts[1].rotation.y_rotation = 90
	individualCarBoosts[2].rotation.y_rotation = 90
	individualCarBoosts[1].parent = tempParts[1]
	individualCarBoosts[2].parent = tempParts[1]
	particleFlow.BeginEdit()
	cache1 = Cache Use_At:0
	cache2 = Cache Use_At:0
	op1 = Birth Type:1 Rate:300 Emit_Start:(animationRange.start as integer) Emit_Stop:(animationRange.end as integer)
	swapOp = Age_Test Test_Value:0 Variation:0
	op2 = Position_Icon()
	op3 = Speed speed:10
	op4 = ShapeLibrary Type_3D:14 size:5
	renderer1 = RenderParticles name:"Render Car 1 Boost 1"
	renderer2 = RenderParticles name:"Render Car 1 Boost 2"
	op5 = Age_Test Test_Value:4000 Variation:800
	op6 = DisplayParticles type:6 color:[255,255,85]
	ev1 = Event name:"Boost Birth"
	ev1.SetPViewLocation (individualCarBoosts[1].X_Coord) (individualCarBoosts[1].Y_Coord+100)
	ev2 =Event name:"Standard Boost"
	ev2.SetPViewLocation (individualCarBoosts[1].X_Coord) (individualCarBoosts[1].Y_Coord+210)
	ev3 = Event name:"Age Delete Boost"
	ev3.SetPViewLocation (individualCarBoosts[1].X_Coord) (individualCarBoosts[1].Y_Coord+400)
	ev3op1 = deleteParticles()
	particleFlow.EndEdit()
	
	--ev1.AppendAction op0
	ev1.AppendAction op1
	ev1.AppendAction swapOp
	ev2.AppendAction op2
	ev2.AppendAction op3
	ev2.AppendAction op4
	ev2.AppendAction op5
	ev2.AppendAction op6
	swapOp.setNextActionList ev2 swapOp
	ev3.AppendAction ev3op1
	op5.setNextActionList ev3 op5
	
	individualCarBoosts[1].AppendAction renderer1
	individualCarBoosts[1].AppendAction cache1
	individualCarBoosts[1].AppendInitialActionList ev1
	individualCarBoosts[2].AppendAction renderer2
	individualCarBoosts[2].AppendAction cache2
	individualCarBoosts[2].AppendInitialActionList ev1
	
	append carBoosts individualCarBoosts
	
	--)

	--MAKING CUSTOM BOOST ATTRIBUTES
	--(
	BoostControls = attributes boostControlAttributes
	(
		parameters params rollout:ro_BoostControls
		(
			isBoosting type:#integer ui:boostctrlActive
			boostRate type:#integer ui:boostctrlRate
			hasJumped type:#integer ui:boostctrlJumped
		)
		rollout ro_BoostControls "Boost and Jump Controls"
		(
			spinner boostctrlRate "Boost rate: " pos:[-7,5] range:[0,1000000,60] type:#integer width:160
			slider boostctrlActive "Is Boosting" pos:[2,25] range:[0,1,0] type:#integer width:165
			slider boostctrlJumped "Has Jumped" pos:[2,77] range:[0,1,0] type:#integer width:165
		)
	)

	custAttributes.add tempHelpers[1] BoostControls --BaseObject:true
	tempHelpers[1].boostControlAttributes.boostRate.controller = bezier_float()
	tempHelpers[1].boostControlAttributes.boostRate.controller.value = 300
	tempHelpers[1].boostControlAttributes.isBoosting.controller = boolean_float()
	tempHelpers[1].boostControlAttributes.hasJumped.controller = boolean_float()
	
	
	
	SuspensionControls = attributes suspensionControlAttributes
	(
		parameters params rollout:ro_SuspensionControls
		(
			suspensionMaxAmount type:#integer ui:susMaxAmount
			suspensionPitch type:#float ui:susPitch
			suspensionRoll type:#float ui:susRoll
		)
		rollout ro_SuspensionControls "Suspension Controls"
		(
			spinner susMaxAmount "Max Suspension: " pos:[7,5] range:[0,10,0] type:#float width:150
			slider susPitch "Pitch" pos:[2,25] range:[-1,1,0] type:#float width:165
			slider susRoll "Roll" pos:[2,77] range:[-1,1,0] type:#float width:165
		)
	)

	custAttributes.add tempHelpers[1] SuspensionControls --BaseObject:true
	tempHelpers[1].suspensionControlAttributes.suspensionMaxAmount.controller = bezier_float()
	tempHelpers[1].suspensionControlAttributes.suspensionMaxAmount.controller.value = 0
	tempHelpers[1].suspensionControlAttributes.suspensionPitch.controller = bezier_float()
	tempHelpers[1].suspensionControlAttributes.suspensionRoll.controller = bezier_float()
	--)



	
	-- Align and parent helper objects to individual parts
	for p=1 to carHelpers[carNum].count do
	(
		carHelpers[carNum][p].pos = carParts[carNum][p].pos
		carParts[carNum][p].parent = carHelpers[carNum][p]
	)
	for p=2 to 5 do (carHelpers[carNum][p].parent = carHelpers[carNum][1]) -- Parent axel helpers to core helper
	for p=10 to 13 do (carHelpers[carNum][p].parent = carHelpers[carNum][1]) -- Parent cup helpers to core helper
	for p=6 to 9 do(carHelpers[carNum][p].parent = carHelpers[carNum][p-4]) -- Parent spring helpers to corresponding axel helper
	for p=14 to 17 do (carHelpers[carNum][p].parent = carHelpers[carNum][p-12]) -- Parent wheel helpers to corresponding axel helper
	for p=18 to 21 do (carParts[carNum][p].parent = carHelpers[carNum][p-4]) -- Parent wheels to corresponding wheel helpers
	
	-- Assign lookat to cup models
	for p=10 to 13 do
	(
		carParts[carNum][p].rotation.controller = LookAt_Constraint()
		carParts[carNum][p].rotation.controller.appendTarget carHelpers[carNum][p-4] 100
		carParts[carNum][p].rotation.controller.lookat_vector_length = 0
		carParts[carNum][p].rotation.controller.target_axis = 2
		carParts[carNum][p].rotation.controller.target_axisFlip = true
	)
	
	-- Assign lookat to spring models
	for p=6 to 9 do
	(
		carParts[carNum][p].rotation.controller = LookAt_Constraint()
		carParts[carNum][p].rotation.controller.appendTarget carHelpers[carNum][p+4] 100
		carParts[carNum][p].rotation.controller.lookat_vector_length = 0
		carParts[carNum][p].rotation.controller.target_axis = 2
	)
	
	for obj in carParts[carNum] do
	(
		baseName = obj.name
		--format "baseName: % -- " obj.name
		newName = replace baseName 1 10 ("Car_" + carNum as string)
		obj.name = newName
		--format "newName: %\n" newName
	)
	
	for p=1 to carHelpers[carNum].count do
	(
		carHelpers[carNum][p].name = carParts[carNum][p].name + "_Helper"
		--format "helper name: %\n" carHelpers[carNum][p].name
	)
	
	carBoosts[carNum][1].name = ("Car_" + carNum as string + "Boost_1")
	carBoosts[carNum][2].name = ("Car_" + carNum as string + "Boost_2")
	
	deselect selection
	
	--carNum += 1
)

	
createdialog CBMaxWrapper style: #(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox)
addsubrollout CBMaxWrapper.allRollouts initialize
addsubrollout CBMaxWrapper.allRollouts cameraList
addsubrollout CBMaxWrapper.allRollouts exportToRL