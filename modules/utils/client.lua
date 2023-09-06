if not lib then return end

local Utils = {}


function Utils.PlayAnim(wait, dict, name, blendIn, blendOut, duration, flag, rate, lockX, lockY, lockZ)
	lib.requestAnimDict(dict)
	TaskPlayAnim(cache.ped, dict, name, blendIn, blendOut, duration, flag, rate, lockX, lockY, lockZ)
	RemoveAnimDict(dict)

	if wait > 0 then Wait(wait) end
end

function Utils.PlayAnimAdvanced(wait, dict, name, posX, posY, posZ, rotX, rotY, rotZ, blendIn, blendOut, duration, flag, time)
	lib.requestAnimDict(dict)
	TaskPlayAnimAdvanced(cache.ped, dict, name, posX, posY, posZ, rotX, rotY, rotZ, blendIn, blendOut, duration, flag, time, 0, 0)
	RemoveAnimDict(dict)

	if wait > 0 then Wait(wait) end
end

---@param flag number
---@param destination? vector3
---@param size? number
---@return number | false
---@return number?
function Utils.Raycast(flag, destination, size)
	local playerCoords = GetEntityCoords(cache.ped)
	destination = destination or GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.2, -0.25)
	local rayHandle = StartShapeTestCapsule(playerCoords.x, playerCoords.y, playerCoords.z + 0.5, destination.x, destination.y, destination.z, size or 2.2, flag or 30, cache.ped, 4)
	while true do
		Wait(0)
		local result, _, coords, _, entityHit = GetShapeTestResult(rayHandle)
		if result ~= 1 then
            -- DrawLine(playerCoords.x, playerCoords.y, playerCoords.z + 0.5, destination.x, destination.y, destination.z, 0, 0, 255, 255)
            -- DrawLine(playerCoords.x, playerCoords.y, playerCoords.z + 0.5, coords.x, coords.y, coords.z, 255, 0, 0, 255)
			local entityType
			if entityHit then entityType = GetEntityType(entityHit) end
			if entityHit and entityType ~= 0 then
				return entityHit, entityType
			end
			return false
		end
	end
end

function Utils.GetClosestPlayer()
	local players = GetActivePlayers()
	local playerCoords = GetEntityCoords(cache.ped)
	local targetDistance, targetId, targetPed

	for i = 1, #players do
		local player = players[i]

		if player ~= cache.playerId then
			local ped = GetPlayerPed(player)
			local distance = #(playerCoords - GetEntityCoords(ped))

			if distance < (targetDistance or 2) then
				targetDistance = distance
				targetId = player
				targetPed = ped
			end
		end
	end

	return targetId, targetPed
end

-- Replace ox_inventory notify with ox_lib (backwards compatibility)
function Utils.Notify(data)
	data.description = data.text
	data.text = nil
	lib.notify(data)
end

RegisterNetEvent('ox_inventory:notify', Utils.Notify)
exports('notify', Utils.Notify)

function Utils.ItemNotify(data)
	if not client.itemnotify then
		return
	end

	SendNUIMessage({action = 'itemNotify', data = data})
end

RegisterNetEvent('ox_inventory:itemNotify', Utils.ItemNotify)

---@deprecated
function Utils.DeleteObject(obj)
	SetEntityAsMissionEntity(obj, false, true)
	DeleteObject(obj)
end

function Utils.DeleteEntity(entity)
	if DoesEntityExist(entity) then
		SetEntityAsMissionEntity(entity, false, true)
		DeleteEntity(entity)
	end
end

local rewardTypes = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 7 | 1 << 10

-- Enables the weapon wheel, but disables the use of inventory items
-- Mostly used for weaponised vehicles, though could be called for "minigames"
function Utils.WeaponWheel(state)
	if state == nil then state = EnableWeaponWheel end

	EnableWeaponWheel = state
	SetWeaponsNoAutoswap(not state)
	SetWeaponsNoAutoreload(not state)

	if client.suppresspickups then
		-- CLEAR_PICKUP_REWARD_TYPE_SUPPRESSION | SUPPRESS_PICKUP_REWARD_TYPE
		return state and N_0x762db2d380b48d04(rewardTypes) or N_0xf92099527db8e2a7(rewardTypes, true)
	end
end

exports('weaponWheel', Utils.WeaponWheel)

function Utils.CreateBlip(settings, coords)
	local blip = Citizen.InvokeNative(0x554D9D53F696D002,1664425300,coords.x, coords.y, coords.z)
	SetBlipSprite(blip, settings.id)
	--SetBlipDisplay(blip, 4)
	SetBlipScale(blip, settings.scale)
	--SetBlipColour(blip, settings.colour)
	--SetBlipAsShortRange(blip, true)
	-- BeginTextCommandSetBlipName(settings.name)
	-- EndTextCommandSetBlipName(blip)
	Citizen.InvokeNative(0x9CB1A1623062F402, blip, settings.name)
	return blip
end

--[[
    DATAVIEW
]]

local _strblob = string.blob or function(length)
    return string.rep("\0", math.max(40 + 1, length))
end

local DataView = {
    EndBig = ">",
    EndLittle = "<",
    Types = {
        Int8 = { code = "i1", size = 1 },
        Uint8 = { code = "I1", size = 1 },
        Int16 = { code = "i2", size = 2 },
        Uint16 = { code = "I2", size = 2 },
        Int32 = { code = "i4", size = 4 },
        Uint32 = { code = "I4", size = 4 },
        Int64 = { code = "i8", size = 8 },
        Uint64 = { code = "I8", size = 8 },
 
        LuaInt = { code = "j", size = 8 }, -- a lua_Integer
        UluaInt = { code = "J", size = 8 }, -- a lua_Unsigned
        LuaNum = { code = "n", size = 8}, -- a lua_Number
        Float32 = { code = "f", size = 4 }, -- a float (native size)
        Float64 = { code = "d", size = 8 }, -- a double (native size)
        String = { code = "z", size = -1, }, -- zero terminated string
    },
 
    FixedTypes = {
        String = { code = "c", size = -1, }, -- a fixed-sized string with n bytes
        Int = { code = "i", size = -1, }, -- a signed int with n bytes
        Uint = { code = "I", size = -1, }, -- an unsigned int with n bytes
    },
}

DataView.__index = DataView
 
--[[ Is a dataview type at a specific offset still within buffer length --]]
local function _ib(o, l, t) return ((t.size < 0 and true) or (o + (t.size - 1) <= l)) end
local function _ef(big) return (big and DataView.EndBig) or DataView.EndLittle end
 
--[[ Helper function for setting fixed datatypes within a buffer --]]
local SetFixed = nil
 
--[[ Create an ArrayBuffer with a size in bytes --]]
function DataView.ArrayBuffer(length)
    return setmetatable({
        offset = 1, length = length, blob = _strblob(length)
    }, DataView)
end
 
--[[ Wrap a non-internalized string --]]
function DataView.Wrap(blob)
    return setmetatable({
        offset = 1, blob = blob, length = blob:len(),
    }, DataView)
end
 
function DataView:Buffer() return self.blob end
function DataView:ByteLength() return self.length end
function DataView:ByteOffset() return self.offset end
function DataView:SubView(offset)
    return setmetatable({
        offset = offset, blob = self.blob, length = self.length,
    }, DataView)
end
 
--[[ Create the API by using DataView.Types. --]]
for label,datatype in pairs(DataView.Types) do
    DataView["Get" .. label] = function(self, offset, endian)
        local o = self.offset + offset
        if _ib(o, self.length, datatype) then
            local v,_ = string.unpack(_ef(endian) .. datatype.code, self.blob, o)
            return v
        end
        return nil -- Out of bounds
    end
 
    DataView["Set" .. label] = function(self, offset, value, endian)
        local o = self.offset + offset
        if _ib(o, self.length, datatype) then
            return SetFixed(self, o, value, _ef(endian) .. datatype.code)
        end
        return self -- Out of bounds
    end
 
    -- Ensure cache is correct.
    if datatype.size >= 0 and string.packsize(datatype.code) ~= datatype.size then
        local msg = "Pack size of %s (%d) does not match cached length: (%d)"
        error(msg:format(label, string.packsize(fmt[#fmt]), datatype.size))
        return nil
    end
end
 
for label,datatype in pairs(DataView.FixedTypes) do
    DataView["GetFixed" .. label] = function(self, offset, typelen, endian)
        local o = self.offset + offset
        if o + (typelen - 1) <= self.length then
            local code = _ef(endian) .. "c" .. tostring(typelen)
            local v,_ = string.unpack(code, self.blob, o)
            return v
        end
        return nil -- Out of bounds
    end
 
    DataView["SetFixed" .. label] = function(self, offset, typelen, value, endian)
        local o = self.offset + offset
        if o + (typelen - 1) <= self.length then
            local code = _ef(endian) .. "c" .. tostring(typelen)
            return SetFixed(self, o, value, code)
        end
        return self
    end
end
 
--[[ Helper function for setting fixed datatypes within a buffer --]]
SetFixed = function(self, offset, value, code)
    local fmt = { }
    local values = { }
 
    -- All bytes prior to the offset
    if self.offset < offset then
        local size = offset - self.offset
        fmt[#fmt + 1] = "c" .. tostring(size)
        values[#values + 1] = self.blob:sub(self.offset, size)
    end
 
    fmt[#fmt + 1] = code
    values[#values + 1] = value
 
    -- All bytes after the value (offset + size) to the end of the buffer
    -- growing the buffer if needed.
    local ps = string.packsize(fmt[#fmt])
    if (offset + ps) <= self.length then
        local newoff = offset + ps
        local size = self.length - newoff + 1
 
        fmt[#fmt + 1] = "c" .. tostring(size)
        values[#values + 1] = self.blob:sub(newoff, self.length)
    end
 
    self.blob = string.pack(table.concat(fmt, ""), table.unpack(values))
    self.length = self.blob:len()
    return self
end

Utils.DataView = DataView

return Utils
