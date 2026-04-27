--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPack = game:GetService("StarterPack")

local CombatConfig = require(ReplicatedStorage.Combat.CombatConfig)
local CombatTypes = require(ReplicatedStorage.Combat.CombatTypes)

local Modules = script.Parent:WaitForChild("Modules")
local CombatState = require(Modules:WaitForChild("CombatState"))
local M1Handler = require(Modules:WaitForChild("M1Handler"))
local BlockSystem = require(Modules:WaitForChild("BlockSystem"))
local DummyManager = require(Modules:WaitForChild("DummyManager"))
local ChatCommands = require(Modules:WaitForChild("ChatCommands"))
local EntityAnim = require(Modules:WaitForChild("EntityAnim"))

type EntityState = CombatTypes.EntityState

-- ════════════════════════════════════════════════════════════
-- BOOTSTRAP
-- ════════════════════════════════════════════════════════════
local combatFolder = ReplicatedStorage:WaitForChild("Combat") :: Folder

local function getOrCreateFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then return existing end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local remotesFolder = getOrCreateFolder(combatFolder, "Remotes")
local assetsFolder = getOrCreateFolder(combatFolder, "Assets")
local animFolder = getOrCreateFolder(assetsFolder, "Animations")
local soundFolder = getOrCreateFolder(assetsFolder, "Sounds")

local function makeRemote(name: string): RemoteEvent
	local existing = remotesFolder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then return existing end
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotesFolder
	return r
end

local M1Request           = makeRemote("M1Request")
local BlockStateChanged   = makeRemote("BlockStateChanged")
local JumpStateChanged    = makeRemote("JumpStateChanged")
local CombatEvent         = makeRemote("CombatEvent")
local StateSync           = makeRemote("StateSync")
local DummyCommand        = makeRemote("DummyCommand")

for animName, animId in pairs(CombatConfig.Animations) do
	if animFolder:FindFirstChild(animName) then continue end
	local a = Instance.new("Animation")
	a.Name = animName
	a.AnimationId = "rbxassetid://" .. tostring(animId)
	a.Parent = animFolder
end

for sndName, sndId in pairs(CombatConfig.Sounds) do
	if soundFolder:FindFirstChild(sndName) then continue end
	local s = Instance.new("Sound")
	s.Name = sndName
	s.SoundId = "rbxassetid://" .. tostring(sndId)
	s.Volume = 1
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMaxDistance = 60
	s.Parent = soundFolder
end

M1Handler.Init(CombatEvent)
EntityAnim.Init(animFolder)

-- ════════════════════════════════════════════════════════════
-- TOOL: place CombatSword in StarterPack
-- ════════════════════════════════════════════════════════════
local function buildSwordTool(): Tool
	local tool = Instance.new("Tool")
	tool.Name = CombatConfig.ToolName
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 4)
	handle.Color = Color3.fromRGB(120, 120, 120)
	handle.Material = Enum.Material.Metal
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.Parent = tool
	return tool
end

if not StarterPack:FindFirstChild(CombatConfig.ToolName) then
	buildSwordTool().Parent = StarterPack
end

-- ════════════════════════════════════════════════════════════
-- PLAYER LIFECYCLE
-- ════════════════════════════════════════════════════════════
local function bindToolTracking(player: Player, character: Model)
	local function recheck()
		local state = CombatState.GetByPlayer(player)
		if not state then return end
		local hasTool = character:FindFirstChild(CombatConfig.ToolName) ~= nil
		if hasTool ~= state.toolEquipped then
			state.toolEquipped = hasTool
			state.dirty = true
			if not hasTool then
				BlockSystem.StopBlock(state)
				M1Handler.ResetChain(state)
			end
		end
	end
	character.ChildAdded:Connect(recheck)
	character.ChildRemoved:Connect(recheck)
	recheck()
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	local rootPart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not (humanoid and rootPart) then return end

	humanoid.WalkSpeed = CombatConfig.DefaultWalkSpeed
	humanoid.JumpPower = CombatConfig.DefaultJumpPower
	humanoid.JumpHeight = CombatConfig.DefaultJumpHeight

	CombatState.Register(character, humanoid, rootPart, player, false, nil, nil)

	humanoid.Died:Connect(function()
		CombatState.Unregister(character)
	end)

	bindToolTracking(player, character)
end

local function onPlayerAdded(player: Player)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
	player.CharacterAdded:Connect(function(c) onCharacterAdded(player, c) end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, plr in ipairs(Players:GetPlayers()) do onPlayerAdded(plr) end

Players.PlayerRemoving:Connect(function(player)
	DummyManager.ClearAll(player)
	if player.Character then
		CombatState.Unregister(player.Character)
	end
end)

-- ════════════════════════════════════════════════════════════
-- REMOTE HANDLERS (server-side tool gates redundantly enforced)
-- ════════════════════════════════════════════════════════════
M1Request.OnServerEvent:Connect(function(player: Player)
	local state = CombatState.GetByPlayer(player)
	if not state then return end
	if not state.toolEquipped then return end
	M1Handler.RequestM1(state)
end)

BlockStateChanged.OnServerEvent:Connect(function(player: Player, isBlocking: any)
	local state = CombatState.GetByPlayer(player)
	if not state then return end
	if typeof(isBlocking) ~= "boolean" then return end
	if isBlocking then
		if not state.toolEquipped then return end
		BlockSystem.StartBlock(state)
	else
		BlockSystem.StopBlock(state)
	end
end)

JumpStateChanged.OnServerEvent:Connect(function(player: Player, isHeld: any)
	local state = CombatState.GetByPlayer(player)
	if not state then return end
	if typeof(isHeld) ~= "boolean" then return end
	state.jumpHeld = isHeld
	if (not isHeld) and state.chainActive then
		state.chainSpaceFlag = false
	end
end)

DummyCommand.OnServerEvent:Connect(function(player: Player, action: any, arg: any)
	if action == "spawn" and typeof(arg) == "string" then
		DummyManager.Spawn(player, arg)
	elseif action == "clear" then
		DummyManager.ClearAll(player)
	end
end)

ChatCommands.Register()

-- ════════════════════════════════════════════════════════════
-- HEARTBEAT TICK
-- ════════════════════════════════════════════════════════════
local function tickEntity(entity: EntityState, _dt: number)
	local now = os.clock()

	-- (No passive block drain — drain happens on hit only.)

	-- Walkspeed authority
	local desiredWS: number
	if now < entity.stunUntil then
		desiredWS = 0
	elseif entity.blocking then
		desiredWS = CombatConfig.DefaultWalkSpeed * CombatConfig.BlockWalkspeedMultiplier
	else
		desiredWS = entity.isDummy and 0 or CombatConfig.DefaultWalkSpeed
	end
	if entity.humanoid.WalkSpeed ~= desiredWS then
		entity.humanoid.WalkSpeed = desiredWS
	end

	-- Jump authority via JumpPower / JumpHeight (does NOT use SetStateEnabled —
	-- so KnockbackService.Updraft can still ChangeState(Jumping) successfully).
	local canJump = (now >= entity.stunUntil)
		and (not entity.chainActive)
		and (not entity.blocking)
		and (not entity.isBlockBroken)
	if entity.player then
		local jp = canJump and CombatConfig.DefaultJumpPower or 0
		local jh = canJump and CombatConfig.DefaultJumpHeight or 0
		if entity.humanoid.JumpPower ~= jp then entity.humanoid.JumpPower = jp end
		if entity.humanoid.JumpHeight ~= jh then entity.humanoid.JumpHeight = jh end
	end

	-- Chain inactivity reset
	if entity.chainActive and (now - entity.lastChainTick > CombatConfig.ChainResetTime) then
		M1Handler.ResetChain(entity)
	end

	-- Hit-counter inactivity reset
	if entity.hitCount > 0 and (now - entity.lastHitTick > 5.0) then
		entity.hitCount = 0
		entity.dirty = true
	end

	-- StateSync push
	if entity.dirty and entity.player then
		local payload: CombatTypes.StateSyncPayload = {
			chainIndex = entity.chainIndex,
			chainActive = entity.chainActive,
			blockMeter = entity.blockMeter,
			blocking = entity.blocking,
			isBlockBroken = entity.isBlockBroken,
			stunUntil = entity.stunUntil,
			hitCount = entity.hitCount,
			nowServer = now,
			perfectBlockWindowEnd = entity.blocking
				and (entity.blockStartTick + CombatConfig.PerfectBlockWindow)
				or 0,
		}
		StateSync:FireClient(entity.player, payload)
		entity.dirty = false
	end
end

RunService.Heartbeat:Connect(function(dt: number)
	for _, entity in ipairs(CombatState.All()) do
		if entity.model.Parent then
			tickEntity(entity, dt)
		else
			CombatState.Unregister(entity.model)
		end
	end
	DummyManager.Tick()
end)

print("[Combat] ServerCombatManager initialized.")