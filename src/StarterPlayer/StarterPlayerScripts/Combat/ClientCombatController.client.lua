--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local CombatConfig = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatConfig"))
local CombatTypes = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatTypes"))

local Modules = script.Parent:WaitForChild("Modules")
local AnimationPlayer = require(Modules:WaitForChild("AnimationPlayer"))
local SoundPlayer = require(Modules:WaitForChild("SoundPlayer"))
local InputController = require(Modules:WaitForChild("InputController"))
local DebugOverlay = require(Modules:WaitForChild("DebugOverlay"))
local CameraShaker = require(Modules:WaitForChild("CameraShaker"))
local BlockGuiController = require(Modules:WaitForChild("BlockGuiController"))

local LocalPlayer = Players.LocalPlayer :: Player

local combatFolder = ReplicatedStorage:WaitForChild("Combat") :: Folder
local remotes = combatFolder:WaitForChild("Remotes") :: Folder
local assets = combatFolder:WaitForChild("Assets") :: Folder
local animFolder = assets:WaitForChild("Animations") :: Folder
local soundFolder = assets:WaitForChild("Sounds") :: Folder

local M1Request = remotes:WaitForChild("M1Request") :: RemoteEvent
local BlockStateChanged = remotes:WaitForChild("BlockStateChanged") :: RemoteEvent
local JumpStateChanged = remotes:WaitForChild("JumpStateChanged") :: RemoteEvent
local CombatEvent = remotes:WaitForChild("CombatEvent") :: RemoteEvent
local StateSync = remotes:WaitForChild("StateSync") :: RemoteEvent

task.spawn(function()
	local assetsToPreload: { Instance } = {}
	for _, s in ipairs(soundFolder:GetChildren()) do table.insert(assetsToPreload, s) end
	for _, a in ipairs(animFolder:GetChildren()) do table.insert(assetsToPreload, a) end
	pcall(function() ContentProvider:PreloadAsync(assetsToPreload) end)
end)

BlockGuiController.Init()

local _toolEquipped: boolean = false
local function refreshToolState(character: Model)
	_toolEquipped = character:FindFirstChild(CombatConfig.ToolName) ~= nil
end

local function bindToolTracking(character: Model)
	refreshToolState(character)
	character.ChildAdded:Connect(function(c)
		if c:IsA("Tool") and c.Name == CombatConfig.ToolName then _toolEquipped = true end
	end)
	character.ChildRemoved:Connect(function(c)
		if c:IsA("Tool") and c.Name == CombatConfig.ToolName then _toolEquipped = false end
	end)
end

local function onCharacterAdded(character: Model)
	character:WaitForChild("Humanoid", 5)
	character:WaitForChild("HumanoidRootPart", 5)
	AnimationPlayer.Bind(character, animFolder)
	SoundPlayer.Bind(character, soundFolder)
	bindToolTracking(character)
end

if LocalPlayer.Character then onCharacterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

InputController.Bind({
	onM1 = function()
		if not _toolEquipped then return end
		M1Request:FireServer()
	end,
	onBlockStart = function()
		if not _toolEquipped then return end
		BlockStateChanged:FireServer(true)
		AnimationPlayer.Play("Block", 0.1)
	end,
	onBlockEnd = function()
		BlockStateChanged:FireServer(false)
		AnimationPlayer.Stop("Block", 0.15)
	end,
	onJumpStart = function()
		JumpStateChanged:FireServer(true)
	end,
	onJumpEnd = function()
		JumpStateChanged:FireServer(false)
	end,
	onDebugToggle = function()
		DebugOverlay.Toggle()
	end,
})

local M1_ANIMS = { [1] = "M1_1", [2] = "M1_2",[3] = "M1_3",[4] = "M1_4", [5] = "M1_5" }

CombatEvent.OnClientEvent:Connect(function(payload: CombatTypes.CombatEventPayload)
	local kind = payload.kind
	local char = LocalPlayer.Character
	local myId = char and char:GetAttribute("EntityId")

	if kind == "Swing" then
		local idx = payload.chainIndex or 1
		if myId and payload.attackerId == myId then
			local animName = M1_ANIMS[idx]
			if animName then AnimationPlayer.Play(animName, 0.05) end
			CameraShaker.Shake(CombatConfig.ShakeIntensity, CombatConfig.ShakeDuration)
		end
		SoundPlayer.Play("M1Swing")

	elseif kind == "Hit" or kind == "Flinch" or kind == "Knockback" or kind == "Updraft" then
		SoundPlayer.Play("Hit")
		if myId and payload.victimId == myId then
			AnimationPlayer.Play("Flinch", 0.05)
		end

	elseif kind == "BlockedHit" then
		SoundPlayer.Play("BlockedHit")

	elseif kind == "PerfectBlocked" then
		SoundPlayer.Play("Parried")

		-- Defender plays the PerfectBlocked shield bash
		if myId and payload.victimId == myId then
			AnimationPlayer.Play("PerfectBlocked", 0.05)
		end

		-- Attacker plays BlockBroken as a parried stagger animation
		if myId and payload.attackerId == myId then
			AnimationPlayer.Play("BlockBroken", 0.05)
		end

	elseif kind == "BlockBroken" then
		SoundPlayer.Play("BlockBroken")
		if myId and payload.victimId == myId then
			AnimationPlayer.Play("BlockBroken", 0.1)
		end
	end
end)

StateSync.OnClientEvent:Connect(function(payload: CombatTypes.StateSyncPayload)
	DebugOverlay.UpdateState(payload)
end)