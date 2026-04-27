--!strict

local CombatTypes = require(game:GetService("ReplicatedStorage").Combat.CombatTypes)
local CombatState = require(script.Parent.CombatState)

type EntityState = CombatTypes.EntityState

local HitboxService = {}

-- Returns unique entity states whose root parts intersect the given OBB.
function HitboxService.Query(
	cframe: CFrame,
	size: Vector3,
	ignoreModels: { Instance }
): { EntityState }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreModels
	params.MaxParts = 50

	local parts = workspace:GetPartBoundsInBox(cframe, size, params)
	local seen: { [Model]: boolean } = {}
	local results: { EntityState } = {}

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if not model or seen[model] then continue end
		local state = CombatState.Get(model)
		if not state then continue end
		if state.humanoid.Health <= 0 then continue end
		seen[model] = true
		table.insert(results, state)
	end

	return results
end

-- Builds the swing hitbox CFrame in front of the attacker.
function HitboxService.BuildSwingCFrame(rootPart: BasePart, forwardOffset: number): CFrame
	return rootPart.CFrame * CFrame.new(0, 0, -forwardOffset)
end

return HitboxService