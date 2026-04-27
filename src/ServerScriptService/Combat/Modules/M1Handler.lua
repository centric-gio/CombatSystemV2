--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatConfig = require(ReplicatedStorage.Combat.CombatConfig)
local CombatTypes = require(ReplicatedStorage.Combat.CombatTypes)

local CombatState = require(script.Parent.CombatState)
local HitboxService = require(script.Parent.HitboxService)
local BlockSystem = require(script.Parent.BlockSystem)
local KnockbackService = require(script.Parent.KnockbackService)
local EntityAnim = require(script.Parent.EntityAnim)

type EntityState = CombatTypes.EntityState

local M1Handler = {}

local CombatEventRemote: RemoteEvent

function M1Handler.Init(combatEventRemote: RemoteEvent)
	CombatEventRemote = combatEventRemote
end

local function broadcast(payload: CombatTypes.CombatEventPayload, origin: Vector3)
	for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local dist = ((hrp :: BasePart).Position - origin).Magnitude
			if dist <= CombatConfig.BroadcastRange then
				CombatEventRemote:FireClient(plr, payload)
			end
		end
	end
end

local function fireToOwner(entity: EntityState, payload: CombatTypes.CombatEventPayload)
	if entity.player then
		CombatEventRemote:FireClient(entity.player, payload)
	end
end

function M1Handler.ResetChain(entity: EntityState)
	entity.chainIndex = 0
	entity.chainActive = false
	entity.chainSpaceFlag = false
	entity.dirty = true
end

local function resolveHitOnVictim(
	attacker: EntityState,
	victim: EntityState,
	chainIndex: number,
	isFinal: boolean,
	updraftBranch: boolean
)
	local now = os.clock()

	if (attacker.rootPart.Position - victim.rootPart.Position).Magnitude > CombatConfig.MaxHitDistance then return end
	if attacker.model == victim.model then return end
	if victim.humanoid.Health <= 0 then return end

	-- Block resolution path
	if victim.blocking then
		local result = BlockSystem.ResolveBlockedHit(victim, attacker, now)
		if result == "perfect" then
			BlockSystem.ApplyPerfectBlock(victim, attacker)
			-- Server-side anim for dummies
			if victim.isDummy then EntityAnim.Play(victim, "PerfectBlocked") end
			broadcast({
				kind = "PerfectBlocked",
				chainIndex = chainIndex,
				attackerId = attacker.model:GetAttribute("EntityId") :: number,
				victimId = victim.model:GetAttribute("EntityId") :: number,
			}, victim.rootPart.Position)
			return
		else
			BlockSystem.ApplyRegularBlock(victim)
			if victim.isBlockBroken and victim.isDummy then
				EntityAnim.Stop(victim, "Block")
				EntityAnim.Play(victim, "BlockBroken")
			end
			broadcast({
				kind = victim.isBlockBroken and "BlockBroken" or "BlockedHit",
				chainIndex = chainIndex,
				attackerId = attacker.model:GetAttribute("EntityId") :: number,
				victimId = victim.model:GetAttribute("EntityId") :: number,
			}, victim.rootPart.Position)
			-- Blocked hit ends the chain (per spec)
			M1Handler.ResetChain(attacker)
			return
		end
	end

	-- Unblocked hit
	local damage = CombatConfig.BaseDamage * (isFinal and CombatConfig.FinalHitMultiplier or 1)
	victim.humanoid:TakeDamage(damage)

	attacker.hitCount += 1
	attacker.lastHitTick = now
	attacker.dirty = true

	-- Hits 1–4: damage + (optional) flinch ONLY. NO knockback.
	if not isFinal then
		if CombatConfig.HitFlinchStun > 0 then
			victim.stunUntil = math.max(victim.stunUntil, now + CombatConfig.HitFlinchStun)
		end
		if victim.isDummy then EntityAnim.Play(victim, "Flinch") end
		broadcast({
			kind = "Flinch",
			chainIndex = chainIndex,
			attackerId = attacker.model:GetAttribute("EntityId") :: number,
			victimId = victim.model:GetAttribute("EntityId") :: number,
			hitCount = attacker.hitCount,
		}, victim.rootPart.Position)
		return
	end

	-- 5th hit ONLY: knockback OR updraft
	if updraftBranch then
		KnockbackService.Updraft(victim.rootPart, victim.humanoid, CombatConfig.UpdraftUpVelocity, CombatConfig.UpdraftDuration)
		KnockbackService.Updraft(attacker.rootPart, attacker.humanoid, CombatConfig.UpdraftUpVelocity, CombatConfig.UpdraftDuration)
		victim.stunUntil = math.max(victim.stunUntil, now + CombatConfig.UpdraftStun)
		attacker.stunUntil = math.max(attacker.stunUntil, now + CombatConfig.UpdraftStun * 0.6)
		if victim.isDummy then EntityAnim.Play(victim, "Flinch") end
		broadcast({
			kind = "Updraft",
			chainIndex = chainIndex,
			attackerId = attacker.model:GetAttribute("EntityId") :: number,
			victimId = victim.model:GetAttribute("EntityId") :: number,
			hitCount = attacker.hitCount,
		}, victim.rootPart.Position)
	else
		KnockbackService.HorizontalKnockback(victim.rootPart, attacker.rootPart.Position, CombatConfig.KnockbackVelocity, CombatConfig.KnockbackDuration)
		victim.stunUntil = math.max(victim.stunUntil, now + CombatConfig.KnockbackStun)
		if victim.isDummy then EntityAnim.Play(victim, "Flinch") end
		broadcast({
			kind = "Knockback",
			chainIndex = chainIndex,
			attackerId = attacker.model:GetAttribute("EntityId") :: number,
			victimId = victim.model:GetAttribute("EntityId") :: number,
			hitCount = attacker.hitCount,
		}, victim.rootPart.Position)
	end

	M1Handler.ResetChain(attacker)
end

local function resolveHitbox(attacker: EntityState, chainIndex: number)
	local cframe = HitboxService.BuildSwingCFrame(attacker.rootPart, CombatConfig.HitboxForwardOffset)
	local victims = HitboxService.Query(cframe, CombatConfig.HitboxSize, { attacker.model })
	if #victims == 0 then return end

	local isFinal = chainIndex >= CombatConfig.ChainCount
	local updraftBranch = isFinal and attacker.chainSpaceFlag

	for _, victim in ipairs(victims) do
		resolveHitOnVictim(attacker, victim, chainIndex, isFinal, updraftBranch)
	end
end

function M1Handler.RequestM1(attacker: EntityState)
	local now = os.clock()

	if attacker.humanoid.Health <= 0 then return end
	if now < attacker.stunUntil then return end
	if attacker.isBlockBroken then return end
	if attacker.blocking then return end
	-- Tool gate (skip for dummies — they can always swing)
	if (not attacker.isDummy) and (not attacker.toolEquipped) then return end
	if now - attacker.lastM1Tick < CombatConfig.M1Cooldown then return end

	if now - attacker.lastChainTick > CombatConfig.ChainResetTime then
		M1Handler.ResetChain(attacker)
	end

	local newIdx = attacker.chainIndex + 1
	if newIdx > CombatConfig.ChainCount then
		M1Handler.ResetChain(attacker)
		newIdx = 1
	end

	local startedNewChain = (newIdx == 1)
	attacker.chainIndex = newIdx
	attacker.lastM1Tick = now
	attacker.lastChainTick = now
	attacker.chainActive = true
	attacker.dirty = true

	if startedNewChain then
		attacker.chainSpaceFlag = attacker.jumpHeld
	end

	-- Server-side anim for dummies
	if attacker.isDummy then
		EntityAnim.Play(attacker, "M1_" .. tostring(newIdx))
	end

	fireToOwner(attacker, {
		kind = "Swing",
		chainIndex = newIdx,
		attackerId = attacker.model:GetAttribute("EntityId") :: number,
	})
	-- Also broadcast Swing so other nearby players hear the swing sound for dummies
	if attacker.isDummy then
		broadcast({
			kind = "Swing",
			chainIndex = newIdx,
			attackerId = attacker.model:GetAttribute("EntityId") :: number,
		}, attacker.rootPart.Position)
	end

	local windup = CombatConfig.SwingWindup[newIdx] or 0.12
	local scheduledTick = now
	task.delay(windup, function()
		if not attacker.model.Parent then return end
		if attacker.lastM1Tick ~= scheduledTick then return end
		if attacker.humanoid.Health <= 0 then return end
		resolveHitbox(attacker, newIdx)
	end)
end

return M1Handler