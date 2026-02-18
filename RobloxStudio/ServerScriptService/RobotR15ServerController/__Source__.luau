-- RobotR15 server controller
-- Owns ride state, movement, sprint, jump, and player visibility while mounted.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CONTROL_EVENT_NAME = "MechGolemControlEvent"
local MOUNT_DISTANCE = 10
local MOUNT_HEIGHT_OFFSET = 5
local DISMOUNT_SIDE_OFFSET = 6
local WALK_SPEED = 20
local SPRINT_SPEED = 36
local JUMP_POWER = 80

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

local controlEvent = ReplicatedStorage:FindFirstChild(CONTROL_EVENT_NAME)
if controlEvent and not controlEvent:IsA("RemoteEvent") then
	controlEvent:Destroy()
	controlEvent = nil
end
if not controlEvent then
	controlEvent = Instance.new("RemoteEvent")
	controlEvent.Name = CONTROL_EVENT_NAME
	controlEvent.Parent = ReplicatedStorage
end

local currentRider = nil
local riderCharacter = nil
local riderHumanoid = nil
local riderRootPart = nil
local riderWeld = nil
local riderDiedConnection = nil
local riderPartStates = {}
local riderMoveDirection = Vector3.zero
local riderSprint = false
local jumpPulseId = 0

local function fireMountedState(player, mounted)
	controlEvent:FireClient(player, "Mounted", mounted)
end

local function pulseJump()
	if mechHumanoid.Health <= 0 then
		return
	end

	-- Force a one-shot jump pulse every time Space is pressed.
	jumpPulseId += 1
	local thisPulse = jumpPulseId
	mechHumanoid.Jump = false
	mechHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	mechHumanoid.Jump = true

	task.delay(0.1, function()
		if thisPulse == jumpPulseId and mechHumanoid.Parent then
			mechHumanoid.Jump = false
		end
	end)
end

local function setCharacterHidden(character, hidden)
	for _, desc in character:GetDescendants() do
		if desc:IsA("BasePart") then
			if hidden then
				riderPartStates[desc] = {
					Transparency = desc.Transparency,
					CanCollide = desc.CanCollide,
				}
				desc.Transparency = 1
				desc.CanCollide = false
			else
				local oldState = riderPartStates[desc]
				if oldState then
					desc.Transparency = oldState.Transparency
					desc.CanCollide = oldState.CanCollide
				else
					desc.Transparency = 0
				end
			end
		end
	end

	if not hidden then
		table.clear(riderPartStates)
	end
end

local function clearRider(sendClientUpdate)
	local previousRider = currentRider

	if riderWeld then
		riderWeld:Destroy()
		riderWeld = nil
	end

	if riderDiedConnection then
		riderDiedConnection:Disconnect()
		riderDiedConnection = nil
	end

	if riderHumanoid and riderHumanoid.Parent then
		riderHumanoid.PlatformStand = false
		riderHumanoid.AutoRotate = true
	end

	if riderCharacter and riderCharacter.Parent then
		setCharacterHidden(riderCharacter, false)
	end

	if riderRootPart and riderRootPart.Parent and mechRootPart and mechRootPart.Parent then
		local dismountPosition = mechRootPart.Position + (mechRootPart.CFrame.RightVector * DISMOUNT_SIDE_OFFSET) + Vector3.new(0, 2, 0)
		riderRootPart.CFrame = CFrame.new(dismountPosition, dismountPosition + mechRootPart.CFrame.LookVector)
	end

	currentRider = nil
	riderCharacter = nil
	riderHumanoid = nil
	riderRootPart = nil
	riderMoveDirection = Vector3.zero
	riderSprint = false

	mechHumanoid:Move(Vector3.zero, false)

	if sendClientUpdate and previousRider then
		fireMountedState(previousRider, false)
	end
end

local function tryMount(player)
	if currentRider then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then
		return
	end

	if humanoid.Health <= 0 then
		return
	end

	local distance = (rootPart.Position - mechRootPart.Position).Magnitude
	if distance > MOUNT_DISTANCE then
		return
	end

	currentRider = player
	riderCharacter = character
	riderHumanoid = humanoid
	riderRootPart = rootPart
	riderMoveDirection = Vector3.zero
	riderSprint = false

	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	rootPart.CFrame = mechRootPart.CFrame * CFrame.new(0, MOUNT_HEIGHT_OFFSET, 0)

	riderWeld = Instance.new("WeldConstraint")
	riderWeld.Name = "PlayerToMechWeld"
	riderWeld.Part0 = mechRootPart
	riderWeld.Part1 = rootPart
	riderWeld.Parent = mechRootPart

	setCharacterHidden(character, true)

	mechHumanoid.WalkSpeed = WALK_SPEED
	mechHumanoid.JumpPower = JUMP_POWER

	if riderDiedConnection then
		riderDiedConnection:Disconnect()
	end
	riderDiedConnection = humanoid.Died:Connect(function()
		if currentRider == player then
			clearRider(true)
		end
	end)

	fireMountedState(player, true)
end

controlEvent.OnServerEvent:Connect(function(player, action, arg1, arg2)
	if type(action) ~= "string" then
		return
	end

	if action == "ToggleMount" then
		if currentRider == player then
			clearRider(true)
		else
			tryMount(player)
		end
		return
	end

	if player ~= currentRider then
		return
	end

	if action == "Move" then
		if typeof(arg1) ~= "Vector3" then
			return
		end

		local moveDirection = Vector3.new(arg1.X, 0, arg1.Z)
		if moveDirection.Magnitude > 1 then
			moveDirection = moveDirection.Unit
		end

		riderMoveDirection = moveDirection
		riderSprint = arg2 == true
		return
	end

	if action == "Jump" then
		pulseJump()
	end
end)

RunService.Heartbeat:Connect(function()
	if not currentRider then
		return
	end

	if not riderCharacter or riderCharacter.Parent == nil then
		clearRider(true)
		return
	end
	if not riderHumanoid or riderHumanoid.Parent == nil or riderHumanoid.Health <= 0 then
		clearRider(true)
		return
	end
	if not riderRootPart or riderRootPart.Parent == nil then
		clearRider(true)
		return
	end

	mechHumanoid.WalkSpeed = riderSprint and SPRINT_SPEED or WALK_SPEED
	mechHumanoid.JumpPower = JUMP_POWER
	mechHumanoid:Move(riderMoveDirection, false)
end)

Players.PlayerRemoving:Connect(function(player)
	if player == currentRider then
		clearRider(false)
	end
end)

local function bindPlayer(player)
	player.CharacterRemoving:Connect(function()
		if player == currentRider then
			clearRider(true)
		end
	end)
end

for _, player in Players:GetPlayers() do
	bindPlayer(player)
end

Players.PlayerAdded:Connect(bindPlayer)
