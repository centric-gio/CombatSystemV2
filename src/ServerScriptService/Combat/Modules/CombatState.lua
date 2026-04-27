--!strict

local CombatTypes = require(game:GetService("ReplicatedStorage").Combat.CombatTypes)
local CombatConfig = require(game:GetService("ReplicatedStorage").Combat.CombatConfig)

type EntityState = CombatTypes.EntityState

local CombatState = {}

local _entities: { [Model]: EntityState } = {}
local _byEntityId: { [number]: EntityState } = {}
local _nextEntityId: number = 1

local function newEntityId(): number
	local id = _nextEntityId
	_nextEntityId += 1
	return id
end

function CombatState.Register(
	model: Model,
	humanoid: Humanoid,
	rootPart: BasePart,
	player: Player?,
	isDummy: boolean,
	dummyAIType: string?,
	spawnedBy: Player?
): EntityState
	local now = os.clock()
	local id = newEntityId()
	model:SetAttribute("EntityId", id)

	local state: EntityState = {
		model = model,
		humanoid = humanoid,
		rootPart = rootPart,
		player = player,
		isDummy = isDummy,
		dummyAIType = dummyAIType,
		spawnedBy = spawnedBy,
		spawnTick = now,

		chainIndex = 0,
		lastM1Tick = 0,
		lastChainTick = 0,
		chainActive = false,
		chainSpaceFlag = false,

		hitCount = 0,
		lastHitTick = 0,

		blocking = false,
		blockStartTick = 0,
		blockMeter = CombatConfig.BlockMeterMax,
		isBlockBroken = false,

		stunUntil = 0,
		jumpHeld = false,
		dirty = true,
		
		toolEquipped = false,
		animTracks = nil,
	}

	_entities[model] = state
	_byEntityId[id] = state
	return state
end

function CombatState.Unregister(model: Model)
	local state = _entities[model]
	if not state then return end
	local id = model:GetAttribute("EntityId")
	if typeof(id) == "number" then
		_byEntityId[id] = nil
	end
	_entities[model] = nil
end

function CombatState.Get(model: Model?): EntityState?
	if not model then return nil end
	return _entities[model]
end

function CombatState.GetByPlayer(player: Player): EntityState?
	local char = player.Character
	if not char then return nil end
	return _entities[char]
end

function CombatState.GetById(id: number): EntityState?
	return _byEntityId[id]
end

function CombatState.All(): { EntityState }
	local list: { EntityState } = {}
	for _, state in pairs(_entities) do
		table.insert(list, state)
	end
	return list
end

return CombatState