--!strict
local Debris = game:GetService("Debris")
local KnockbackService = {}

local IMPULSE_NAME = "CombatImpulse"
local ATTACH_NAME = "CombatImpulseAttachment"

local function clearExisting(rootPart: BasePart)
	local oldLv = rootPart:FindFirstChild(IMPULSE_NAME)
	if oldLv then oldLv:Destroy() end
	local oldAtt = rootPart:FindFirstChild(ATTACH_NAME)
	if oldAtt then oldAtt:Destroy() end
end

local function setFreefall(rootPart: BasePart)
	local humanoid = rootPart.Parent and rootPart.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Freefall) end) end
end

function KnockbackService.ApplyImpulse(rootPart: BasePart, velocity: Vector3, duration: number)
	if not rootPart or not rootPart.Parent then return end
	clearExisting(rootPart)

	local att = Instance.new("Attachment")
	att.Name = ATTACH_NAME
	att.Parent = rootPart

	local lv = Instance.new("LinearVelocity")
	lv.Name = IMPULSE_NAME
	lv.Attachment0 = att
	local mass = math.max(1, rootPart.AssemblyMass)
	lv.MaxForce = mass * 50000 
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VectorVelocity = velocity
	lv.Parent = rootPart

	Debris:AddItem(lv, duration)
	Debris:AddItem(att, duration + 0.05)
end

function KnockbackService.HorizontalKnockback(rootPart: BasePart, awayFrom: Vector3, speed: number, duration: number)
	local diff = rootPart.Position - awayFrom
	local horizontal = Vector3.new(diff.X, 0, diff.Z)
	local dir = horizontal.Magnitude > 0.01 and horizontal.Unit or rootPart.CFrame.LookVector

	setFreefall(rootPart)
	KnockbackService.ApplyImpulse(rootPart, dir * speed, duration)
end

-- NEW: Time-based Updraft calculation
function KnockbackService.Updraft(rootPart: BasePart, height: number, ascentTime: number, hangTime: number)
	if not rootPart or not rootPart.Parent then return end
	setFreefall(rootPart)
	clearExisting(rootPart)

	local att = Instance.new("Attachment")
	att.Name = ATTACH_NAME
	att.Parent = rootPart

	local lv = Instance.new("LinearVelocity")
	lv.Name = IMPULSE_NAME
	lv.Attachment0 = att
	local mass = math.max(1, rootPart.AssemblyMass)
	lv.MaxForce = mass * 50000 
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	-- Compute exact velocity needed to reach height in ascentTime
	lv.VectorVelocity = Vector3.new(0, height / ascentTime, 0)
	lv.Parent = rootPart

	-- Antigravity hover phase
	task.delay(ascentTime, function()
		if lv.Parent then lv.VectorVelocity = Vector3.new(0, 0, 0) end
	end)

	local totalDuration = ascentTime + hangTime
	Debris:AddItem(lv, totalDuration)
	Debris:AddItem(att, totalDuration + 0.05)
end

function KnockbackService.Lunge(rootPart: BasePart, direction: Vector3, speed: number, duration: number)
	local flatDir = Vector3.new(direction.X, 0, direction.Z)
	local dir = flatDir.Magnitude > 0.01 and flatDir.Unit or rootPart.CFrame.LookVector
	KnockbackService.ApplyImpulse(rootPart, dir * speed, duration)
end

return KnockbackService