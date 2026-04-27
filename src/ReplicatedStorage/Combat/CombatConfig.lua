--!strict
local CombatConfig = {}

-- ════════ M1 CHAIN ════════
CombatConfig.M1Cooldown            = 0.2
CombatConfig.ChainCount            = 5
CombatConfig.ChainResetTime        = 5.00
CombatConfig.SwingWindup           = { [1] = 0.12, [2] = 0.10,[3] = 0.12, [4] = 0.10, [5] = 0.18 }

-- ════════ HITBOX ════════
CombatConfig.HitboxSize            = Vector3.new(7, 6, 7)
CombatConfig.HitboxForwardOffset   = 3.5
CombatConfig.MaxHitDistance        = 12

-- ════════ DAMAGE ════════
CombatConfig.BaseDamage            = 7
CombatConfig.FinalHitMultiplier    = 1.5

-- ════════ STUNS (seconds) ════════
CombatConfig.HitFlinchStun         = 0.35
CombatConfig.KnockbackStun         = 0.90
CombatConfig.UpdraftStun           = 1.05
CombatConfig.BlockBreakStun        = 2.50
CombatConfig.PerfectBlockStaggerStun = 1.40

-- ════════ LUNGE & PUSHBACK (Hits 1-4) ════════
CombatConfig.AttackerLungeVelocity = 15     
CombatConfig.AttackerLungeDuration = 0.15   
CombatConfig.VictimPushbackVelocity = 14    
CombatConfig.VictimPushbackDuration = 0.15

-- ════════ FINAL HIT IMPULSES (Hit 5) ════════
CombatConfig.KnockbackVelocity     = 30
CombatConfig.KnockbackDuration     = 0.22
CombatConfig.UpdraftHeight         = 18     
CombatConfig.UpdraftAscentTime     = 0.20   
CombatConfig.UpdraftHangTime       = 0.60   

-- ════════ BLOCK ════════
CombatConfig.BlockMeterMax           = 100
CombatConfig.BlockDrainPerSecond     = 0   -- Passive drain while blocking
CombatConfig.BlockRegenPerSecond     = 35   -- Passive regen when NOT blocking
CombatConfig.BlockDrainPerHit        = 8
CombatConfig.BlockWalkspeedMultiplier = 0.55
CombatConfig.PerfectBlockWindow      = 0.12

-- ════════ SCREEN SHAKE ════════
CombatConfig.ShakeIntensity        = 0.3
CombatConfig.ShakeDuration         = 0.18

-- ════════ MOVEMENT ════════
CombatConfig.DefaultWalkSpeed      = 16
CombatConfig.DefaultJumpPower      = 50
CombatConfig.DefaultJumpHeight     = 7.2 

-- ════════ TOOL ════════
CombatConfig.ToolName              = "Combat"

-- ════════ NETWORKING ════════
CombatConfig.MinClientM1Interval   = 0.30
CombatConfig.BroadcastRange        = 120
CombatConfig.DummyLifetime         = 30
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