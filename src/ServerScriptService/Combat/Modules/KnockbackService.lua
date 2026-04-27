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

-- Apply a velocity vector for `duration` seconds via LinearVelocity constraint.
-- World-relative; full force authority. Stomps any in-progress impulse.
function KnockbackService.ApplyImpulse(rootPart: BasePart, velocity: Vector3, duration: number)
	if not rootPart or not rootPart.Parent then return end
	clearExisting(rootPart)

	local att = Instance.new("Attachment")
	att.Name = ATTACH_NAME
	att.Parent = rootPart

	local lv = Instance.new("LinearVelocity")
	lv.Name = IMPULSE_NAME
	lv.Attachment0 = att
	lv.MaxForce = math.huge
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VectorVelocity = velocity
	lv.Parent = rootPart

	Debris:AddItem(lv, duration)
	Debris:AddItem(att, duration + 0.05)
end

-- Horizontal-only knockback away from origin.
function KnockbackService.HorizontalKnockback(
	rootPart: BasePart,
	awayFrom: Vector3,
	speed: number,
	duration: number
)
	local diff = rootPart.Position - awayFrom
	local horizontal = Vector3.new(diff.X, 0, diff.Z)
	local dir = horizontal.Magnitude > 0.01 and horizontal.Unit or rootPart.CFrame.LookVector
	KnockbackService.ApplyImpulse(rootPart, dir * speed, duration)
end

-- Vertical-only updraft impulse + force humanoid into Jumping state to detach grip.
function KnockbackService.Updraft(
	rootPart: BasePart,
	humanoid: Humanoid,
	upSpeed: number,
	duration: number
)
	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end)
	KnockbackService.ApplyImpulse(rootPart, Vector3.new(0, upSpeed, 0), duration)
end

return KnockbackService