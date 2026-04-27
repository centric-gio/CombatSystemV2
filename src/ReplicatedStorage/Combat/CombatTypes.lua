--!strict

local CombatTypes = {}

export type EntityState = {
	-- Identity
	model: Model,
	humanoid: Humanoid,
	rootPart: BasePart,
	player: Player?,            -- nil for dummies
	isDummy: boolean,
	dummyAIType: string?,       -- "Idle" | "Blocking" | "Attacking" | "PerfectBlock"
	spawnedBy: Player?,
	spawnTick: number,

	-- Chain
	chainIndex: number,
	lastM1Tick: number,
	lastChainTick: number,
	chainActive: boolean,
	chainSpaceFlag: boolean,    -- spacebar held continuously through chain

	-- Hit counter
	hitCount: number,
	lastHitTick: number,

	-- Block
	blocking: boolean,
	blockStartTick: number,
	blockMeter: number,
	isBlockBroken: boolean,

	-- Stun
	stunUntil: number,

	-- Input mirror (player only)
	jumpHeld: boolean,

	-- Dirty flag for state sync
	dirty: boolean,
	
	toolEquipped: boolean,
	animTracks: { [string]: AnimationTrack }?,
}

-- Combat event payload kinds (server → client)
export type CombatEventPayload = {
	kind: string,               -- "Swing" | "Hit" | "BlockedHit" | "PerfectBlocked" | "BlockBroken" | "Knockback" | "Updraft" | "Flinch" | "Stagger"
	chainIndex: number?,
	attackerId: number?,
	victimId: number?,
	hitCount: number?,
}

-- StateSync payload (server → client owner only)
export type StateSyncPayload = {
	chainIndex: number,
	chainActive: boolean,
	blockMeter: number,
	blocking: boolean,
	isBlockBroken: boolean,
	stunUntil: number,
	hitCount: number,
	nowServer: number,
	perfectBlockWindowEnd: number,  -- absolute time the perfect-block window ends, or 0
}

return CombatTypes