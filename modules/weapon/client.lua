if not lib then return end

local Weapon = {}
local Items = require 'modules.items.client'
local Utils = require 'modules.utils.client'

local Inventory = require 'modules.inventory.client'

-- generic group animation data
local anims = {}
anims[`GROUP_MELEE`] = { 'melee@holster', 'unholster', 200, 'melee@holster', 'holster', 600 }
anims[`GROUP_PISTOL`] = { 'reaction@intimidation@cop@unarmed', 'intro', 400, 'reaction@intimidation@cop@unarmed', 'outro', 450 }
anims[`GROUP_STUNGUN`] = anims[`GROUP_PISTOL`]

local function vehicleIsCycle(vehicle)
	local class = GetVehicleClass(vehicle)
	return class == 8 or class == 13
end

local needAmmo = {}
needAmmo[`group_thrown`] = true
needAmmo[`group_bow`] = true

local fuelWeapons = {}
fuelWeapons[`WEAPON_MELEE_LANTERN`] = true
fuelWeapons[`WEAPON_MELEE_DAVY_LANTERN`] = true
fuelWeapons[`WEAPON_MELEE_LANTERN_HALLOWEEN`] = true
fuelWeapons[`WEAPON_MELEE_TORCH`] = true

local inspectGroups = {
	[970310034]		= true,
	[-594562071]	= true,
	[416676503]		= true,
	[-1212426201]	= true,
	[-1101297303]	= true,
	[860033945]		= true	
}

function Weapon.Equip(item, data)
	local playerPed = cache.ped
	local coords = GetEntityCoords(playerPed, true)

	-- Cannot equip if carrying ped

	if client.weaponanims then
		goto skipAnim
	end

	::skipAnim::

	item.hash = joaat(data.name)

	item.timer = 0
	item.group = GetWeapontypeGroup(item.hash)
	item.throwable = (item.group == `group_thrown`) -- To Handle thrown weapons
	item.melee = (item.group == `group_melee`) and 0 or nil -- To Handle melee weapons
	item.fuel = fuelWeapons[item.hash] -- To Handle handheld weapons like torch and lanterns
	item.attachPoint = data.attachPoint or 0
	item.allowedAmmos = Items(item.name).allowedAmmos or nil
	item.canInspect = inspectGroups[item.group] -- To Handle Rust/Dirt
	item.canFire = true -- To handle bow thing until a solution to not unequip bow on 0 ammo

	if not HasPedGotWeapon(playerPed, item.hash, 0, true) then
		if needAmmo[item.group] then
			GiveWeaponToPed_2(playerPed, item.hash, 1, false, true, 0, false, 0.5, 1.0, 752097756, false, 0.0, false)
		else
			GiveWeaponToPed_2(playerPed, item.hash, 0, false, true, 0, false, 0.5, 1.0, 752097756, false, 0.0, false)
		end
		print('Gave Weapon')
	else
		--Citizen.InvokeNative(0x13D234A2A3F66E63, PlayerPedId())
		print('Already Has Weapon')
	end
	--[[
		WIP : 
		SetPlayerMaxAmmoOverrideForAmmoType
	]]
	-- This was changed while giving weapon as need ammo for some weapons
	if not needAmmo[item.group] then
		print('Not Bow/Thrown Group So Removing all old ammo')
		Citizen.InvokeNative(0x1B83C0DEEBCBB214, playerPed) -- Remove All Ped Ammo
	end
	if item.metadata?.ammoType and item.metadata?.ammo > 0  then
		print('Loaded Ammo :',item.metadata?.ammo or 0)
		Citizen.InvokeNative(0x106A811C6D3035F3, playerPed, joaat(item.metadata?.ammoType), tonumber(item.metadata?.ammo), `ADD_REASON_DEFAULT`) --AddAmmoToPedByType
		Citizen.InvokeNative(0xCC9C4393523833E2, playerPed, item.hash, joaat(item.metadata?.ammoType))
	end
	if item.group == `group_bow` and (item.metadata?.ammoType ~= nil) and (item.metadata?.ammoType ~= 'AMMO_ARROW') and (GetPedAmmoByType(playerPed, `AMMO_ARROW`) > 0) then
		print('Removing Default Ammo of AMMO_ARROW type Gave to Equip Bow')
		Citizen.InvokeNative(0xB6CFEC32E3742779,playerPed, `AMMO_ARROW`, GetPedAmmoByType(playerPed, `AMMO_ARROW`), `REMOVE_REASON_DEBUG`) --RemoveAmmoFromPedByType
	elseif item.group == `group_bow` and (item.metadata?.ammoType ~= nil) and (item.metadata?.ammoType == 'AMMO_ARROW') then
		print('Removing '..(GetPedAmmoByType(playerPed, `AMMO_ARROW`) - item.metadata?.ammo)..'x Ammo of AMMO_ARROW type Gave to Equip Bow')
		Citizen.InvokeNative(0xB6CFEC32E3742779,playerPed, `AMMO_ARROW`, (GetPedAmmoByType(playerPed, `AMMO_ARROW`) - item.metadata?.ammo), `REMOVE_REASON_DEBUG`) --RemoveAmmoFromPedByType
	elseif item.group == `group_bow` and (item.metadata?.ammoType == nil) then
		item.canFire = false
		lib.notify({ id = 'weapon_equip', type = 'error', description = 'Please Equip Arrows to use bow.' })
	end

	SetCurrentPedWeapon(playerPed, item.hash, false, 0, false, false)
	
	local WeaponObject = GetCurrentPedWeaponEntityIndex(playerPed , 0)
	local count = 0
	while WeaponObject == 0 do 
		print('Waiting for weapon')
		count = count + 1
		if count > 20 then print('Failed to get Weapon Obj') return end
		WeaponObject = GetCurrentPedWeaponEntityIndex(playerPed , 0)
		Wait(100)
	end
	item.weaponObject = WeaponObject
	Citizen.InvokeNative(0xA7A57E89E965D839 ,item.weaponObject , tonumber(1 - (item.metadata?.durability / 100))) --SetWeaponDegradation
	if item.metadata?.rust > 0 then
		Citizen.InvokeNative(0xE22060121602493B ,item.weaponObject , tonumber((item.metadata?.rust / 100))) --SetWeaponRust
	elseif item.metadata?.dirt > 0 then
		Citizen.InvokeNative(0x812CE61DEBCAB948 ,item.weaponObject , tonumber((item.metadata?.dirt / 100))) --SetWeaponDirt
	end

	TriggerEvent('ox_inventory:currentWeapon', item)
	Utils.ItemNotify({ item, 'ui_equipped' })

	return item
end

function Weapon.Disarm(currentWeapon, noAnim, hide)
	if currentWeapon?.timer then
		currentWeapon.timer = nil

		if source == '' then
			TriggerServerEvent('ox_inventory:updateWeapon')
		end

		--SetPedAmmo(cache.ped, currentWeapon.hash, 0)
		Citizen.InvokeNative(0x1B83C0DEEBCBB214, playerPed) -- Remove All Ped Ammo

		if client.weaponanims and not noAnim then
			if cache.vehicle and vehicleIsCycle(cache.vehicle) then
				goto skipAnim
			end

			--ClearPedSecondaryTask(cache.ped)

			local item = Items[currentWeapon.name]
			local coords = GetEntityCoords(cache.ped, true)
			local anim = item.anim or anims[GetWeapontypeGroup(currentWeapon.hash)]

			if anim == anims[`GROUP_PISTOL`] and not client.hasGroup(shared.police) then
				anim = nil
			end

			local sleep = anim and anim[6] or 1400

			--Utils.PlayAnimAdvanced(sleep, anim and anim[4] or 'reaction@intimidation@1h', anim and anim[5] or 'outro', coords.x, coords.y, coords.z, 0, 0, GetEntityHeading(cache.ped), 8.0, 3.0, sleep, 50, 0)
		end

		::skipAnim::

		Utils.ItemNotify({ currentWeapon, 'ui_holstered' })
		TriggerEvent('ox_inventory:currentWeapon')
	end


	--Utils.WeaponWheel()
	--SetPedCurrentWeaponVisible(cache.ped, false, false, false, false) -- No Anim, wapon stay
	if hide == false then
		Citizen.InvokeNative(0xFCCC886EDE3C63EC, cache.ped, 2, false) -- Holster Animation, weapon stay [HidePedWeapons]
		Wait(100)
		RemoveWeaponFromPed(cache.ped, currentWeapon.hash, true, `REMOVE_REASON_DEFAULT`) -- Remove Weapon From Body
		Citizen.InvokeNative(0x1B83C0DEEBCBB214, cache.ped) -- Remove All Ped Ammo
		print('Weapon Removed :', currentWeapon.name)
    else
		RemoveAllPedWeapons(cache.ped, true, true)
	end
	if currentWeapon?.fuel then
		if currentWeapon.name == 'WEAPON_MELEE_TORCH' then
			TriggerServerEvent('ox_inventory:removeItem', 'WEAPON_MELEE_TORCH', 1, nil, currentWeapon.slot)
		else
			TriggerServerEvent('ox_inventory:updateWeapon', 'fuel', currentWeapon.metadata.durability) 
		end
	end
	--RemoveAllPedWeapons(cache.ped, true, true) -- No anim, weapon removed
end

function Weapon.ClearAll(currentWeapon)
	Weapon.Disarm(currentWeapon)

	if client.parachute then
		local chute = `GADGET_PARACHUTE`
		GiveWeaponToPed(cache.ped, chute, 0, true, false)
		SetPedGadget(cache.ped, chute, true)
	end
end

function Weapon.Inspect(currentWeapon)
end

Utils.Disarm = Weapon.Disarm
Utils.ClearWeapons = Weapon.ClearAll

return Weapon
