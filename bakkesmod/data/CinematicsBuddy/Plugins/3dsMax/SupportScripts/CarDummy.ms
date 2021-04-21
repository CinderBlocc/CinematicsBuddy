-- CarDummy stores car metadata, and animation data for boost and wheels. A placeholder car mesh is parented to the dummy.

-- INFORMATION FROM METADATADUMMY --
struct StructCarInfo
(
	CarName,
	BodyID,
	BackWheelRadius,
	FrontWheelRadius
)

function GetCarInfo MetadataDummy CarIndex =
(
	local CarInfo = StructCarInfo()
	
	local MetadataModifier = MetadataDummy.modifiers[1]
	local CarNames = FilterString MetadataModifier.CarNames "\n"
	local BodyIDs = FilterString MetadataModifier.CarBodyIDs "\n"
	local BackWheelRadii = FilterString MetadataModifier.CarBackWheelRadii "\n"
	local FrontWheelRadii = FilterString MetadataModifier.CarFrontWheelRadii "\n"
	
	CarInfo.CarName = CarNames[CarIndex]
	CarInfo.BodyID = BodyIDs[CarIndex] as integer
	CarInfo.BackWheelRadius = BackWheelRadii[CarIndex] as float
	CarInfo.FrontWheelRadius = FrontWheelRadii[CarIndex] as float
	
	return CarInfo
)

-- MAIN FUNCTION DEFINITION --
function CreateCarDummy MetadataDummy CarIndex CarMeshBase =
(
	-- Get information about this car from MetadataDummy
	local CarInfo = GetCarInfo MetadataDummy CarIndex
	
	-- Create DummyObject
	local DummyObjectName = CarInfo.CarName + " DUMMY"
	local DummyObject = PointHelperObj name:DummyObjectName cross:true box:false size:100 wirecolor:[14,255,2]
	
	-- Add custom attributes
	AddModifier DummyObject (EmptyModifier())
	local TheModifier = DummyObject.modifiers[1]
	TheModifier.name = "Car Data"
	CarDataModifier = attributes CarDataAttributes
	(
		-- Metadata
		parameters metadataparams rollout:ro_metadata
		(
			CarName             type:#string  ui:TextBoxCarName
			CarsSeenIndex       type:#integer ui:SpinnerCarsSeenIndex
			CarBodyID           type:#integer ui:SpinnerCarBodyID
			CarBackWheelRadius  type:#float   ui:SpinnerBackWheelRadius
			CarFrontWheelRadius type:#float   ui:SpinnerFrontWheelRadius
		)
		rollout ro_metadata "Metadata"
		(
			edittext TextboxCarName          "Name"               width:152 pos:[5,2]    readonly:true
			spinner  SpinnerCarsSeenIndex    "Index   "           width:178 pos:[-21,23] type:#integer enabled:false
			spinner  SpinnerCarBodyID        "Body ID"            width:179 pos:[-22,43] type:#integer enabled:false
			spinner  SpinnerBackWheelRadius  "Back Wheel Radius " width:142 pos:[15,63]  type:#float   enabled:false
			spinner  SpinnerFrontWheelRadius "Front Wheel Radius" width:140 pos:[17,83]  type:#float   enabled:false
		)
		
		-- Animation data
		parameters animationparams rollout:ro_animation
		(
			bIsDemolished         type:#boolean ui:CheckboxIsDemolished
			bIsBoosting           type:#boolean ui:CheckboxIsBoosting
			Wheel0_SteerAmount    type:#float   ui:Spinner_W0_SteerAmount
			Wheel0_SuspensionDist type:#float   ui:Spinner_W0_SuspensionDist
			Wheel0_SpinSpeed      type:#float   ui:Spinner_W0_SpinSpeed
			Wheel1_SteerAmount    type:#float   ui:Spinner_W1_SteerAmount
			Wheel1_SuspensionDist type:#float   ui:Spinner_W1_SuspensionDist
			Wheel1_SpinSpeed      type:#float   ui:Spinner_W1_SpinSpeed
			Wheel2_SteerAmount    type:#float   ui:Spinner_W2_SteerAmount
			Wheel2_SuspensionDist type:#float   ui:Spinner_W2_SuspensionDist
			Wheel2_SpinSpeed      type:#float   ui:Spinner_W2_SpinSpeed
			Wheel3_SteerAmount    type:#float   ui:Spinner_W3_SteerAmount
			Wheel3_SuspensionDist type:#float   ui:Spinner_W3_SuspensionDist
			Wheel3_SpinSpeed      type:#float   ui:Spinner_W3_SpinSpeed
		)
		rollout ro_animation "Animation Data"
		(
			checkbox CheckboxIsDemolished "Demolished" pos:[8,5] enabled:false
			checkbox CheckboxIsBoosting   "Boosting"   pos:[93,5] enabled:false
			label Label_W0 "------------- WHEEL 0 ------------- " align:#center
			spinner Spinner_W0_SteerAmount    "Steer Amount          "    pos:[19,45]  range:[-1000,1000,0] width:139 enabled:false
			spinner Spinner_W0_SuspensionDist "Suspension Distance"       pos:[23,65]  range:[-1000,1000,0] width:135 enabled:false
			spinner Spinner_W0_SpinSpeed      "Spin Speed               " pos:[21,85]  range:[-1000,1000,0] width:137 enabled:false
			label Label_W1 "------------- WHEEL 1 ------------- " align:#center
			spinner Spinner_W1_SteerAmount    "Steer Amount          "    pos:[19,122] range:[-1000,1000,0] width:139 enabled:false
			spinner Spinner_W1_SuspensionDist "Suspension Distance"       pos:[23,142] range:[-1000,1000,0] width:135 enabled:false
			spinner Spinner_W1_SpinSpeed      "Spin Speed               " pos:[21,162] range:[-1000,1000,0] width:137 enabled:false
			label Label_W2 "------------- WHEEL 2 ------------- " align:#center
			spinner Spinner_W2_SteerAmount    "Steer Amount          "    pos:[19,200] range:[-1000,1000,0] width:139 enabled:false
			spinner Spinner_W2_SuspensionDist "Suspension Distance"       pos:[23,220] range:[-1000,1000,0] width:135 enabled:false
			spinner Spinner_W2_SpinSpeed      "Spin Speed               " pos:[21,240] range:[-1000,1000,0] width:137 enabled:false
			label Label_W3 "------------- WHEEL 3 ------------- " align:#center
			spinner Spinner_W3_SteerAmount    "Steer Amount          "    pos:[19,278] range:[-1000,1000,0] width:139 enabled:false
			spinner Spinner_W3_SuspensionDist "Suspension Distance"       pos:[23,298] range:[-1000,1000,0] width:135 enabled:false
			spinner Spinner_W3_SpinSpeed      "Spin Speed               " pos:[21,318] range:[-1000,1000,0] width:137 enabled:false
		)
	)
	CustAttributes.Add TheModifier CarDataModifier
	
	-- Store metadata. Match stored car index to the index in the file
	TheModifier.CarName = CarInfo.CarName
	TheModifier.CarsSeenIndex = CarIndex - 1
	TheModifier.CarBodyID = CarInfo.BodyID
	TheModifier.CarBackWheelRadius = CarInfo.BackWheelRadius
	TheModifier.CarFrontWheelRadius = CarInfo.FrontWheelRadius
	
	-- Clone car mesh and parent it to DummyObject. CarMeshNode is created in the CloneNodes call
	MaxOps.CloneNodes CarMeshBase cloneType:#copy newNodes:&CarMeshNode #nodialog
	local CarMesh = CarMeshNode[1]
	CarMesh.name = CarInfo.CarName + " MESH"
	CarMesh.parent = DummyObject
	
	return DummyObject
)
	