--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CombatConfig = require(game:GetService("ReplicatedStorage").Combat.CombatConfig)
local CombatTypes = require(game:GetService("ReplicatedStorage").Combat.CombatTypes)

local DebugOverlay = {}

local _enabled: boolean = false
local _gui: ScreenGui? = nil
local _label: TextLabel? = nil
local _hitboxPart: BasePart? = nil
local _highlight: Highlight? = nil
local _renderConn: RBXScriptConnection? = nil

local _state: CombatTypes.StateSyncPayload? = nil

local function makeGui(): (ScreenGui, TextLabel)
	local plr = Players.LocalPlayer :: Player
	local gui = Instance.new("ScreenGui")
	gui.Name = "CombatDebugOverlay"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = plr:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 180)
	frame.Position = UDim2.new(0, 12, 0, 12)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BackgroundTransparency = 0.4
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, -16)
	label.Position = UDim2.new(0, 8, 0, 8)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Code
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = "Combat Debug"
	label.Parent = frame

	return gui, label
end

local function makeHitboxPreview()
	if _hitboxPart then return end
	local part = Instance.new("Part")
	part.Name = "DebugHitboxPreview"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.ForceField
	part.Color = Color3.fromRGB(0, 200, 255)
	part.Transparency = 0.65
	part.Size = CombatConfig.HitboxSize
	part.Parent = workspace
	_hitboxPart = part

	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(0, 220, 255)
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = 0.4
	hl.OutlineTransparency = 0
	hl.Adornee = part
	hl.Parent = part
	_highlight = hl
end

local function destroyHitboxPreview()
	if _hitboxPart then _hitboxPart:Destroy(); _hitboxPart = nil end
	if _highlight then _highlight:Destroy(); _highlight = nil end
end

local function renderTick()
	if not _enabled then return end
	local plr = Players.LocalPlayer :: Player
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?

	-- Update hitbox preview position
	if hrp and _hitboxPart then
		_hitboxPart.CFrame = hrp.CFrame * CFrame.new(0, 0, -CombatConfig.HitboxForwardOffset)
	end

	if _label then
		local now = os.clock()
		local s = _state
		if s then
			local stunRemain = math.max(0, s.stunUntil - now)
			local pbWindow = math.max(0, s.perfectBlockWindowEnd - now)
			local lines = {
				"═══ COMBAT DEBUG (L) ═══",
				string.format("Chain: %d / %d  active=%s", s.chainIndex, CombatConfig.ChainCount, tostring(s.chainActive)),
				string.format("Hit Counter: %d", s.hitCount),
				string.format("Block: %s  Meter: %.0f / %d", tostring(s.blocking), s.blockMeter, CombatConfig.BlockMeterMax),
				string.format("Broken: %s", tostring(s.isBlockBroken)),
				string.format("Stun: %.2fs", stunRemain),
				string.format("Perfect Window: %.3fs", pbWindow),
				string.format("M1 cooldown: %.2fs", CombatConfig.M1Cooldown),
			}
			_label.Text = table.concat(lines, "\n")
		else
			_label.Text = "═══ COMBAT DEBUG (L) ═══\nWaiting for state…"
		end
	end
end

function DebugOverlay.Toggle()
	_enabled = not _enabled
	if _enabled then
		if not _gui then
			_gui, _label = makeGui()
		else
			_gui.Enabled = true
		end
		makeHitboxPreview()
		if not _renderConn then
			_renderConn = RunService.RenderStepped:Connect(renderTick)
		end
	else
		if _gui then _gui.Enabled = false end
		destroyHitboxPreview()
		if _renderConn then _renderConn:Disconnect(); _renderConn = nil end
	end
end

function DebugOverlay.UpdateState(payload: CombatTypes.StateSyncPayload)
	_state = payload
end

return DebugOverlay