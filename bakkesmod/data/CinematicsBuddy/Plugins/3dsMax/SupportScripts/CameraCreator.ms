-- CameraCreator creates a camera with the "Sync Shift" modifier

function CreateCamera CameraName = 
(
	local TheCamera = FreeCamera name:CameraName
	
	-- Add custom attributes
	AddModifier TheCamera (EmptyModifier())
	local TheModifier = TheCamera.modifiers[1]
	TheModifier.name = "Sync Shift"
	SyncShiftModifier = attributes SyncShiftAttributes
	(
		-- Sync Shift rollout
		parameters syncshiftparams rollout:ro_syncshift
		(
			ShiftAmount type:#float ui:SpinnerShiftAmount
		)
		rollout ro_syncshift "Sync Shift"
		(
			local    ApplyShiftTooltip = "This modifier lets you shift the keyframes in time so you can sync additional cameras to the main camera.\nShift Amount is measured in seconds."
			label    LabelShiftAmount "Shift Amount (Seconds)" align:#center
			spinner  SpinnerShiftAmount "" width:65 range:[-1000,1000,0] pos:[15,28] type:#float
			button   ButtonApplyShift "Apply" width:65 pos:[85,25] tooltip:ApplyShiftTooltip
			
			on ButtonApplyShift pressed do
			(
				-- Since this modifier will only be visible if only this camera is selected, this line should be fine
				local ThisCamera = selection[1]
				
				-- Get shift amount as a factor of frames (60 fps)
				local FinalShiftAmount = SpinnerShiftAmount.value * 60
				
				undo "Camera Shift" on
				(
					MoveKeys ThisCamera.Position.X_Position.Controller FinalShiftAmount
					MoveKeys ThisCamera.Position.Y_Position.Controller FinalShiftAmount
					MoveKeys ThisCamera.Position.Z_Position.Controller FinalShiftAmount
					MoveKeys ThisCamera.Rotation.X_Rotation.Controller FinalShiftAmount
					MoveKeys ThisCamera.Rotation.Y_Rotation.Controller FinalShiftAmount
					MoveKeys ThisCamera.Rotation.Z_Rotation.Controller FinalShiftAmount
					MoveKeys ThisCamera.FOV.Controller FinalShiftAmount
				)
				
				SpinnerShiftAmount.value = 0
			)
		)
	)
	CustAttributes.Add TheModifier SyncShiftModifier
	
	return TheCamera
)
