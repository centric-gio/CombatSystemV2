--!strict
local CombatTypes = {}

export type EntityState = {
	model: Model,
	humanoid: Humanoid,
	rootPart: BasePart,
	player: Player?,
	isDummy: boolean,
	dummyAIType: string?,
	spawnedBy: Player?,
	spawnTick: number,

	chainIndex: number,
	lastM1Tick: number,
	lastChainTick: number,
	chainActive: boolean,

	hitCount: number,
	lastHitTick: number,

	blocking: boolean,
	blockStartTick: number,
	blockMeter: number,
	isBlockBroken: boolean,

	stunUntil: number,
	jumpHeld: boolean,
	dirty: boolean,

	toolEquipped: boolean,
	animTracks: { [string]: AnimationTrack }?,
}

export type CombatEventPayload = {
	kind: string,
	chainIndex: number?,
	attackerId: number?,
	victimId: number?,
	hitCount: number?,
}

export type StateSyncPayload = {
	chainIndex: number,
	chainActive: boolean,
	blockMeter: number,
	blocking: boolean,
	isBlockBroken: boolean,
	stunUntil: number,
	hitCount: number,
	nowServer: number,
	perfectBlockWindowEnd: number,
}

return CombatTypes