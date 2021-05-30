/*
	An example script for linking a car model's rig to the CinematicsBuddy car dummy
	
	For the most part you should only need to edit the RigCustomization struct at the top to fit the needs of your car model
	
	A few general notes:
		- In order for this script to work, the MESH that you are trying to replace should be selected, not the dummy parent
		- Maxscript works best if all functions are defined before they are called
			- The actual functionality of this script is at the bottom of this file
			- Start from ProxyOctaneRigMain and trace through the functions called in that function
		- The script is filled with basic comments to help those with limited programming experience tailor the script to their needs
		- All mesh files are assumed to be in the /CinematicsBuddyAssets/Models/ folder
			- You can change that in the RigCustomization struct function if you want to use a different folder
		- Wheels indices are as follows:
			- 1 (0 in UI): Front left
			- 2 (1 in UI): Front right
			- 3 (2 in UI): Back left
			- 4 (3 in UI): Back right
*/


-- This should be most of what you edit per car script
struct RigCustomization
(
	-- Create local variables (not global) to easily access models folder relative to script location
	-- If you don't want to use relative paths, you could define the full path to your models' locations
	ScriptLocation = PathConfig.RemovePathLeaf (GetSourceFileName()) + "\\",
	ModelsLocation = ScriptLocation + "..\\..\\CinematicsBuddyAssets\\Models\\",
	
	-- Which car file to import
	CarFile = "OctaneProxyBody.FBX",
	ImportedCarName = "RL_OCTANE_PROXY_BODY",
	LowerSuspensionRodName = ImportedCarName + " SUSPENSION_LOWER",
	UpperSuspensionRodName = ImportedCarName + " SUSPENSION_UPPER",
	FrontQualifier = " FRONT",
	BackQualifier  = " BACK",
	LeftQualifier  = " LEFT",
	RightQualifier = " RIGHT",
	
	-- Which wheel file to import
	WheelFile = "WheelProxy.FBX",
	ImportedWheelName = "RL_WHEEL_PROXY",
	
	-- Color of dummies
	DummyColor = [14,255,2],
	
	-- Locations of rig pieces (symmetric, so only define left side)
	FrontWheelLocation           = [ 52.5, 27.5, -5.5],
	BackWheelLocation            = [-34.0, 30.5, -4.0],
	FrontSuspensionLowerLocation = [ 52.5,  4.5, -5.5],
	BackSuspensionLowerLocation  = [-34.0,  6.0, -4.0],
	FrontSuspensionUpperLocation = [ 52.5,  7.0,  7.0],
	BackSuspensionUpperLocation  = [-34.0, 17.5, 16.5],
	
	-- Boost emitter info
	BoostEmitterLocation = [-47.0,  7.0,  8.0],
	BoostRateDefault = 300,
	BoostDurationSeconds = 1.5,
	BoostDurationVariationSeconds = 0.2,
	EmitterLength = 6,
	EmitterWidth = 20,
	bIsDoubleEmitter = true
)


------------------
-- DUMMY PARENT --
------------------
struct ProxyRigCarInfo
(
	CarName = "UNDEFINED NAME",
	CarFrontWheelRadius = -1.0,
	CarBackWheelRadius  = -1.0
)
function GetDummyParentAndDeleteSelectedMesh =
(
	-- Make sure an object is selected
	if selection.count < 1 do
	(
		MessageBox("Nothing is selected. Please select the car mesh you want to replace.")
		return undefined
	)
	
	-- Get a reference to the first object in the selection
	local SelectedObject = selection[1]
	local DummyParent = SelectedObject.parent
	
	-- Ensure the mesh is selected and not the dummy
	if SuperClassOf SelectedObject != GeometryClass do
	(
		MessageBox("Selection is not geometry. Please select the car mesh you want to replace.")
		return undefined
	)
	
	-- Ensure the mesh has a dummy as its parent
	if DummyParent != undefined then
	(
		if SuperClassOf DummyParent != Helper do
		(
			MessageBox("Selection's parent is not a dummy. Please select a valid CinematicsBuddy imported car mesh.")
			return undefined
		)
	)
	else
	(
		MessageBox("Selection has no parent object. Please select a valid CinematicsBuddy imported car mesh.")
		return undefined
	)
	
	-- Ensure dummy has a valid metadata modifier
	local TheModifier = DummyParent.Modifiers[1]
	if TheModifier != undefined then
	(
		if TheModifier.CarName == undefined do -- Chances are the script will stop executing here if it tries accessing a nonexistant CarName variable
		(
			MessageBox("DummyParent has no metadata modifier. Please select a valid CinematicsBuddy imported car mesh.")
			return undefined
		)
	)
	else
	(
		MessageBox("DummyParent has no modifiers. Please select a valid CinematicsBuddy imported car mesh.")
		return undefined
	)
	
	-- Delete the mesh and return a reference to the parent object
	delete SelectedObject
	return DummyParent
)
function GetCarInfo DummyParent =
(
	local CarInfo = ProxyRigCarInfo()
	
	local TheModifier = DummyParent.Modifiers[1]
	CarInfo.CarName = TheModifier.CarName
	CarInfo.CarFrontWheelRadius = TheModifier.CarFrontWheelRadius
	CarInfo.CarBackWheelRadius  = TheModifier.CarBackWheelRadius
	
	return CarInfo
)


--------------------
-- MESH IMPORTING --
--------------------
struct ProxyRigImportedModels
(
	BodyMesh  = undefined,
	WheelMesh = undefined
)
function ImportProxyMeshes =
(
	local CustomizationInfo = RigCustomization()
	
	-- Create empty struct that will be filled with the models and returned so other functions can access the models
	local TheMeshes = ProxyRigImportedModels()
	
	-- Import the Octane proxy body mesh and assign it to the output struct
	local BodyMeshLocation = CustomizationInfo.ModelsLocation + CustomizationInfo.CarFile
	ImportFile BodyMeshLocation #noPrompt
	TheMeshes.BodyMesh = GetNodeByName(CustomizationInfo.ImportedCarName)
	
	-- Import the proxy wheel mesh and assign it to the output struct
	local WheelMeshLocation = CustomizationInfo.ModelsLocation + CustomizationInfo.WheelFile
	ImportFile WheelMeshLocation #noPrompt
	TheMeshes.WheelMesh = GetNodeByName(CustomizationInfo.ImportedWheelName)
	
	-- Ensure both objects are at full scale. Warn if either is invalid.
	if TheMeshes.BodyMesh != undefined then TheMeshes.BodyMesh.scale = [1,1,1]
	else MessageBox("TheMeshes.BodyMesh is undefined")
	if TheMeshes.WheelMesh != undefined then TheMeshes.WheelMesh.scale = [1,1,1]
	else MessageBox("TheMeshes.WheelMesh is undefined")
	
	-- Return the struct so the calling function can use the objects
	return TheMeshes
)


--------------------
-- RIG GENERATION --
--------------------
struct ProxyRigOctane
(
	RootObject = undefined,
	BodyMesh   = undefined,
	WheelMeshes       = #(),
	BoostEmitters     = #(),
	WheelRootDummies  = #(),
	SteeringDummies   = #(),
	SpinningDummies   = #(),
	SuspensionLowerDummies = #(),
	SuspensionUpperDummies = #(),
	SuspensionLowerMeshes  = #(),
	SuspensionUpperMeshes  = #()
)
function ProxyRigMirrorObject ObjectToMirror OriginalObject bInvertScale =
(
	ObjectToMirror.transform = OriginalObject.transform
	ObjectToMirror.pos.y *= -1
	
	if bInvertScale do ObjectToMirror.scale.y *= -1
)
function ProxyRigPlaceWheels TheMeshes TheRig CarInfo = 
(
	-- Clone the wheels
	for i = 1 to 4 do
	(
		MaxOps.CloneNodes TheMeshes.WheelMesh cloneType:#copy newNodes:&WheelMeshNode #nodialog
		local NewWheel = WheelMeshNode[1]
		NewWheel.name = CarInfo.CarName + " WHEEL " + ((i - 1) as string)
		Append TheRig.WheelMeshes NewWheel
	)
	
	-- Delete the original wheel mesh
	delete TheMeshes.WheelMesh
	
	-- Location and scale variables
	local CustomizationInfo = RigCustomization()
	local BackScaleRatio = CarInfo.CarBackWheelRadius / CarInfo.CarFrontWheelRadius
	
	-- Transform the front wheels
	TheRig.WheelMeshes[1].pos = CustomizationInfo.FrontWheelLocation
	ProxyRigMirrorObject TheRig.WheelMeshes[2] TheRig.WheelMeshes[1] true
	
	-- Transform the back wheels
	TheRig.WheelMeshes[3].pos = CustomizationInfo.BackWheelLocation
	ProxyRigMirrorObject TheRig.WheelMeshes[4] TheRig.WheelMeshes[3] true
	TheRig.WheelMeshes[3].scale *= [BackScaleRatio, 1, BackScaleRatio]
	TheRig.WheelMeshes[4].scale *= [BackScaleRatio, 1, BackScaleRatio]
)
function ProxyRigGetSuspensions TheRig CarInfo = 
(
	local CI = RigCustomization()
	
	-- Get the meshes by the names specified in the customization at the top
	local SuspensionLowerMeshes = #()
	local SuspensionUpperMeshes = #()
	local FrontBack = #(CI.FrontQualifier, CI.BackQualifier)
	local LeftRight = #(CI.LeftQualifier, CI.RightQualifier)
	
	for FrontBackIdx = 1 to 2 do
	(
		for LeftRightIdx = 1 to 2 do
		(
			local LowerRod = GetNodeByName(CI.LowerSuspensionRodName + FrontBack[FrontBackIdx] + LeftRight[LeftRightIdx])
			local UpperRod = GetNodeByName(CI.UpperSuspensionRodName + FrontBack[FrontBackIdx] + LeftRight[LeftRightIdx])
			
			LowerRod.name = CarInfo.CarName + " LOWERSUSPENSIONROD" + FrontBack[FrontBackIdx] + LeftRight[LeftRightIdx]
			UpperRod.name = CarInfo.CarName + " UPPERSUSPENSIONROD" + FrontBack[FrontBackIdx] + LeftRight[LeftRightIdx]
			
			append SuspensionLowerMeshes LowerRod
			append SuspensionUpperMeshes UpperRod
		)
	)
	
	TheRig.SuspensionLowerMeshes = SuspensionLowerMeshes
	TheRig.SuspensionUpperMeshes = SuspensionUpperMeshes
)
function GenerateProxyOctaneRigDummies TheRig CarInfo = 
(
	local CustomizationInfo = RigCustomization()
	
	-- Create the root object that all elements will be bound to
	local RootObjectName = CarInfo.CarName + " ROOT"
	TheRig.RootObject = PointHelperObj name:RootObjectName cross:false box:true size:100 wirecolor:CustomizationInfo.DummyColor
	
	-- Create arrays of transforms to iterate dummy creation
	local WheelLocations = #()
	local SuspensionLowerLocations = #()
	local SuspensionUpperLocations = #()
	local Scales = #()
	append WheelLocations  CustomizationInfo.FrontWheelLocation
	append WheelLocations (CustomizationInfo.FrontWheelLocation * [1, -1, 1])
	append WheelLocations  CustomizationInfo.BackWheelLocation
	append WheelLocations (CustomizationInfo.BackWheelLocation * [1, -1, 1])
	append SuspensionLowerLocations  CustomizationInfo.FrontSuspensionLowerLocation
	append SuspensionLowerLocations (CustomizationInfo.FrontSuspensionLowerLocation * [1, -1, 1])
	append SuspensionLowerLocations  CustomizationInfo.BackSuspensionLowerLocation
	append SuspensionLowerLocations (CustomizationInfo.BackSuspensionLowerLocation * [1, -1, 1])
	append SuspensionUpperLocations  CustomizationInfo.FrontSuspensionUpperLocation
	append SuspensionUpperLocations (CustomizationInfo.FrontSuspensionUpperLocation * [1, -1, 1])
	append SuspensionUpperLocations  CustomizationInfo.BackSuspensionUpperLocation
	append SuspensionUpperLocations (CustomizationInfo.BackSuspensionUpperLocation * [1, -1, 1])
	local BackScaleRatio = CarInfo.CarBackWheelRadius / CarInfo.CarFrontWheelRadius
	append Scales 1
	append Scales 1
	append Scales BackScaleRatio
	append Scales BackScaleRatio
	
	-- Create the dummies
	for i = 1 to 4 do
	(
		local WheelRootName  = TheRig.WheelMeshes[i].name + " ROOT"
		local WheelRootDummy = PointHelperObj name:WheelRootName cross:false box:true axistripod:false size:10 wirecolor:CustomizationInfo.DummyColor
		WheelRootDummy.pos   = WheelLocations[i]
		append TheRig.WheelRootDummies WheelRootDummy
		
		local SteeringName  = TheRig.WheelMeshes[i].name + " STEERING"
		local SteeringDummy = PointHelperObj name:SteeringName cross:false box:true axistripod:false size:15 wirecolor:CustomizationInfo.DummyColor
		SteeringDummy.pos   = WheelLocations[i]
		append TheRig.SteeringDummies SteeringDummy
		
		local SpinningName  = TheRig.WheelMeshes[i].name + " SPINNING"
		local SpinningDummy = PointHelperObj name:SpinningName cross:false box:true axistripod:false size:(35*Scales[i]) wirecolor:CustomizationInfo.DummyColor
		SpinningDummy.pos   = WheelLocations[i]
		append TheRig.SpinningDummies SpinningDummy
		
		local SuspensionLowerName   = TheRig.WheelMeshes[i].name + " SUSPENSION LOWER"
		local SuspensionLowerDummy = PointHelperObj name:SuspensionLowerName cross:false box:true axistripod:false size:10 wirecolor:CustomizationInfo.DummyColor
		SuspensionLowerDummy.pos    = SuspensionLowerLocations[i]
		append TheRig.SuspensionLowerDummies SuspensionLowerDummy
		
		local SuspensionUpperName   = TheRig.WheelMeshes[i].name + " SUSPENSION UPPER"
		local SuspensionUpperDummy = PointHelperObj name:SuspensionUpperName cross:false box:true axistripod:false size:10 wirecolor:CustomizationInfo.DummyColor
		SuspensionUpperDummy.pos    = SuspensionUpperLocations[i]
		append TheRig.SuspensionUpperDummies SuspensionUpperDummy
	)
)
function GenerateProxyOctaneBoostEmitters TheRig CarInfo = 
(
	local BoostEmitters = #()
	
	local CI = RigCustomization()
	
	-- Create first boost source
	local BoostBaseName = CarInfo.CarName + " Boost"
	local BoostLeftName = BoostBaseName
	if CI.bIsDoubleEmitter do (BoostLeftName = BoostBaseName + " Left")
	local LogoSize = 10
	if CI.EmitterLength < CI.EmitterWidth then ( LogoSize = CI.EmitterLength )
	else ( LogoSize = CI.EmitterWidth )
	local BoostLeft = PF_Source name:BoostLeftName pos:CI.BoostEmitterLocation Logo_Size:LogoSize Emitter_Length:CI.EmitterLength Emitter_Width:CI.EmitterWidth X_Coord:20 Y_Coord:0 Quantity_Viewport:100
	
	particleFlow.beginEdit()
	-- EVENT 1: EMISSION
	Event1 = Event name:(CarInfo.CarName + " Boost Birth")
	Event1.SetPViewLocation (BoostLeft.X_Coord) (BoostLeft.Y_Coord + 100)
	
	-- EVENT 2: DESIGN AND DISPLAY
	Event2 = Event name:(CarInfo.CarName + " Standard Boost")
	Event2.SetPViewLocation (BoostLeft.X_Coord) (BoostLeft.Y_Coord + 210)
	
	-- EVENT 3: DELETE
	Event3 = Event name:(CarInfo.CarName + " Age Delete Boost")
	Event3.SetPViewLocation (BoostLeft.X_Coord) (BoostLeft.Y_Coord + 400)
	particleFlow.endEdit()
	
	-- EVENT 1
		-- Emitter operator to spawn particles. As soon as they spawn, throw to next event (design and display)
		particleFlow.beginEdit()
		OpEmitter     = Birth Type:1 Rate:300 Emit_Start:(AnimationRange.Start as integer) Emit_Stop:(AnimationRange.End as integer)
		ThrowToEvent2 = Age_Test Test_Value:0 Variation:0
		particleFlow.endEdit()
		
		ThrowToEvent2.SetNextActionList Event2 ThrowToEvent2
		
		Event1.AppendAction OpEmitter
		Event1.AppendAction ThrowToEvent2
	
	-- EVENT 2
		-- Design and display particles. After a certain age, throw to next event (delete)
		-- Note: Test values for age are done via tick. 3ds max has 4800 ticks per second
		particleFlow.beginEdit()
		OpPosition         = Position_Icon()
		OpSpeed            = Speed speed:10
		OpParticleShape    = ShapeLibrary Type_3D:14 size:5
		ThrowToEvent3      = Age_Test Test_Value:(4800 * CI.BoostDurationSeconds) Variation:(4800 * CI.BoostDurationVariationSeconds)
		OpDisplayParticles = DisplayParticles type:6 color:[255,255,85]
		particleFlow.endEdit()
		
		ThrowToEvent3.SetNextActionList Event3 ThrowToEvent3
		
		Event2.AppendAction OpPosition
		Event2.AppendAction OpSpeed
		Event2.AppendAction OpParticleShape
		Event2.AppendAction ThrowToEvent3
		Event2.AppendAction OpDisplayParticles
	
	-- EVENT 3
		particleFlow.beginEdit()
		OpDelete = DeleteParticles()
		particleFlow.endEdit()
		Event3.AppendAction OpDelete
	
	-- Create renderers and caches
	particleFlow.beginEdit()
	RendererLeft = RenderParticles name:(CarInfo.CarName + " Render Left")
	CacheLeft = Cache Use_At:0
	particleFlow.endEdit()
	
	BoostLeft.AppendAction RendererLeft
	BoostLeft.AppendAction CacheLeft
	BoostLeft.AppendInitialActionList Event1
	BoostLeft.rotation.y_rotation = 90
	append BoostEmitters BoostLeft
	
	if CI.bIsDoubleEmitter do
	(
		local BoostRight = PF_Source name:(BoostBaseName + " Right") pos:(CI.BoostEmitterLocation * [1,-1,1]) Logo_Size:LogoSize Emitter_Length:CI.EmitterLength Emitter_Width:CI.EmitterWidth X_Coord:50 Y_Coord:0 Quantity_Viewport:100
		
		particleFlow.beginEdit()
		RendererRight = RenderParticles name:(CarInfo.CarName + " Render Right")
		CacheRight = Cache Use_At:0
		particleFlow.endEdit()
		
		BoostRight.AppendAction RendererRight
		BoostRight.AppendAction CacheRight
		BoostRight.AppendInitialActionList Event1
		BoostRight.rotation.y_rotation = 90
		append BoostEmitters BoostRight
	)
	
	TheRig.BoostEmitters = BoostEmitters
)
function GenerateProxyOctaneRig TheMeshes CarInfo = 
(
	local TheRig = ProxyRigOctane()
	
	-- Assign the car mesh to the rig and rename it
	TheRig.BodyMesh = TheMeshes.BodyMesh
	TheRig.BodyMesh.name = CarInfo.CarName + " BODY MESH"
	
	-- Put the wheel meshes in the right places and name them
	ProxyRigPlaceWheels TheMeshes TheRig CarInfo
	
	-- Store a reference to all of the suspension rod meshes
	ProxyRigGetSuspensions TheRig CarInfo
	
	-- Generate all of the necessary dummy objects
	GenerateProxyOctaneRigDummies TheRig CarInfo
	
	-- Generate boost emitters
	GenerateProxyOctaneBoostEmitters TheRig CarInfo
	
	return TheRig
)


-----------------
-- RIG BINDING --
-----------------
struct ProxyOctaneMetadataControllers
(
	bIsBoosting,
	SteerAmount        = #(),
	SuspensionDistance = #(),
	SpinSpeed          = #()
)
function ConstrainProxyOctaneRig TheRig = 
(
	/*
		HIERARCHY (<<Refers to mesh instead of dummy>>)
		RootObject
			<<BodyMesh>>
			BoostEmitters
			SuspensionUpperDummies (LookAtConstraint: SteeringDummies)
				<<UpperRodMeshes>>
			SuspensionLowerDummies
				WheelRootDummies
				<<LowerRodMeshes>>
			SteeringDummies (PositionConstraint: WheelRootDummies)
				SpinningDummies
					<<WheelMeshes>>
		
		TRANSFORM LOCK FLAGS
		1: POS_X
		2: POS_Y
		3: POS_Z
		4: ROT_X
		5: ROT_Y
		6: ROT_Z
		7: SCALE_X
		8: SCALE_Y
		9: SCALE_Z
	*/
	
	-- Parent body mesh to root
	TheRig.BodyMesh.parent = TheRig.RootObject
	SetTransformLockFlags TheRig.BodyMesh #all
	SetTransformLockFlags TheRig.RootObject #all
	
	-- Parent boost emitters to root
	for i = 1 to TheRig.BoostEmitters.count do
	(
		TheRig.BoostEmitters[i].parent = TheRig.RootObject
		SetTransformLockFlags TheRig.BoostEmitters[i] #all
	)
	
	-- Rig upper suspensions along with upper rod meshes
	for i = 1 to TheRig.SuspensionUpperDummies.count do
	(
		-- Parent suspension to root
		TheRig.SuspensionUpperDummies[i].parent = TheRig.RootObject
		
		-- Assign lookat constraint to point upper suspension at steering dummy
		TheRig.SuspensionUpperDummies[i].rotation.controller = LookAt_Constraint()
		local TheController = TheRig.SuspensionUpperDummies[i].rotation.controller
		TheController.appendTarget TheRig.WheelRootDummies[i] 100
		TheController.lookat_vector_length = 0
		TheController.target_axis = 2
		TheController.target_axisFlip = true
		TheController.upnode_world = false
		TheController.pickUpNode = TheRig.RootObject
		
		-- Parent upper rod mesh to suspension dummy
		TheRig.SuspensionUpperMeshes[i].parent = TheRig.SuspensionUpperDummies[i]
		
		-- Lock transforms
		SetTransformLockFlags TheRig.SuspensionUpperDummies[i] #{1,2,3,5,6,7,8,9}
		SetTransformLockFlags TheRig.SuspensionUpperMeshes[i] #all
	)
	
	-- Rig lower suspensions along with wheel root dummies and lower rod meshes
	for i = 1 to TheRig.SuspensionLowerDummies.count do
	(
		-- Parent suspension to root
		TheRig.SuspensionLowerDummies[i].parent = TheRig.RootObject
		
		-- Parent wheel root to suspension
		TheRig.WheelRootDummies[i].parent = TheRig.SuspensionLowerDummies[i]
		
		-- Parent lower rod mesh to suspension dummy
		TheRig.SuspensionLowerMeshes[i].parent = TheRig.SuspensionLowerDummies[i]
		
		-- Lock transforms
		SetTransformLockFlags TheRig.SuspensionLowerDummies[i] #{1,2,3,5,6,7,8,9}
		SetTransformLockFlags TheRig.WheelRootDummies[i] #all
		SetTransformLockFlags TheRig.SuspensionLowerMeshes[i] #all
	)
	
	-- Rig steering dummies along with spinning dummies and wheel meshes
	-- Wheels remain aligned vertically even when the suspension is rotated down, so there's some constraint trickery involved
	for i = 1 to TheRig.SteeringDummies.count do
	(
		-- Parent steering dummy to root
		TheRig.SteeringDummies[i].parent = TheRig.RootObject
		
		-- Override the position constraint to lock to the wheel root position
		TheRig.SteeringDummies[i].position.controller = Position_Constraint()
		local TheController = TheRig.SteeringDummies[i].position.controller
		TheController.appendTarget TheRig.WheelRootDummies[i] 100
		
		-- Parent spinning dummy to steering dummy
		TheRig.SpinningDummies[i].parent = TheRig.SteeringDummies[i]
		
		-- Parent wheel mesh to spinning dummy
		TheRig.WheelMeshes[i].parent = TheRig.SpinningDummies[i]
		
		-- Lock transforms
		SetTransformLockFlags TheRig.SteeringDummies[i] #{1,2,3,4,5,7,8,9}
		SetTransformLockFlags TheRig.SpinningDummies[i] #{1,2,3,4,6,7,8,9}
		SetTransformLockFlags TheRig.WheelMeshes[i] #all
	)
)
function MoveProxyOctaneRigToParent TheRig DummyParent =
(
	-- Move the rig's root object to the DummyParent's transform
	TheRig.RootObject.rotation = DummyParent.rotation
	TheRig.RootObject.pos = DummyParent.pos
	
	-- Make the rig's root object a child of DummyParent
	TheRig.RootObject.parent = DummyParent
)
function AddBoostModifierToDummyParent DummyParent = 
(
	local CustomizationInfo = RigCustomization()
	
	local TheModifier = EmptyModifier()
	TheModifier.name = "Boost Data"
	BoostDataModifier = attributes BoostDataAttributes
	(
		parameters boostdataparams rollout:ro_boostdata
		(
			BoostRate type:#float ui:SpinnerBoostRate
		)
		rollout ro_boostdata "Boost"
		(
			spinner SpinnerBoostRate "Boost Rate" range:[0,2000,0] type:#float
		)
	)
	CustAttributes.Add TheModifier BoostDataModifier
	TheModifier.BoostRate.controller = bezier_float()
	TheModifier.BoostRate.controller.value = CustomizationInfo.BoostRateDefault
	
	AddModifier DummyParent TheModifier before:1
)
function GetProxyOctaneMetadataControllers DummyParent = 
(
	local TheControllers = ProxyOctaneMetadataControllers()
	
	local TheModifier = DummyParent.Modifiers[1]
	TheControllers.bIsBoosting = TheModifier.bIsBoosting.controller
	append TheControllers.SteerAmount TheModifier.Wheel0_SteerAmount.controller
	append TheControllers.SteerAmount TheModifier.Wheel1_SteerAmount.controller
	append TheControllers.SteerAmount TheModifier.Wheel2_SteerAmount.controller
	append TheControllers.SteerAmount TheModifier.Wheel3_SteerAmount.controller
	append TheControllers.SuspensionDistance TheModifier.Wheel0_SuspensionDist.controller
	append TheControllers.SuspensionDistance TheModifier.Wheel1_SuspensionDist.controller
	append TheControllers.SuspensionDistance TheModifier.Wheel2_SuspensionDist.controller
	append TheControllers.SuspensionDistance TheModifier.Wheel3_SuspensionDist.controller
	append TheControllers.SpinSpeed TheModifier.Wheel0_SpinSpeed.controller
	append TheControllers.SpinSpeed TheModifier.Wheel1_SpinSpeed.controller
	append TheControllers.SpinSpeed TheModifier.Wheel2_SpinSpeed.controller
	append TheControllers.SpinSpeed TheModifier.Wheel3_SpinSpeed.controller
	
	return TheControllers
)
function WireProxyOctaneRigParameters TheRig DummyParent = 
(
	-- For more information about these paramters, refer to the CarDummy.ms script in the CinematicsBuddy 3dsMax SupportScripts folder
	local AnimationModifier = DummyParent.Modifiers[1]
	local BoostModifier = DummyParent.Modifiers[2]
	local CustomizationInfo = RigCustomization()
	
	-- Get the arrays of controllers for easier iteration
	local TheControllers = GetProxyOctaneMetadataControllers DummyParent
	
	-- Wire boosting controller
	local BoostParticleSystem = TheRig.BoostEmitters[1].GetInitialActionList 1
	local BoostEmitter = BoostParticleSystem.GetAction 1
	local BoostScript  = Float_Script()
	BoostScript.AddTarget "bIsBoosting" TheControllers.bIsBoosting
	BoostScript.AddTarget "BoostRate" BoostModifier.BoostRate.controller
	BoostScript.Script = "if bIsBoosting then BoostRate else 0"
	BoostEmitter.rate.controller = BoostScript
	
	-- Wire wheels
	for i = 1 to TheRig.WheelRootDummies.count do
	(
		-- SteerAmount
		local SteerScript = Float_Script()
		SteerScript.AddTarget "SteerAmount" TheControllers.SteerAmount[i]
		SteerScript.Script = "SteerAmount * -1.0"
		TheRig.SteeringDummies[i].rotation.z_rotation.controller = SteerScript
		
		-- SuspensionDistance
		local SuspensionScript = Float_Script()
		SuspensionScript.AddTarget "SuspensionDistance" TheControllers.SuspensionDistance[i]
		local ModResult = mod i 2
		if ModResult == 0 then ( SuspensionScript.Script = "SuspensionDistance / 57.2958" )
		else ( SuspensionScript.Script = "SuspensionDistance / -57.2958" )
		TheRig.SuspensionLowerDummies[i].rotation.x_rotation.controller = SuspensionScript
	)
	
	-- Bake spin speed into keyframes
	local DeltaTime = 1.0 / (framerate as float)
	local PreviousRotationValues = #(0.0, 0.0, 0.0, 0.0)
	set animate on
	for CurrentFrame = AnimationRange.Start to AnimationRange.End do
	(
		at time CurrentFrame
		(
			for i = 1 to TheRig.SpinningDummies.count do
			(
				local CurrentSpinSpeed = TheControllers.SpinSpeed[i].value
				local NewValue = PreviousRotationValues[i] + CurrentSpinSpeed * DeltaTime * 57.2958
				
				TheRig.SpinningDummies[i].rotation.y_rotation.controller.value = NewValue
				PreviousRotationValues[i] = NewValue
			)
		)
	)
	set animate off
)
function BindProxyOctaneRig TheRig DummyParent =
(
	-- Apply all the internal contstraints before moving to the parent
	ConstrainProxyOctaneRig TheRig
	
	-- Move the rig to the location of DummyParent and set DummyParent as the overall parent object
	MoveProxyOctaneRigToParent TheRig DummyParent
	
	-- Add boost modifier to control boost rate
	AddBoostModifierToDummyParent DummyParent
	
	-- Wire all of the rig elements to the metadata modifier
	WireProxyOctaneRigParameters TheRig DummyParent
)


------------------------
-- MAIN FUNCTIONALITY --
------------------------
-- Note the main function is actually a function instead of loose code
-- This lets us keep all of our variables local instead of global to prevent namespace pollution
-- ProxyOctaneRigMain is called just below its definition
function ProxyOctaneRigMain = 
(
	-- Obtain selected mesh's parent and delete the mesh
	-- If the selected object was not a mesh or had no parent with a valid modifier, it will be undefined
	local DummyParent = GetDummyParentAndDeleteSelectedMesh()
	if DummyParent == undefined do return false
	
	-- Get car name and wheel sizes from parent
	local CarInfo = GetCarInfo(DummyParent)
	
	-- Get meshes and make sure theyre valid before continuing
	local TheMeshes = ImportProxyMeshes()
	if TheMeshes.BodyMesh == undefined or TheMeshes.WheelMesh == undefined do return false
	
	-- Create rig dummies and wheel set
	local TheRig = GenerateProxyOctaneRig TheMeshes CarInfo
	
	-- Bind the new dummy objects to the dummy parent
	BindProxyOctaneRig TheRig DummyParent
	
	return true
)

--- Run the full script ----
ProxyOctaneRigMain() ----
----------------------------