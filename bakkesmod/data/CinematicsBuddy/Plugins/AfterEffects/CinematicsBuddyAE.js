//Written by: SwiFT EQ and CinderBlock
//Version 0.9.9e

// GLOBAL VARIABLES //
ProgressDialog();
ProgressSteps = 20;
var BlueColor = [0.35, 0.45, 0.9];
var OrangeColor = [0.95, 0.55, 0.2];
var bShouldEulerFilter = true;

// RUN THE SCRIPT //
main();

// PROGRESS DIALOG DEFINITION //
function ProgressDialog()
{    
    var TheWindow;
    var MainLabel;
    var MainBar;
    var SubLabel;
    var SubBar;
    var CancelButton;

    //Create the dialog box
    TheWindow = new Window("palette", "Progress", undefined, {closeButton: true});
    
    //Create the label and progress bar for the main steps
    MainLabel = TheWindow.add("statictext");
    MainLabel.preferredSize = [450, -1];
    MainBar = TheWindow.add("progressbar", undefined, 0, 5);
    MainBar.preferredSize = [450, -1];

    //Create the label and progress bar for the sub steps
    //SubBar is defaulted to 100 steps, but should be set using SetSubSteps
    SubLabel = TheWindow.add("statictext");
    SubLabel.preferredSize = [450, -1];
    SubBar = TheWindow.add("progressbar", undefined, 0, 100);
    SubBar.preferredSize = [450, -1];

    // MEMBER FUNCTIONS //
    ProgressDialog.IncrementMain = function()
    {
        ++MainBar.value;
        SubBar.value = 0;
        SubLabel.text = "";
        TheWindow.update();
    };

    ProgressDialog.IncrementSub = function(amount)
    {
        SubBar.value += amount;
        //TheWindow.update();
    };

    ProgressDialog.MainMessage = function(message)
    {
        MainLabel.text = message;
        TheWindow.update();
    };

    ProgressDialog.SubMessage = function(message)
    {
        SubLabel.text = message;
        TheWindow.update();
    };

    ProgressDialog.SetMainMaxValue = function(MainSteps)
    {
        MainBar.maxvalue = MainSteps;
        TheWindow.update();
    }

    ProgressDialog.SetSubMaxValue = function(SubSteps)
    {
        SubBar.maxvalue = SubSteps;
        SubBar.value = 0;
        TheWindow.update();
    }

    ProgressDialog.Show = function()
    {
        TheWindow.show();
        TheWindow.update();
    }

    ProgressDialog.Close = function()
    {
        MainLabel.text = "";
        MainBar.value = 0;
        SubLabel.text = "";
        SubBar.value = 0;
        TheWindow.update();
        TheWindow.close();
    };
}
//

// MAIN FUNCTIONS //
function main()
{
    //Make sure there is an active composition
    if(app.project.activeItem == null)
    {
        alert("No selected composition");
        return;
    }
    
    //Create the FileData object. Contains all lines from file, and current line index
    var FileData = GetFileData();
    if(FileData.bSuccess == true)
    {
        //Initialize progress dialog. Currently 5 main steps as denoted by the functions below
        ProgressDialog.SetMainMaxValue(5);
        ProgressDialog.Show();
        
        //Collect header metadata
        var HeaderData = GetHeaderData(FileData.HeaderString);
        
        //Collect keyframes as chunks of strings
        var KeyframeStrings = SplitKeyframes(FileData.KeyframeStrings, parseInt(HeaderData.RecordingMetadata.Frames));

        //Collect arrays of keyframe data, starting from current line index in FileData
        var Keyframes = GetKeyframes(KeyframeStrings, HeaderData);
        
        //Compile all of the keyframes into individual arrays
        var Arrays = GetKeyframeArrays(Keyframes, HeaderData);
        
        //Create camera and layers and apply keyframe data
        ApplyKeyframes(Arrays, HeaderData);
        
        //Return version number upon successful completion
        ProgressDialog.Close();
        return "Version: " + HeaderData.RecordingMetadata.Version;
    }

    return "Failed to open txt file";
}

function GetFileData()
{
    //Create object to return later
    var FileData = new Object();
    FileData.bSuccess = false;
    FileData.HeaderString = new Object();
    FileData.KeyframeStrings = new Object();

    //Get user's file selection
    var ChosenFile = File.openDialog("Choose a Cinematics Buddy export file");

    //Read the file, then close it
    var TheData = new Object();
    if(ChosenFile && ChosenFile.open("r"))
    {
        TheData = ChosenFile.read();        
        ChosenFile.close();
    }
    else
    {
        //File was either not selected or unable to be opened
        alert("Invalid file");
        return FileData;
    }

    //Convert data into a string and split between header and keyframes
    var AsString = TheData.toString();
    var HeaderSubstringEnd = AsString.indexOf("\n", AsString.indexOf("BEGIN ANIMATION"));
    FileData.HeaderString = AsString.substring(0, HeaderSubstringEnd);
    FileData.KeyframeStrings = AsString.substring(HeaderSubstringEnd);
    
    //Successfully completed file read
    FileData.bSuccess = true;
    return FileData;
}

function GetHeaderData(TheHeader)
{
    ProgressDialog.MainMessage("Parsing header");
    ProgressDialog.SetSubMaxValue(3);
    
    //Initialize HeaderData object
    var HeaderData = new Object();
    HeaderData.Lines = TheHeader.split("\n");
    HeaderData.CurrentLine = 0;
    
    //Get RecordingMetadata
    ProgressDialog.SubMessage("Getting Recording Metadata");
    HeaderData.RecordingMetadata = GetRecordingMetadata(HeaderData);
    ProgressDialog.IncrementSub(1);
    
    //Get ReplayMetadata
    ProgressDialog.SubMessage("Getting Replay Metadata");
    HeaderData.ReplayMetadata = GetReplayMetadata(HeaderData);
    ProgressDialog.IncrementSub(1);
    
    //Get CarsSeen
    ProgressDialog.SubMessage("Getting Cars Seen");
    HeaderData.CarsSeen = GetCarsSeen(HeaderData);
    ProgressDialog.IncrementSub(1);
    
    ProgressDialog.IncrementMain();
    return HeaderData;
}

function SplitKeyframes(InString, TotalKeyframes)
{
    ProgressDialog.MainMessage("Splitting keyframes");
    ProgressDialog.SetSubMaxValue(TotalKeyframes);
    ProgressDialog.SubMessage("0/" + TotalKeyframes);
    
    var KeyframeStrings = [];
    var IdxStart = 0;
    var IdxEnd = 0;
    
    //Split all keyframes into separate substrings
    var bIsSplitting = true;
    var bHaveKeyframe = false;
    var StackLevel = 0;
    var KeyframesFound = 0;
    while(bIsSplitting === true)
    {
        ++IdxEnd;
        if(IdxEnd >= InString.length)
        {
            IdxEnd = InString.length;
            bIsSplitting = false;
        }
        
        //Stack match braces until a full keyframe is found
        if(InString[IdxEnd] === '{')
        {
            ++StackLevel;
        }
        else if(InString[IdxEnd] === '}')
        {
            --StackLevel;
            if(StackLevel === 0)
            {
                bHaveKeyframe = true;
            }
        }
        
        //Put the whole keyframe into a substring and push to the array
        if(bHaveKeyframe === true)
        {
            ++KeyframesFound;
            if(KeyframesFound % ProgressSteps == 0)
            {
                ProgressDialog.IncrementSub(ProgressSteps);
                ProgressDialog.SubMessage(KeyframesFound + "/" + TotalKeyframes);
            }
            
            //Increment the end to get the last closing brace
            ++IdxEnd;
            KeyframeStrings.push(InString.substring(IdxStart, IdxEnd));
            
            IdxStart = IdxEnd + 1;
            if(IdxStart >= InString.length)
            {
                break;
            }
        }
        
        bHaveKeyframe = false;
    }

    ProgressDialog.IncrementMain();
    return KeyframeStrings;
}

function GetKeyframes(KeyframeStrings, HeaderData)
{
    ProgressDialog.MainMessage("Parsing keyframes");
    ProgressDialog.SetSubMaxValue(KeyframeStrings.length);
    ProgressDialog.SubMessage("0/" + KeyframeStrings.length);
    
    var Keyframes = [];
    var PreviousKeyframe = GetNullKeyframe();
    
    for(var i = 0; i < KeyframeStrings.length;)
    {
        var NewKeyframe = GetKeyframeData(KeyframeStrings[i], HeaderData, PreviousKeyframe);
        PreviousKeyframe = NewKeyframe;
        Keyframes.push(NewKeyframe);
        
        ++i;
        if(i % ProgressSteps == 0)
        {
            ProgressDialog.IncrementSub(ProgressSteps);
            ProgressDialog.SubMessage(i + "/" + KeyframeStrings.length);
        }
    }

    ProgressDialog.IncrementMain();
    return Keyframes;
}

function GetKeyframeArrays(Keyframes, HeaderData)
{
    ProgressDialog.MainMessage("Compiling keyframes");
    ProgressDialog.SetSubMaxValue(Keyframes.length);
    ProgressDialog.SubMessage("0/" + Keyframes.length);
    
    var Arrays = [];
    
    //Time array
    Arrays.Time = [];
    
    //Camera arrays
    var CameraData = new Object();
    CameraData.FOV = [];
    CameraData.Location = BuildVectorArrays();
    CameraData.Rotation = BuildVectorArrays();
    Arrays.Camera = CameraData;
    
    //Ball arrays
    var BallData = new Object();
    BallData.Location = BuildVectorArrays();
    BallData.Rotation = BuildVectorArrays();
    Arrays.Ball = BallData;
    
    //Car arrays
    Arrays.Cars = [];
    for(var i = 0; i < HeaderData.CarsSeen.length; ++i)
    {
        var CarArray = new Object();
        CarArray.bIsNull  = [];
        CarArray.Location = BuildVectorArrays();
        CarArray.Rotation = BuildVectorArrays();
        
        Arrays.Cars.push(CarArray);
    }

    //Loop through all keyframes and add their data to Arrays
    for(var i = 0; i < Keyframes.length;)
    {
        var ThisKeyframe = Keyframes[i];
        
        //Time
        Arrays.Time.push(ThisKeyframe.Time.Time);
        
        //Camera
        Arrays.Camera.FOV.push(ThisKeyframe.Camera.FOV);
        MapVector(Arrays.Camera.Location, ThisKeyframe.Camera.Location);
        MapRotator(Arrays.Camera.Rotation, ThisKeyframe.Camera.Rotation);
        
        //Ball
        MapVector(Arrays.Ball.Location, ThisKeyframe.Ball.Location);
        MapRotator(Arrays.Ball.Rotation, ThisKeyframe.Ball.Rotation);
        
        //Cars
        for(var j = 0; j < HeaderData.CarsSeen.length; ++j)
        {
            Arrays.Cars[j].bIsNull.push(ThisKeyframe.Cars[j].bIsNull ? 0 : 100);
            MapVector(Arrays.Cars[j].Location, ThisKeyframe.Cars[j].Location);
            MapRotator(Arrays.Cars[j].Rotation, ThisKeyframe.Cars[j].Rotation);
        }
        
        ++i;
        if(i % ProgressSteps == 0)
        {
            ProgressDialog.IncrementSub(ProgressSteps);
            ProgressDialog.SubMessage(i + "/" + Keyframes.length);
        }
    }
    
    ProgressDialog.IncrementMain();
    return Arrays;
}

function ApplyKeyframes(Arrays, HeaderData)
{
    ProgressDialog.MainMessage("Applying keyframes");
    ProgressDialog.SetSubMaxValue(2);
    
    //Start an undo group so that all composition changes can be undone easily
    app.beginUndoGroup("CinematicsBuddyAE Import");
    
    //Create reference grids, camera, and other necessary objects
    ProgressDialog.SubMessage("Creating objects");
    var MyComp = app.project.activeItem;
    var Objects = CreateCompObjects(MyComp, HeaderData);
    var CameraLayer = Objects.CameraLayer;
    var BallLayer = Objects.BallLayer;
    var CarLayers = Objects.CarLayers;
    ProgressDialog.IncrementSub(1);
    
    //Begin applying the arrays
    ProgressDialog.SubMessage("Applying arrays");
    
    //Camera
    CameraLayer.property("Camera Options").property("Zoom").setValuesAtTimes(Arrays.Time, Arrays.Camera.FOV);
    ApplyVectorKeyframe(CameraLayer, Arrays.Time, Arrays.Camera.Location, true);
    ApplyVectorKeyframe(CameraLayer, Arrays.Time, Arrays.Camera.Rotation, false);
    
    //Ball
    ApplyVectorKeyframe(BallLayer, Arrays.Time, Arrays.Ball.Location, true);
    ApplyVectorKeyframe(BallLayer, Arrays.Time, Arrays.Ball.Rotation, false);
    
    //Cars
    for(var i = 0; i < HeaderData.CarsSeen.length; ++i)
    {
        var ThisCarLayer = CarLayers[i];
        var ThisCarKeyframes = Arrays.Cars[i];
        ThisCarLayer.property("Opacity").setValuesAtTimes(Arrays.Time, ThisCarKeyframes.bIsNull);
        ApplyVectorKeyframe(ThisCarLayer, Arrays.Time, ThisCarKeyframes.Location, true);
        ApplyVectorKeyframe(ThisCarLayer, Arrays.Time, ThisCarKeyframes.Rotation, false);
    }
    
    //Completed task
    ProgressDialog.IncrementSub(1);
    
    //End undo group
    app.endUndoGroup();
    ProgressDialog.IncrementMain();
}

function ApplyVectorKeyframe(TheLayer, TimeArray, TheVector, bLocationOrRotation)
{
    var TheType = bLocationOrRotation ? "Position" : "Rotation";
    
    TheLayer.property("Transform").property("X " + TheType).setValuesAtTimes(TimeArray, TheVector.X);
    TheLayer.property("Transform").property("Y " + TheType).setValuesAtTimes(TimeArray, TheVector.Y);
    TheLayer.property("Transform").property("Z " + TheType).setValuesAtTimes(TimeArray, TheVector.Z);
}
//


// UTILITY FUNCTIONS //
function RemoveWhitespace(InString)
{
    return InString.replace(/^\s+|\s+$/g,'');
}

function GetSplitHeaderLine(ThisLine)
{
    var SplitLine = ThisLine.split(":");
    
    var Output = new Object();
    Output.Label = SplitLine[0];
    Output.Data = RemoveWhitespace(SplitLine.slice(1, SplitLine.length).join());
    
    return Output;
}

function GetSplitKeyframeLine(ThisLine)
{
    var SplitLine = ThisLine.split(":");
    
    var Output = new Object();
    Output.Label = SplitLine[0];
    Output.Data = SplitLine.slice(1, SplitLine.length).join();
    
    return Output;
}

function GetEmptyVector()
{
    var Vector = new Object();
    Vector.X = 0;
    Vector.Y = 0;
    Vector.Z = 0;
    
    return Vector;
}

function GetEmptyRotator()
{
    var Rotator = new Object();
    
    var Rotation = new Object();
    Rotation.X = 0;
    Rotation.Y = 0;
    Rotation.Z = 0;
    
    var Offsets = new Object();
    Offsets.X = 0;
    Offsets.Y = 0;
    Offsets.Z = 0;
    
    Rotator.Rotation = Rotation;
    Rotator.Offsets  = Offsets;
    
    return Rotator;
}

function ParseVector(VectorString)
{    
    var VectorVals = VectorString.split(",");
    
    var Vector = new Object();
    Vector.X = parseFloat(VectorVals[1]) *  2.54;
    Vector.Y = parseFloat(VectorVals[2]) * -2.54;
    Vector.Z = parseFloat(VectorVals[0]) *  2.54;
    
    return Vector;
}

function ParseQuat(QuatString)
{
    //Converts quaternion WXYZ into Euler rotation XYZ
    //https://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToEuler/
    var QuatVals = QuatString.split(",");
    var qW = parseFloat(QuatVals[0]);
    var qX = parseFloat(QuatVals[1]);
    var qY = parseFloat(QuatVals[2]);
    var qZ = parseFloat(QuatVals[3]);
    
    //Pitch
    var H1 = (2 * qY * qW) - (2 * qX * qZ);
    var H2 = 1 - (2 * qY * qY) - (2 * qZ * qZ);
    var Pitch = Math.atan2(H1, H2);
    
    //Yaw - Clamped to [-1,1] so asin doesn't throw a NaN result
    var A1 = 2 * qX * qY;
    var A2 = 2 * qZ * qW;
    var Added = A1 + A2;
    if(Added < -1) { Added = -1; }
    if(Added >  1) { Added =  1; }
    var Yaw = Math.asin(Added);
    
    //Roll
    var B1 = (2 * qX * qW) - (2 * qY * qZ);
    var B2 = 1 - (2 * qX * qX) - (2 * qZ * qZ);
    var Roll = Math.atan2(B1, B2);
    
    //Convert from radians to degrees
    var RadToDeg = 180 / Math.PI;
    var NewPitch = Pitch * RadToDeg;
    var NewYaw   = Yaw   * RadToDeg;
    var NewRoll  = Roll  * RadToDeg;
    
    //Output the rotation - offsets defaulted to 0
    var Output = GetEmptyRotator();
    Output.Rotation.X = NewPitch * -1;
    Output.Rotation.Y = NewYaw;
    Output.Rotation.Z = NewRoll * -1;
    
    return Output;
}

function EulerFilter(PreviousRotation, IncomingRotation, bIgnorePreviousRotation)
{
    //PreviousRotation should not be taken into account
    if(!bShouldEulerFilter || bIgnorePreviousRotation)
    {
        return IncomingRotation;
    }

    // FOR NOW JUST RETURN IncomingRotation SO YOU CAN SEE IF ANYTHING BROKE //
    var OutputRotation = GetEmptyRotator();
    
    //Modify the incoming rotation value and the stored offsets
    OutputRotation.Rotation.X = FilterAxis(PreviousRotation.Rotation, IncomingRotation.Rotation, PreviousRotation.Offsets, 0);
    OutputRotation.Rotation.Y = FilterAxis(PreviousRotation.Rotation, IncomingRotation.Rotation, PreviousRotation.Offsets, 1);
    OutputRotation.Rotation.Z = FilterAxis(PreviousRotation.Rotation, IncomingRotation.Rotation, PreviousRotation.Offsets, 2);
    
    //Pass the newly modified offsets to the current rotation
    OutputRotation.Offsets = PreviousRotation.Offsets;

    return OutputRotation;
}

function FilterAxis(Previous, Incoming, Offsets, AxisNum)
{
    //ExtendScript won't modify a value by reference unless it is a struct, hence needing to pass in a rotation object
    if(AxisNum == 0)
    {
        Offsets.X += GetNewOffset(Previous.X, Incoming.X, Offsets.X);
        return Incoming.X + Offsets.X;
    }
    else if(AxisNum == 1)
    {
        Offsets.Y += GetNewOffset(Previous.Y, Incoming.Y, Offsets.Y);
        return Incoming.Y + Offsets.Y;
    }
    else if(AxisNum == 2)
    {
        Offsets.Z += GetNewOffset(Previous.Z, Incoming.Z, Offsets.Z);
        return Incoming.Z + Offsets.Z;
    }

    //How did you get here?
    return 0;
}

function GetNewOffset(PreviousVal, IncomingVal, OffsetVal)
{
    /*
        270 is chosen as the threshold because:
            - a change in 180 might be legitimate (i.e. new kickoff)
            - a change in 360 will rarely happen (i.e. 178 to -178 is a change of 356)
            - 270 is between the two and probably will cover most if not all cases
    */

    var ModifiedIncoming = IncomingVal + OffsetVal;
    var Difference = ModifiedIncoming - PreviousVal;
    var NewOffset = 0;
    
    if(Difference > 270.0)
    {
        NewOffset -= 360.0;
    }
    else if(Difference < -270.0)
    {
        NewOffset += 360.0;
    }

    return NewOffset;
}

function BuildVectorArrays()
{
    var Output = new Object();
    
    Output.X = [];
    Output.Y = [];
    Output.Z = [];
    
    return Output;
}

function MapVector(OutArray, InVector)
{
    OutArray.X.push(InVector.X);
    OutArray.Y.push(InVector.Y);
    OutArray.Z.push(InVector.Z);
}

function MapRotator(OutArray, InRotator)
{
    OutArray.X.push(InRotator.Rotation.X);
    OutArray.Y.push(InRotator.Rotation.Y);
    OutArray.Z.push(InRotator.Rotation.Z);
}
//

// HEADER PARSING //
function GetRecordingMetadata(HeaderData)
{
    var RecordingMetadata = new Object();
    RecordingMetadata.Version    = "";
    RecordingMetadata.Camera     = "";
    RecordingMetadata.AverageFPS = -1.0;
    RecordingMetadata.Frames     = -1;
    RecordingMetadata.Duration   = -1.0;
    
    //Skip the first line "RECORDING METADATA"
    ++HeaderData.CurrentLine;

    //Loop through all the metadata lines until an empty line is found
    while(HeaderData.CurrentLine < HeaderData.Lines.length)
    {
        var ThisLine = HeaderData.Lines[HeaderData.CurrentLine];
        ++HeaderData.CurrentLine;
        
        if(ThisLine === "")
        {
            break;
        }
        
        //Get the individual data points
        var SplitLine = GetSplitHeaderLine(ThisLine);
        if(SplitLine.Label.indexOf("Version") > -1)          { RecordingMetadata.Version    = SplitLine.Data;             }
        else if(SplitLine.Label.indexOf("Camera") > -1)      { RecordingMetadata.Camera     = SplitLine.Data;             }
        else if(SplitLine.Label.indexOf("Average FPS") > -1) { RecordingMetadata.AverageFPS = parseFloat(SplitLine.Data); }
        else if(SplitLine.Label.indexOf("Frames") > -1)      { RecordingMetadata.Frames     = parseInt(SplitLine.Data);   }
        else if(SplitLine.Label.indexOf("Duration") > -1)    { RecordingMetadata.Duration   = parseFloat(SplitLine.Data); }
    }

    return RecordingMetadata;
}

function GetReplayMetadata(HeaderData)
{
    var ReplayMetadata = new Object();
    ReplayMetadata.Name    = "";
    ReplayMetadata.ID      = "";
    ReplayMetadata.TheDate = "";
    ReplayMetadata.FPS     = -1;
    ReplayMetadata.Frames  = -1;
    
    //Skip the first line "REPLAY METADATA"
    ++HeaderData.CurrentLine;
    
    //Loop through all the metadata lines until an empty line is found
    while(HeaderData.CurrentLine < HeaderData.Lines.length)
    {
        var ThisLine = HeaderData.Lines[HeaderData.CurrentLine];
        ++HeaderData.CurrentLine;
        
        if(ThisLine === "")
        {
            break;
        }
        
        //Get the individual data points
        var SplitLine = GetSplitHeaderLine(ThisLine);
        if(SplitLine.Label.indexOf("Name") > -1)        { ReplayMetadata.Name    = SplitLine.Data;           }
        else if(SplitLine.Label.indexOf("ID") > -1)     { ReplayMetadata.ID      = SplitLine.Data;           }
        else if(SplitLine.Label.indexOf("Date") > -1)   { ReplayMetadata.TheDate = SplitLine.Data;           }
        else if(SplitLine.Label.indexOf("FPS") > -1)    { ReplayMetadata.FPS     = parseInt(SplitLine.Data); }
        else if(SplitLine.Label.indexOf("Frames") > -1) { ReplayMetadata.Frames  = parseInt(SplitLine.Data); }
    }

    return ReplayMetadata;
}

function GetCarsSeen(HeaderData)
{
    var CarsSeen = [];
    
    //Skip the first line "CARS SEEN" and the opening brace
    HeaderData.CurrentLine += 2;
    
    //Loop through all the cars seen lines until an empty line is found
    while(HeaderData.CurrentLine < HeaderData.Lines.length)
    {
        //Trim the whitespace off the front and check if the group is done
        var ThisLine = RemoveWhitespace(HeaderData.Lines[HeaderData.CurrentLine]);
        ++HeaderData.CurrentLine;
        if(ThisLine == "}")
        {
            break;
        }
        
        //Split the line by :
        var SplitLine = GetSplitKeyframeLine(ThisLine);
        
        //Get information for the next car
        var CarSeenIndex = SplitLine.Label;
        var CarSeen = GetCarSeen(HeaderData, CarSeenIndex);
        CarsSeen.push(CarSeen);
    }

    return CarsSeen;
}

function GetCarSeen(HeaderData, CarSeenIndex)
{
    var CarSeen = new Object();
    CarSeen.Index = -1;
    CarSeen.Name = "UNNAMED CAR";
    CarSeen.ID = "NO ID";
    CarSeen.Body = -1;
    CarSeen.FrontWheelRadius = -1.0;
    CarSeen.BackWheelRadius = -1.0;
    
    //Skip the car index since that was retrieved in the parent function
    ++HeaderData.CurrentLine;
    
    while(true)
    {
        //Trim the whitespace off the front and check if the group is done
        var ThisLine = RemoveWhitespace(HeaderData.Lines[HeaderData.CurrentLine]);
        ++HeaderData.CurrentLine;
        if(ThisLine == "}")
        {
            break;
        }
        
        //Split the line by :
        var SplitLine = GetSplitKeyframeLine(ThisLine);
        
        //Get all car seen data
        if(SplitLine.Label == "Body")                    { CarSeen.Body = parseInt(SplitLine.Data);               }
        else if(SplitLine.Label == "ID")                 { CarSeen.ID   = SplitLine.Data;                         }
        else if(SplitLine.Label == "Front Wheel Radius") { CarSeen.FrontWheelRadius = parseFloat(SplitLine.Data); }
        else if(SplitLine.Label == "Back Wheel Radius")  { CarSeen.BackWheelRadius  = parseFloat(SplitLine.Data); }
    }
    
    //Fill in last values
    CarSeen.Index = CarSeenIndex;
    CarSeen.Name = "Car " + CarSeenIndex + ": " + CarSeen.ID + " Null Object";
    
    return CarSeen;
}
//

// KEYFRAME PARSING //
function GetNullKeyframe()
{
    var Keyframe = new Object();
    
    Keyframe.bIsNullFrame = true;
    Keyframe.FrameNumber = -1;
    Keyframe.Ball = new Object();
    Keyframe.Camera = new Object();
    Keyframe.Cars = [];
    Keyframe.Time = new Object();
    Keyframe.CurrentLine = 0;
    
    return Keyframe;
}
function GetKeyframeData(KeyframeString, HeaderData, PreviousKeyframe)
{
    var Keyframe = GetNullKeyframe();
     Keyframe.bIsNullFrame = false;
    
    //Split keyframe into an array of its individual lines
    var Lines = KeyframeString.split("\n");
    var StackLevel = 0;
    
    //Loop through lines
    while(Keyframe.CurrentLine < Lines.length)
    {
        //Trim the whitespace off the front and check if the keyframe is done
        var ThisLine = RemoveWhitespace(Lines[Keyframe.CurrentLine]);
        ++Keyframe.CurrentLine;
        if(ThisLine == "}")
        {
            break;
        }
        
        //Split the line by :
        var SplitLine = GetSplitKeyframeLine(ThisLine);
        
        //Choose the right data gathering function based on the group label
        if(SplitLine.Data == "{")
        {
            switch(StackLevel)
            {
                case 0:
                {
                    Keyframe.FrameNumber = parseInt(SplitLine.Label);
                    ++StackLevel;
                    break;
                }
                case 1:
                {
                    if(SplitLine.Label == "B")       { Keyframe.Ball = GetBallData(Keyframe, Lines, PreviousKeyframe);             }
                    else if(SplitLine.Label == "CM") { Keyframe.Camera = GetCameraData(Keyframe, Lines, PreviousKeyframe);         }
                    else if(SplitLine.Label == "CR") { Keyframe.Cars = GetCarsData(Keyframe, Lines, HeaderData, PreviousKeyframe); }
                    else if(SplitLine.Label == "T")  { Keyframe.Time = GetTimeData(Keyframe, Lines);                               }
                    break;
                }
            }
        }
    }
    
    return Keyframe;
}

function GetBallData(Keyframe, Lines, PreviousKeyframe)
{
    var BallData = new Object();
    BallData.Location = GetEmptyVector();
    BallData.Rotation = GetEmptyRotator();
    
    while(true)
    {
        //Trim the whitespace off the front and check if the group is done
        var ThisLine = RemoveWhitespace(Lines[Keyframe.CurrentLine]);
        ++Keyframe.CurrentLine;
        if(ThisLine == "}")
        {
            break;
        }
        
        //Split the line by :
        var SplitLine = GetSplitKeyframeLine(ThisLine);
        
        //Get location and rotation
        if(SplitLine.Label == "L") { BallData.Location = ParseVector(SplitLine.Data); }
        else if(SplitLine.Label == "R")
        {
            var NewRotation = ParseQuat(SplitLine.Data);
            
            if(!PreviousKeyframe.bIsNullFrame)
            {
                var PreviousRotation = PreviousKeyframe.Ball.Rotation;
                BallData.Rotation = EulerFilter(PreviousRotation, NewRotation, PreviousKeyframe.bIsNullFrame);
            }
            else
            {
                BallData.Rotation = NewRotation;
            }
        }
    }
    
    return BallData;
}

function GetCameraData(Keyframe, Lines, PreviousKeyframe)
{
    var CameraData = new Object();
    CameraData.Location = GetEmptyVector();
    CameraData.Rotation = GetEmptyRotator();
    CameraData.FOV = 0;
    
    while(true)
    {
        //Trim the whitespace off the front and check if the group is done
        var ThisLine = RemoveWhitespace(Lines[Keyframe.CurrentLine]);
        ++Keyframe.CurrentLine;
        if(ThisLine == "}")
        {
            break;
        }
        
        //Split the line by :
        var SplitLine = GetSplitKeyframeLine(ThisLine);
        
        //Get location, rotation, and FOV
        if(SplitLine.Label == "L")      { CameraData.Location = ParseVector(SplitLine.Data); }
        else if(SplitLine.Label == "F") { CameraData.FOV = GetZoom(SplitLine.Data);          }
        else if(SplitLine.Label == "R")
        {
            var NewRotation = ParseQuat(SplitLine.Data);
            
            if(!PreviousKeyframe.bIsNullFrame)
            {
                var PreviousRotation = PreviousKeyframe.Camera.Rotation;
                CameraData.Rotation = EulerFilter(PreviousRotation, NewRotation, PreviousKeyframe.bIsNullFrame);
            }
            else
            {
                CameraData.Rotation = NewRotation;
            }
        }
    }
    
    return CameraData;
}

function GetZoom(InFOV)
{
    var TheComp = app.project.activeItem;
    var AspectRatio = TheComp.width / TheComp.height;
    var FOV = parseFloat(InFOV);
    var FOVRads = (FOV / 2) * (Math.PI / 180);
    var Zoom = TheComp.width / (2 * Math.tan(FOVRads));
    
    return Zoom;
}

function GetTimeData(Keyframe, Lines)
{
    var TimeData = new Object();
    TimeData.ReplayFrame = 0;
    TimeData.Time = 0.0;
    
    while(true)
    {
        //Trim the whitespace off the front and check if the group is done
        var ThisLine = RemoveWhitespace(Lines[Keyframe.CurrentLine]);
        ++Keyframe.CurrentLine;
        if(ThisLine == "}")
        {
            break;
        }
        
        //Split the line by :
        var SplitLine = GetSplitKeyframeLine(ThisLine);
        
        //Get replay frame and time
        if(SplitLine.Label == "RF")     { TimeData.ReplayFrame = parseInt(SplitLine.Data); }
        else if(SplitLine.Label == "T") { TimeData.Time = parseFloat(SplitLine.Data);      }
    }
    
    return TimeData;
}

function GetCarsData(Keyframe, Lines, HeaderData, PreviousKeyframe)
{
    var Cars = GetNullCars(HeaderData.CarsSeen.length);
    
    while(true)
    {
        //Trim the whitespace off the front and check if the group is done
        var ThisLine = RemoveWhitespace(Lines[Keyframe.CurrentLine]);
        ++Keyframe.CurrentLine;
        if(ThisLine == "}")
        {
            break;
        }
        
        //Split the line by :
        var SplitLine = GetSplitKeyframeLine(ThisLine);
        
        //Get information for the next car
        var CarSeenIndex = SplitLine.Label;
        var Car = GetCarData(Keyframe, Lines, PreviousKeyframe, CarSeenIndex);
        Car.CarSeenIndex = CarSeenIndex;
        Cars[CarSeenIndex] = Car;
    }

    return Cars;
}

function GetNullCars(NumCars)
{
    var NullCars = [];
    
    for(var i = 0; i < NumCars; ++i)
    {
        var Car = new Object();
        Car.bIsNull = true;
        Car.CarSeenIndex = i;
        Car.bBoosting = false;
        Car.Location = GetEmptyVector();
        Car.Rotation = GetEmptyRotator();
        Car.Wheels = GetNullWheels(4);
        
        NullCars.push(Car);
    }

    return NullCars;
}

function GetNullWheels(NumWheels)
{
    var NullWheels = [];
    
    for(var i = 0; i < NumWheels; ++i)
    {
        var Wheel = new Object();
        Wheel.SteerAmount        = 0;
        Wheel.SuspensionDistance = 0;
        Wheel.SpinSpeed          = 0;
        
        NullWheels.push(Wheel);
    }
    
    return NullWheels;
}

function GetCarData(Keyframe, Lines, PreviousKeyframe, CarSeenIndex)
{
    var Car = new Object();
    Car.bIsNull = false;
    Car.CarSeenIndex = -1;
    Car.bBoosting = false;
    Car.Location = GetEmptyVector();
    Car.Rotation = GetEmptyRotator();
    Car.Wheels = [];
    
    //Skip the car index since that was retrieved in the parent function
    ++Keyframe.CurrentLine;
    
    while(true)
    {
        //Trim the whitespace off the front and check if the group is done
        var ThisLine = RemoveWhitespace(Lines[Keyframe.CurrentLine]);
        ++Keyframe.CurrentLine;
        if(ThisLine == "}")
        {
            break;
        }
        
        //Split the line by :
        var SplitLine = GetSplitKeyframeLine(ThisLine);
        
        //Get all car data
        if(SplitLine.Label == "B")      { Car.bBoosting = parseInt(SplitLine.Data);       }
        else if(SplitLine.Label == "L") { Car.Location  = ParseVector(SplitLine.Data);    }
        else if(SplitLine.Label == "W") { Car.Wheels    = GetWheelsData(Keyframe, Lines); }
        else if(SplitLine.Label == "R")
        {
            var NewRotation = ParseQuat(SplitLine.Data);
            
            if(!PreviousKeyframe.bIsNullFrame)
            {
                var PreviousRotation = PreviousKeyframe.Cars[CarSeenIndex].Rotation;
                Car.Rotation = EulerFilter(PreviousRotation, NewRotation);
            }
            else
            {
                Car.Rotation = NewRotation;
            }
        }
    }
    
    return Car;
}

function GetWheelsData(Keyframe, Lines)
{
    var Wheels = [];
    
    while(true)
    {
        //Trim the whitespace off the front and check if the group is done
        var ThisLine = RemoveWhitespace(Lines[Keyframe.CurrentLine]);
        ++Keyframe.CurrentLine;
        if(ThisLine == "]")
        {
            break;
        }
    
        //Get information for the next wheel
        Wheels.push(GetWheelData(Keyframe, Lines));
    }
        
    return Wheels;    
}

function GetWheelData(Keyframe, Lines)
{
    var Wheel = new Object();
    Wheel.SteerAmount        = 0;
    Wheel.SuspensionDistance = 0;
    Wheel.SpinSpeed          = 0;
    
    //Skip the wheel index
    ++Keyframe.CurrentLine;
    
    while(true)
    {
        //Trim the whitespace off the front and check if the group is done
        var ThisLine = RemoveWhitespace(Lines[Keyframe.CurrentLine]);
        ++Keyframe.CurrentLine;
        if(ThisLine == "}")
        {
            break;
        }
        
        //Split the line by :
        var SplitLine = GetSplitKeyframeLine(ThisLine);
        
        //Get all wheel data
        if(SplitLine.Label == "SA")      { Wheel.SteerAmount        = parseFloat(SplitLine.Data); }
        else if(SplitLine.Label == "SD") { Wheel.SuspensionDistance = parseFloat(SplitLine.Data); }
        else if(SplitLine.Label == "SS") { Wheel.SpinSpeed          = parseFloat(SplitLine.Data); }
    }
    
    return Wheel;
}
//


// COMPOSITION OBJECT CREATION //
function CreateCompObjects(MyComp, HeaderData)
{
    //Objects are added to layers in reverse order of what's seen here
    //Camera should be created last so it will be on top
    var Objects = new Object();
    
    //Grids to approximate field
    CreateGrids(MyComp, Objects);
    
    //Labels in goals
    Objects.BlueGoalLabel = CreateBlueGoalLabel(MyComp);
    Objects.OrangeGoalLabel = CreateOrangeGoalLabel(MyComp);
    
    //Car null objects
    Objects.CarLayers = CreateCars(MyComp, HeaderData);
    
    //Ball null object
    Objects.BallLayer = CreateBall(MyComp);
    
    //Camera
    Objects.CameraLayer = CreateCamera(MyComp, HeaderData);
    
    return Objects;
}

function CreateGrids(MyComp, Objects)
{
    //Floor
    var FloorLayer = CreateGrid(MyComp, "Floor");
    FloorLayer.property("Position").setValue([0, 0, 0]);
    FloorLayer.property("Scale").setValue([1024 * 2.54, 819.2 * 2.54, 100]);
    FloorLayer.property("X Rotation").setValue(-90);
    
    //Ceiling
    var CeilingLayer = CreateGrid(MyComp, "Ceiling");
    CeilingLayer.property("Position").setValue([0, 2044 * -2.54, 0]);
    CeilingLayer.property("Scale").setValue([1024 * 2.54, 819.2 * 2.54, 100]);
    CeilingLayer.property("X Rotation").setValue(-90);
    
    //Positive X Wall
    var LeftWallLayer = CreateGrid(MyComp, "Left Wall");
    LeftWallLayer.property("Position").setValue([0, 2044 * -2.54 / 2, 4096 * 2.54]);
    LeftWallLayer.property("Scale").setValue([1024 * 2.54, 204.4 * 2.54, 100]);
    LeftWallLayer.property("Effects").property("ADBE Grid").property("Height").setValue(80);
    
    //Negative X Wall
    var RightWallLayer = CreateGrid(MyComp, "Right Wall");
    RightWallLayer.property("Position").setValue([0, 2044 * -2.54 / 2, 4096 * -2.54]);
    RightWallLayer.property("Scale").setValue([1024 * 2.54, 204.4 * 2.54, 100]);
    RightWallLayer.property("Effects").property("ADBE Grid").property("Height").setValue(80);
    
    //Blue goal wall
    var BlueWallLayer = CreateGrid(MyComp, "Blue Wall");
    BlueWallLayer.property("Position").setValue([-5120 * 2.54, 2044 * -2.54 / 2, 0]);
    BlueWallLayer.property("Scale").setValue([819.2 * 2.54, 204.4 * 2.54, 100]);
    BlueWallLayer.property("Y Rotation").setValue(90);
    BlueWallLayer.property("Effects").property("ADBE Grid").property("Width").setValue(22);
    BlueWallLayer.property("Effects").property("ADBE Grid").property("Height").setValue(80);
    BlueWallLayer.property("Effects").property("ADBE Ramp").property("End Color").setValue(BlueColor);
    
    //Orange goal wall
    var OrangeWallLayer = CreateGrid(MyComp, "Orange Wall");
    OrangeWallLayer.property("Position").setValue([5120 * 2.54, 2044 * -2.54 / 2, 0]);
    OrangeWallLayer.property("Scale").setValue([819.2 * 2.54, 204.4 * 2.54, 100]);
    OrangeWallLayer.property("Y Rotation").setValue(90);
    OrangeWallLayer.property("Effects").property("ADBE Grid").property("Width").setValue(22);
    OrangeWallLayer.property("Effects").property("ADBE Grid").property("Height").setValue(80);
    OrangeWallLayer.property("Effects").property("ADBE Ramp").property("Start Color").setValue(OrangeColor);
    
    //Add all grids to objects collection
    Objects.FloorLayer = FloorLayer;
    Objects.CeilingLayer = CeilingLayer;
    Objects.LeftWallLayer = LeftWallLayer;
    Objects.RightWallLayer = RightWallLayer;
    Objects.BlueWallLayer = BlueWallLayer;
    Objects.OrangeWallLayer = OrangeWallLayer;
}

function CreateGrid(MyComp, GridName)
{
    var NewGrid = MyComp.layers.addSolid([1,1,1], GridName, 1000, 1000, 1);
    NewGrid.guideLayer = true;
    NewGrid.threeDLayer = true;
    
    //Gradient ramp effect
    var GradientEffect = NewGrid.property("Effects").addProperty("ADBE Ramp");
    GradientEffect.property("Start of Ramp").setValue([0, 500]);
    GradientEffect.property("End of Ramp").setValue([1000, 500]);
    GradientEffect.property("Start Color").setValue(BlueColor);
    GradientEffect.property("End Color").setValue(OrangeColor);
    
    //Grid effect
    var GridEffect = NewGrid.property("Effects").addProperty("ADBE Grid");
    GridEffect.property("Size From").setValue(3);
    GridEffect.property("Width").setValue(16);
    GridEffect.property("Height").setValue(20);
    GridEffect.property("Border").setValue(2);
    GridEffect.property("Blending Mode").setValue(3);
    
    return NewGrid;
}

function CreateCamera(MyComp, HeaderData)
{
    var CameraName = "UNNAMED CAMERA";
    if(HeaderData.RecordingMetadata.Camera != "")
    {
        CameraName = HeaderData.RecordingMetadata.Camera;
    }
    
    var CameraLayer = MyComp.layers.addCamera(CameraName, [MyComp.width / 2, MyComp.height / 2]);
    CameraLayer.autoOrient = AutoOrientType.NO_AUTO_ORIENT;
    CameraLayer.property("Position").dimensionsSeparated = true;
    
    return CameraLayer;
}

function CreateBall(MyComp)
{
    var BallLayer = MyComp.layers.addNull();
    BallLayer.source.name = "Ball Null Object";
    BallLayer.threeDLayer = true;
    BallLayer.property("Position").dimensionsSeparated = true;
    
    return BallLayer;
}

function CreateCars(MyComp, HeaderData)
{
    var CarLayers = [];
    
    for(var i = 0; i < HeaderData.CarsSeen.length; ++i)
    {
        CarLayers.push(CreateCar(MyComp, HeaderData.CarsSeen[i]));
    }

    return CarLayers;
}

function CreateCar(MyComp, CarSeen)
{
    var ThisCar = MyComp.layers.addNull();
    ThisCar.source.name = CarSeen.Name;
    ThisCar.threeDLayer = true;
    ThisCar.property("Position").dimensionsSeparated = true;
    
    return ThisCar;
}

function CreateBlueGoalLabel(MyComp)
{
    var BlueGoalLabel = MyComp.layers.addText("Blue Goal");
    BlueGoalLabel.guideLayer = true;
    BlueGoalLabel.threeDLayer = true;
    BlueGoalLabel.property("Position").setValue([-5120 * 2.54, -600, 0]);
    BlueGoalLabel.property("Y Rotation").setValue(-90);
    var TextDocument = BlueGoalLabel.property("Source Text").value;
    TextDocument.font = "Arial-BoldMT";
    TextDocument.fontSize = 1000;
    TextDocument.fillColor = BlueColor;
    TextDocument.strokeColor = [0, 0, 0];
    TextDocument.strokeWidth = 50;
    BlueGoalLabel.property("Source Text").setValue(TextDocument);
    
    return BlueGoalLabel;
}

function CreateOrangeGoalLabel(MyComp)
{
    var OrangeGoalLabel = MyComp.layers.addText("Orange Goal");
    OrangeGoalLabel.guideLayer = true;
    OrangeGoalLabel.threeDLayer = true;
    OrangeGoalLabel.property("Position").setValue([5120 * 2.54, -600, 0]);
    OrangeGoalLabel.property("Y Rotation").setValue(90);
    var TextDocument = OrangeGoalLabel.property("Source Text").value;
    TextDocument.font = "Arial-BoldMT";
    TextDocument.fontSize = 750;
    TextDocument.fillColor = OrangeColor;
    TextDocument.strokeColor = [0, 0, 0];
    TextDocument.strokeWidth = 50;
    OrangeGoalLabel.property("Source Text").setValue(TextDocument);
    
    return OrangeGoalLabel;
}

function RemoveCompObjects(Objects)
{
    Objects.CameraLayer.remove();
    Objects.BallLayer.remove();
    Objects.FloorLayer.remove();
    Objects.CeilingLayer.remove();
    Objects.LeftWallLayer.remove();
    Objects.RightWallLayer.remove();
    Objects.BlueWallLayer.remove();
    Objects.OrangeWallLayer.remove();
    Objects.BlueGoalLabel.remove();
    Objects.OrangeGoalLabel.remove();
    
    for(var i = 0; i < Objects.CarLayers.length; ++i)
    {
        Objects.CarLayers[i].remove();
    }
}
//
