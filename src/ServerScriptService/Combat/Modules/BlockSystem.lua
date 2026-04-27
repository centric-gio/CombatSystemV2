--!strict
local CombatConfig = require(game:GetService("ReplicatedStorage").Combat.CombatConfig)
local CombatTypes = require(game:GetService("ReplicatedStorage").Combat.CombatTypes)
local EntityAnim = require(script.Parent.EntityAnim)

type EntityState = CombatTypes.EntityState
local BlockSystem = {}

function BlockSystem.StartBlock(entity: EntityState)
	if entity.humanoid.Health <= 0 or entity.isBlockBroken or os.clock() < entity.stunUntil or entity.blocking then return end
	if (not entity.isDummy) and (not entity.toolEquipped) then return end
	entity.blocking = true
	entity.blockStartTick = os.clock()
	-- DO NOT instantly fill meter here, it allows continuous usage up until break
	entity.dirty = true
	if entity.isDummy then EntityAnim.Play(entity, "Block") end
end

function BlockSystem.StopBlock(entity: EntityState)
	if not entity.blocking then return end
	entity.blocking = false
	-- DO NOT instantly fill meter here; it relies on the new passive regen
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
		if not entity.model.Parent or os.clock() < entity.stunUntil then return end
		entity.isBlockBroken = false
		-- Meter resets when the stun fully recovers
		entity.blockMeter = CombatConfig.BlockMeterMax 
		entity.dirty = true
	end)
end

function BlockSystem.ResolveBlockedHit(victim: EntityState, attacker: EntityState, hitTime: number): string
	if victim.dummyAIType == "PerfectBlock" or hitTime - victim.blockStartTick <= CombatConfig.PerfectBlockWindow then
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
	-- Successful parries reward a small meter return
	victim.blockMeter = math.min(CombatConfig.BlockMeterMax, victim.blockMeter + 20)
	victim.dirty = true

	attacker.stunUntil = math.max(attacker.stunUntil, os.clock() + CombatConfig.PerfectBlockStaggerStun)
	attacker.chainIndex = 0
	attacker.chainActive = false
	attacker.dirty = true
end

return BlockSystem