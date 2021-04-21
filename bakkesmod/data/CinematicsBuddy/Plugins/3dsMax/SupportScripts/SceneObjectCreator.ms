-- SceneObjectCreator creates the objects necessary to rebuild the Rocket League scene inside 3ds Max.

-- Import additional scripts so their functions can be called
FileIn(CBSupportScripts + "CarDummy.ms")
FileIn(CBSupportScripts + "CameraCreator.ms")
	
-- STRUCT DEFINITION --
struct StructSceneObjects
(
	MetadataDummy,
	ArenaMesh,
	BallDummy,
	CameraObject,
	CarDummies = #()
)

struct StructNewCamera
(
	MetadataDummy,
	CameraObject
)
	
-- FUNCTION DEFINITION --
function CreateSceneObjects ImportTypes MetadataDummy CameraName = 
(
	DisableSceneRedraw
	SceneObjects = StructSceneObjects()
	
	-- Store MetadataDummy in SceneObjects so it can be easily passed around in functions
	SceneObjects.MetadataDummy = MetadataDummy
	local MetadataModifier = MetadataDummy.modifiers[1]
	
	-- Import arena mesh
	local ArenaLocation = CBModelAssets + "StadiumProxy.FBX"
	ImportFile ArenaLocation #noPrompt
	SceneObjects.ArenaMesh = $RL_STADIUM_PROXY
	SceneObjects.ArenaMesh.scale = [1,1,1]
	MetadataModifier.OtherArenaName = SceneObjects.ArenaMesh.name
	
	-- Create camera
	if ImportTypes.bImportCamera == true do
	(
		SceneObjects.CameraObject = CreateCamera(CameraName)
	)
	
	-- Import ball mesh
	if ImportTypes.bImportBall == true do
	(
		local BallLocation = CBModelAssets + "BallProxy.FBX"
		ImportFile BallLocation #noPrompt
		local BallMesh = $RL_BALL_PROXY
		BallMesh.scale = [1,1,1]
		BallMesh.rotation = EulerAngles 0 0 -30
		
		-- Create dummy for ball so ballmesh can have rotation offset
		local BallDummy = PointHelperObj name:"RL_BALL_PROXY DUMMY" cross:true box:false size:250 wirecolor:[14,255,2]
		BallMesh.parent = BallDummy
		SceneObjects.BallDummy = BallDummy
		
		MetadataModifier.OtherBallName  = SceneObjects.BallDummy.name
	)
	
	-- Import car mesh to assign to car dummies
	if ImportTypes.bImportBall == true do
	(
		local CarLocation = CBModelAssets + "OctaneProxy.FBX"
		ImportFile CarLocation #noPrompt
		local CarMeshBase = $RL_OCTANE_PROXY
		CarMeshBase.scale = [1,1,1]
		
		-- Loop through car names from MetadataDummy and create dummies that hold their respective car data
		-- IMPORTANT: Maxscript starts with index 1, but the CarsSeen array starts at 0. This is handled internally in CreateCarDummy
		local CarNamesArray = FilterString MetadataModifier.CarNames "\n"
		local CarIndex = 1
		while CarIndex <= CarNamesArray.count do
		(
			local NewCarDummy = CreateCarDummy MetadataDummy CarIndex CarMeshBase		
			append SceneObjects.CarDummies NewCarDummy
			CarIndex += 1
		)
		
		-- Delete original car mesh as all the dummies made their own clones
		delete CarMeshBase
	)
	
	EnableSceneRedraw
	return SceneObjects
)
