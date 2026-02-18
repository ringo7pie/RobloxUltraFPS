-- RobotR15 Controller
-- E: mount/dismount, WASD: move, Shift: sprint, Space: jump

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CONTROL_EVENT_NAME = "MechGolemControlEvent"
local MOUNT_KEY = Enum.KeyCode.E
local MOUNT_DISTANCE = 10

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local function resolveMechModel()
	local direct = workspace:FindFirstChild("RobotR15")
	if direct and direct:IsA("Model") then
		return direct
	end

	local vehicles = workspace:FindFirstChild("Vehicles")
	if vehicles then
		local inVehicles = vehicles:FindFirstChild("RobotR15")
		if inVehicles and inVehicles:IsA("Model") then
			return inVehicles
		end
	end

	return nil
end

local mechGolem = resolveMechModel()
if not mechGolem then
	warn("RobotR15 not found in Workspace.")
	return
end

local mechHumanoid = mechGolem:FindFirstChildOfClass("Humanoid")
local mechRootPart = mechGolem:FindFirstChild("HumanoidRootPart")
if not mechHumanoid or not mechRootPart then
	warn("RobotR15 is missing Humanoid or HumanoidRootPart.")
	return
end

local controlEvent = ReplicatedStorage:WaitForChild(CONTROL_EVENT_NAME)
if not controlEvent:IsA("RemoteEvent") then
	warn(CONTROL_EVENT_NAME .. " is not a RemoteEvent.")
	return
end

local isRiding = false
local camera = workspace.CurrentCamera
local originalCameraSubject = camera.CameraSubject
local originalCameraType = camera.CameraType
local lastMoveDirection = Vector3.new(0, 0, 0)
local lastSprintState = false
local hasSentMove = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MechGolemUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mountPrompt = Instance.new("TextLabel")
mountPrompt.Name = "MountPrompt"
mountPrompt.Size = UDim2.fromOffset(300, 46)
mountPrompt.Position = UDim2.new(0.5, -150, 0.8, 0)
mountPrompt.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mountPrompt.TextColor3 = Color3.fromRGB(255, 255, 255)
mountPrompt.Text = "E: Ride RobotR15"
mountPrompt.TextScaled = true
mountPrompt.Font = Enum.Font.GothamBold
mountPrompt.Visible = false
mountPrompt.Parent = screenGui

local function showPrompt(visible)
	mountPrompt.Visible = visible
end

local function setLocalCharacterHidden(hidden)
	local transparency = hidden and 1 or 0
	for _, desc in character:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.LocalTransparencyModifier = transparency
		end
	end
end

local function isNearMech()
	return (humanoidRootPart.Position - mechRootPart.Position).Magnitude <= MOUNT_DISTANCE
end

local function getInputDirection()
	local x = 0
	local z = 0

	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		x -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		x += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		z -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		z += 1
	end

	local direction = Vector3.new(x, 0, z)
	if direction.Magnitude > 1 then
		direction = direction.Unit
	end
	return direction
end

local function toWorldDirection(localDirection)
	if localDirection.Magnitude == 0 then
		return Vector3.zero
	end

	local cameraCF = camera.CFrame
	local forward = Vector3.new(cameraCF.LookVector.X, 0, cameraCF.LookVector.Z)
	local right = Vector3.new(cameraCF.RightVector.X, 0, cameraCF.RightVector.Z)

	if forward.Magnitude < 0.001 or right.Magnitude < 0.001 then
		return Vector3.new(localDirection.X, 0, -localDirection.Z)
	end

	forward = forward.Unit
	right = right.Unit

	local worldDirection = (right * localDirection.X) + (forward * -localDirection.Z)
	if worldDirection.Magnitude > 1 then
		worldDirection = worldDirection.Unit
	end

	return worldDirection
end

local function isSprinting()
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
end

local function updateRidingMovement()
	if not isRiding then
		return
	end

	local localDirection = getInputDirection()
	local worldDirection = toWorldDirection(localDirection)
	local sprinting = isSprinting()

	if not hasSentMove or (worldDirection - lastMoveDirection).Magnitude > 0.01 or sprinting ~= lastSprintState then
		controlEvent:FireServer("Move", worldDirection, sprinting)
		lastMoveDirection = worldDirection
		lastSprintState = sprinting
		hasSentMove = true
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == MOUNT_KEY then
		if isRiding or isNearMech() then
			controlEvent:FireServer("ToggleMount")
		end
		return
	end

	if isRiding and input.KeyCode == Enum.KeyCode.Space then
		controlEvent:FireServer("Jump")
	end
end)

controlEvent.OnClientEvent:Connect(function(action, mounted)
	if action ~= "Mounted" then
		return
	end

	if mounted then
		isRiding = true
		showPrompt(false)
		hasSentMove = false
		lastMoveDirection = Vector3.zero
		lastSprintState = false

		originalCameraSubject = camera.CameraSubject
		originalCameraType = camera.CameraType
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = mechHumanoid
		setLocalCharacterHidden(true)
	else
		isRiding = false
		showPrompt(false)
		hasSentMove = false
		lastMoveDirection = Vector3.zero
		lastSprintState = false

		if humanoid and humanoid.Parent then
			camera.CameraSubject = humanoid
		else
			camera.CameraSubject = originalCameraSubject
		end
		camera.CameraType = originalCameraType
		setLocalCharacterHidden(false)
	end
end)

RunService.RenderStepped:Connect(function()
	if isRiding then
		updateRidingMovement()
	else
		showPrompt(isNearMech())
	end
end)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	setLocalCharacterHidden(false)
	isRiding = false
	hasSentMove = false
	lastMoveDirection = Vector3.zero
	lastSprintState = false
end)
