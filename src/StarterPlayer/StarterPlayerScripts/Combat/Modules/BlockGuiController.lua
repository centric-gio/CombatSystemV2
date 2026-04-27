--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CombatConfig = require(ReplicatedStorage:WaitForChild("Combat"):WaitForChild("CombatConfig"))

local BlockGuiController = {}

local _guis: { [Model]: BillboardGui } = {}
local _connections: {[Model]: { RBXScriptConnection } } = {}

local function updateGui(model: Model)
	local gui = _guis[model]
	if not gui then return end
	local img = gui:FindFirstChild("BlockImage") :: ImageLabel
	if not img then return end

	local isBlocking = model:GetAttribute("Combat_Blocking") == true
	local isBroken = model:GetAttribute("Combat_BlockBroken") == true
	local meter = model:GetAttribute("Combat_BlockMeter") :: number or CombatConfig.BlockMeterMax

	if isBroken then
		gui.Enabled = true
		img.ImageColor3 = Color3.new(1, 0, 0)
	elseif isBlocking then
		gui.Enabled = true
		-- Map meter from Max -> 0 to Color White -> Dark Gray (0.2)
		local ratio = math.max(0.2, meter / CombatConfig.BlockMeterMax)
		img.ImageColor3 = Color3.new(ratio, ratio, ratio)
	else
		gui.Enabled = false
	end
end

-- Triggers Pop Effect
local function popTween(model: Model)
	local gui = _guis[model]
	if not gui then return end
	local img = gui:FindFirstChild("BlockImage") :: ImageLabel
	if not img then return end

	local popInfo = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	img.Size = UDim2.fromScale(1.4, 1.4)
	TweenService:Create(img, popInfo, {Size = UDim2.fromScale(1, 1)}):Play()
end

local function onEntityAdded(model: Model)
	local root = model:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not root then return end

	local template = ReplicatedStorage.Combat.Assets:FindFirstChild("BlockBillboard") :: BillboardGui?
	if template then
		local clone = template:Clone()
		clone.Enabled = false
		clone.Parent = root
		_guis[model] = clone
	end

	_connections[model] = {
		model:GetAttributeChangedSignal("Combat_Blocking"):Connect(function() updateGui(model) end),
		model:GetAttributeChangedSignal("Combat_BlockBroken"):Connect(function() updateGui(model) end),
		model:GetAttributeChangedSignal("Combat_BlockMeter"):Connect(function()
			updateGui(model)
			if model:GetAttribute("Combat_Blocking") == true then popTween(model) end
		end),
	}
	updateGui(model)
end

local function onEntityRemoved(model: Model)
	if _guis[model] then _guis[model]:Destroy(); _guis[model] = nil end
	if _connections[model] then
		for _, conn in ipairs(_connections[model]) do conn:Disconnect() end
		_connections[model] = nil
	end
end

function BlockGuiController.Init()
	for _, model in ipairs(CollectionService:GetTagged("CombatEntity")) do onEntityAdded(model) end
	CollectionService:GetInstanceAddedSignal("CombatEntity"):Connect(onEntityAdded)
	CollectionService:GetInstanceRemovedSignal("CombatEntity"):Connect(onEntityRemoved)
end

return BlockGuiController