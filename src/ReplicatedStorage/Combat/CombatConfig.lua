--!strict

local CombatConfig = {}

-- ════════ M1 CHAIN ════════
CombatConfig.M1Cooldown            = 0.2   -- min seconds between M1 inputs
CombatConfig.ChainCount            = 5
CombatConfig.ChainResetTime        = 5.00   -- inactivity before chain resets
CombatConfig.SwingWindup           = {       -- input → hitbox-active delay per chain idx
	[1] = 0.12, [2] = 0.10, [3] = 0.12, [4] = 0.10, [5] = 0.18,
}

-- ════════ HITBOX ════════
CombatConfig.HitboxSize            = Vector3.new(7, 6, 7)
CombatConfig.HitboxForwardOffset   = 3.5    -- studs ahead of HRP
CombatConfig.MaxHitDistance        = 12     -- anti-cheat: hard cap

-- ════════ DAMAGE ════════
CombatConfig.BaseDamage            = 7
CombatConfig.FinalHitMultiplier    = 1.5    -- 5th hit damage multiplier

-- ════════ STUNS (seconds) ════════
CombatConfig.HitFlinchStun         = 0
CombatConfig.KnockbackStun         = 0.90
CombatConfig.UpdraftStun           = 1.00
CombatConfig.BlockBreakStun        = 2.50
CombatConfig.PerfectBlockStaggerStun = 1.40

-- ════════ MOVEMENT IMPULSES (LinearVelocity) ════════
CombatConfig.KnockbackVelocity     = 75     -- studs/sec horizontal
CombatConfig.KnockbackDuration     = 0.22
CombatConfig.UpdraftUpVelocity     = 55     -- studs/sec vertical
CombatConfig.UpdraftDuration       = 0.32
CombatConfig.StaggerVelocity       = 32
CombatConfig.StaggerDuration       = 0.18

-- ════════ BLOCK ════════
CombatConfig.BlockMeterMax           = 100
CombatConfig.BlockDrainPerSecond     = 18    -- passive drain while held
CombatConfig.BlockDrainPerHit        = 8     -- additional drain on blocked hit
CombatConfig.BlockWalkspeedMultiplier = 0.55
CombatConfig.PerfectBlockWindow      = 0.12  -- post-StartBlock parry window

-- ════════ MOVEMENT ════════
CombatConfig.DefaultWalkSpeed      = 16
CombatConfig.DefaultJumpPower      = 50
CombatConfig.DefaultJumpHeight     = 7.2 

-- ════════ TOOL ════════
CombatConfig.ToolName              = "CombatSword"

-- ════════ NETWORKING ════════
CombatConfig.MinClientM1Interval   = 0.30   -- client-side rate limit
CombatConfig.BroadcastRange        = 120    -- studs (event replication scope)

-- ════════ DUMMIES ════════
CombatConfig.DummyLifetime         = 30     -- seconds
CombatConfig.DummyAttackInterval   = 0.55
CombatConfig.DummyAggroRange       = 18
CombatConfig.DummyMeleeRange       = 5

-- ════════ ASSET IDS ════════
CombatConfig.Animations = {
	Flinch         = 116027285222276,
	BlockBroken    = 91395768560395,
	Block          = 83146853780823,
	M1_1           = 124192568876661,
	M1_2           = 87768775093348,
	M1_3           = 124082988225751,
	M1_4           = 87768775093348,
	M1_5           = 124082988225751,
	PerfectBlocked = 100679173821281,
}

CombatConfig.Sounds = {
	M1Swing     = 139731037802687,
	Hit         = 139890294541073,
	BlockedHit  = 136811265205147,
	Parried     = 116964347071838,
	BlockBroken = 85805517776968,
}

return CombatConfig