--!strict

local CombatConfig = require(game:GetService("ReplicatedStorage").Combat.CombatConfig)
local CombatTypes = require(game:GetService("ReplicatedStorage").Combat.CombatTypes)
local KnockbackService = require(script.Parent.KnockbackService)
local EntityAnim = require(script.Parent.EntityAnim)

type EntityState = CombatTypes.EntityState

local BlockSystem = {}

function BlockSystem.StartBlock(entity: EntityState)
	if entity.humanoid.Health <= 0 then return end
	if entity.isBlockBroken then return end
	if os.clock() < entity.stunUntil then return end
	if entity.blocking then return end
	-- Tool gate (skip for dummies)
	if (not entity.isDummy) and (not entity.toolEquipped) then return end

	entity.blocking = true
	entity.blockStartTick = os.clock()
	entity.blockMeter = CombatConfig.BlockMeterMax
	entity.dirty = true

	if entity.isDummy then EntityAnim.Play(entity, "Block") end
end

function BlockSystem.StopBlock(entity: EntityState)
	if not entity.blocking then return end
	entity.blocking = false
	entity.blockMeter = CombatConfig.BlockMeterMax
	entity.dirty = true

	if entity.isDummy then EntityAnim.Stop(entity, "Block") end
end

function BlockSystem.BreakBlock(entity: EntityState)
	if entity.isBlockBroken then return end
	entity.blocking = false
	entity.isBlockBroken = true
	entity.blockMeter = 0
	entity.stunUntil = math.max(entity.stunUntil, os.clock() + CombatConfig.BlockBreakStun)
	entity.dirty = true

	if entity.isDummy then
		EntityAnim.Stop(entity, "Block")
		EntityAnim.Play(entity, "BlockBroken")
	end

	task.delay(CombatConfig.BlockBreakStun + 0.05, function()
		if not entity.model.Parent then return end
		if os.clock() < entity.stunUntil then return end
		entity.isBlockBroken = false
		entity.blockMeter = CombatConfig.BlockMeterMax
		entity.dirty = true
	end)
end

function BlockSystem.ResolveBlockedHit(victim: EntityState, _attacker: EntityState, hitTime: number): string
	if victim.dummyAIType == "PerfectBlock" then
		return "perfect"
	end
	if hitTime - victim.blockStartTick <= CombatConfig.PerfectBlockWindow then
		return "perfect"
	end
	return "regular"
end

function BlockSystem.ApplyRegularBlock(victim: EntityState)
	victim.blockMeter -= CombatConfig.BlockDrainPerHit
	if victim.blockMeter <= 0 then
		victim.blockMeter = 0
		BlockSystem.BreakBlock(victim)
	end
	victim.dirty = true
end

function BlockSystem.ApplyPerfectBlock(victim: EntityState, attacker: EntityState)
	victim.blockMeter = CombatConfig.BlockMeterMax
	victim.dirty = true

	KnockbackService.HorizontalKnockback(
		attacker.rootPart, victim.rootPart.Position,
		CombatConfig.StaggerVelocity, CombatConfig.StaggerDuration
	)
	attacker.stunUntil = math.max(attacker.stunUntil, os.clock() + CombatConfig.PerfectBlockStaggerStun)
	attacker.chainIndex = 0
	attacker.chainActive = false
	attacker.chainSpaceFlag = false
	attacker.dirty = true
end

return BlockSystem