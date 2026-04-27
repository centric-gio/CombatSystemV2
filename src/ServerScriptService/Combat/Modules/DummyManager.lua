--!strict

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatConfig = require(ReplicatedStorage.Combat.CombatConfig)
local CombatTypes = require(ReplicatedStorage.Combat.CombatTypes)

local CombatState = require(script.Parent.CombatState)
local M1Handler = require(script.Parent.M1Handler)
local BlockSystem = require(script.Parent.BlockSystem)
local EntityAnim = require(script.Parent.EntityAnim)

type EntityState = CombatTypes.EntityState

local DummyManager = {}

local _activeDummies: { [Model]: EntityState } = {}

-- ──────────────────── R6 rig builder ────────────────────
local function buildR6Rig(): Model
	local model = Instance.new("Model")

	local function makePart(name: string, size: Vector3, color: Color3): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Material = Enum.Material.Plastic
		return p
	end

	local hrp = makePart("HumanoidRootPart", Vector3.new(2, 2, 1), Color3.new(1, 1, 1))
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Massless = true

	local torso = makePart("Torso", Vector3.new(2, 2, 1), Color3.fromRGB(80, 120, 200))
	local head = makePart("Head", Vector3.new(2, 1, 1), Color3.fromRGB(220, 200, 80))
	local leftArm = makePart("Left Arm", Vector3.new(1, 2, 1), Color3.fromRGB(200, 170, 130))
	local rightArm = makePart("Right Arm", Vector3.new(1, 2, 1), Color3.fromRGB(200, 170, 130))
	local leftLeg = makePart("Left Leg", Vector3.new(1, 2, 1), Color3.fromRGB(40, 60, 100))
	local rightLeg = makePart("Right Leg", Vector3.new(1, 2, 1), Color3.fromRGB(40, 60, 100))

	local function weld(p0: BasePart, p1: BasePart, c0: CFrame)
		local w = Instance.new("Motor6D")
		w.Part0 = p0
		w.Part1 = p1
		w.C0 = c0
		w.Parent = p0
	end

	-- HRP at center
	hrp.Parent = model
	torso.Parent = model
	weld(hrp, torso, CFrame.new(0, 0, 0))

	head.Parent = model
	weld(torso, head, CFrame.new(0, 1.5, 0))

	leftArm.Parent = model
	weld(torso, leftArm, CFrame.new(-1.5, 0, 0))

	rightArm.Parent = model
	weld(torso, rightArm, CFrame.new(1.5, 0, 0))

	leftLeg.Parent = model
	weld(torso, leftLeg, CFrame.new(-0.5, -2, 0))

	rightLeg.Parent = model
	weld(torso, rightLeg, CFrame.new(0.5, -2, 0))

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.WalkSpeed = 0  -- dummies don't walk
	humanoid.JumpPower = 0
	humanoid.Parent = model

	model.PrimaryPart = hrp
	return model
end

local function attachBillboard(model: Model, label: string): TextLabel?
	local head = model:FindFirstChild("Head") :: BasePart?
	local anchor = head or (model:FindFirstChild("HumanoidRootPart") :: BasePart?)
	if not anchor then return nil end

	local bb = Instance.new("BillboardGui")
	bb.Name = "DummyHUD"
	bb.Size = UDim2.fromScale(8, 1.5)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = anchor

	local txt = Instance.new("TextLabel")
	txt.Name = "Label"
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.TextColor3 = Color3.new(1, 1, 1)
	txt.TextStrokeTransparency = 0
	txt.Font = Enum.Font.GothamBold
	txt.TextSize = 14
	txt.Text = label
	txt.Parent = bb
	return txt
end

-- ──────────────────── lifecycle ────────────────────
function DummyManager.Spawn(requester: Player, aiType: string): Model?
	local validTypes = { Idle = true, Blocking = true, Attacking = true, PerfectBlock = true }
	if not validTypes[aiType] then return nil end

	local rChar = requester.Character
	local rRoot = rChar and rChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rRoot then return nil end

	local model = buildR6Rig()
	model.Name = "Dummy_" .. aiType
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid

	model:PivotTo(rRoot.CFrame * CFrame.new(0, 0, -6))
	model.Parent = workspace

	-- Strip any default health regen scripts (none on procedural rig, but guard anyway)
	local oldHealthScript = model:FindFirstChild("Health")
	if oldHealthScript and oldHealthScript:IsA("Script") then
		oldHealthScript:Destroy()
	end

	if aiType == "Idle" then
		humanoid.MaxHealth = math.huge
		humanoid.Health = math.huge
		humanoid.HealthChanged:Connect(function()
			if humanoid.Health ~= math.huge then
				humanoid.Health = math.huge
			end
		end)
	else
		humanoid.MaxHealth = 500
		humanoid.Health = 500
	end

	local state = CombatState.Register(model, humanoid, hrp, nil, true, aiType, requester)
	_activeDummies[model] = state

	-- Set up server-side animations
	EntityAnim.Setup(state)

	local label = attachBillboard(model, aiType)

	task.delay(CombatConfig.DummyLifetime, function()
		DummyManager.Despawn(model)
	end)

	humanoid.Died:Connect(function()
		task.delay(1.5, function()
			DummyManager.Despawn(model)
		end)
	end)

	if label then
		task.spawn(function()
			while model.Parent and label.Parent do
				local hpPct = humanoid.Health < math.huge
					and math.floor((humanoid.Health / math.max(humanoid.MaxHealth, 1)) * 100)
					or 100
				local meterPct = math.floor(state.blockMeter / CombatConfig.BlockMeterMax * 100)
				local statusBits = {}
				if state.blocking then table.insert(statusBits, "BLOCK") end
				if state.isBlockBroken then table.insert(statusBits, "BROKEN") end
				if os.clock() < state.stunUntil then table.insert(statusBits, "STUN") end
				local status = #statusBits > 0 and (" [" .. table.concat(statusBits, "|") .. "]") or ""
				label.Text = string.format("%s | HP %d%% | Block %d%%%s", aiType, hpPct, meterPct, status)
				task.wait(0.15)
			end
		end)
	end

	return model
end

function DummyManager.Despawn(model: Model)
	if not _activeDummies[model] then return end
	_activeDummies[model] = nil
	CombatState.Unregister(model)
	if model.Parent then
		model:Destroy()
	end
end

function DummyManager.ClearAll(requester: Player?)
	for model, state in pairs(_activeDummies) do
		if requester == nil or state.spawnedBy == requester then
			DummyManager.Despawn(model)
		end
	end
end

-- ──────────────────── AI tick ────────────────────
local function nearestPlayer(origin: Vector3, range: number): (Player?, BasePart?)
	local best: Player?, bestPart: BasePart?, bestDist = nil, nil, range
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local d = (hrp.Position - origin).Magnitude
			if d < bestDist then
				best = plr; bestPart = hrp; bestDist = d
			end
		end
	end
	return best, bestPart
end

function DummyManager.Tick()
	local now = os.clock()
	for model, state in pairs(_activeDummies) do
		if not model.Parent then
			DummyManager.Despawn(model)
			continue
		end

		local ai = state.dummyAIType
		if ai == "Blocking" then
			if not state.blocking and not state.isBlockBroken and now >= state.stunUntil then
				BlockSystem.StartBlock(state)
			end
		elseif ai == "PerfectBlock" then
			if not state.blocking and now >= state.stunUntil then
				BlockSystem.StartBlock(state)
			end
			-- Continually refresh window so any incoming hit is within parry threshold
			state.blockStartTick = now
		elseif ai == "Attacking" then
			-- DOES NOT FOLLOW. Only attacks if player is in melee range.
			local _, targetPart = nearestPlayer(state.rootPart.Position, CombatConfig.DummyMeleeRange)
			if targetPart then
				if now - state.lastM1Tick >= CombatConfig.DummyAttackInterval and now >= state.stunUntil then
					-- Face target horizontally
					local origin = state.rootPart.Position
					local lookAt = Vector3.new(targetPart.Position.X, origin.Y, targetPart.Position.Z)
					if (lookAt - origin).Magnitude > 0.1 then
						state.rootPart.CFrame = CFrame.lookAt(origin, lookAt)
					end
					M1Handler.RequestM1(state)
				end
			end
		end
	end
end

return DummyManager