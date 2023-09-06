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

----- INSPECT ----------

local function InventoryGetGuidFromItemId(inventoryId, itemDataBuffer, category, slotId, outItemBuffer) return Citizen.InvokeNative(0x886DFD3E185C8A89, inventoryId, itemDataBuffer, category, slotId, outItemBuffer) end
local function SetWeaponDegradation(weaponObject, float) Citizen.InvokeNative(0xA7A57E89E965D839, weaponObject, float, Citizen.ResultAsFloat()) end
local function SetWeaponDamage(weaponObject, float, p2) Citizen.InvokeNative(0xE22060121602493B, weaponObject, float, p2) end
local function SetWeaponDirt(weaponObject, float, p2) Citizen.InvokeNative(0x812CE61DEBCAB948, weaponObject, float, p2) end
local function SetWeaponSoot(weaponObject, float, p2) Citizen.InvokeNative(0xA9EF4AD10BDDDB57, weaponObject, float, p2) end
local function DisableControlAction(padIndex, control, disable) Citizen.InvokeNative(0xFE99B66D079CF6BC, padIndex, control, disable) end
local function IsPedRunningInspectionTask(ped) return Citizen.InvokeNative(0x038B1F1674F0E242, ped) end
local function SetPedBlackboardBool(ped, visibleName, value, removeTimer) return Citizen.InvokeNative(0xCB9401F918CB0F75, ped, visibleName, value, removeTimer)  end
local function GetWeaponDamage(weaponObject) return Citizen.InvokeNative(0x904103D5D2333977, weaponObject, Citizen.ResultAsFloat())  end
local function GetWeaponDirt(weaponObject) return Citizen.InvokeNative(0x810E8AE9AFEA7E54, weaponObject, Citizen.ResultAsFloat()) end
local function GetWeaponSoot(weaponObject) return Citizen.InvokeNative(0x4BF66F8878F67663, weaponObject, Citizen.ResultAsFloat())  end
local function GetWeaponDegradation(weaponObject) return Citizen.InvokeNative(0x0D78E1097F89E637, weaponObject, Citizen.ResultAsFloat()) end
local function GetWeaponPermanentDegradation(weaponObject) return Citizen.InvokeNative(0xD56E5F336C675EFA, weaponObject, Citizen.ResultAsFloat()) end
local function GetWeaponName(weaponHash) return Citizen.InvokeNative(0x89CF5FF3D363311E,weaponHash,Citizen.ResultAsString()) end
local function GetWeaponNameWithPermanentDegradation(weaponHash, value) return Citizen.InvokeNative(0x7A56D66C78D8EF8E, weaponHash, value, Citizen.ResultAsString()) end
local function IsEntityDead(entity) return Citizen.InvokeNative(0x7D5B1F88E7504BBA, entity) end
local function IsPedSwimming(ped) return Citizen.InvokeNative(0x9DE327631295B4C2, ped) end
local function IsWeaponOneHanded(hash) return Citizen.InvokeNative(0xD955FEE4B87AFA07, hash) end
local function IsWeaponTwoHanded(hash) return Citizen.InvokeNative(0x0556E9D2ECF39D01, hash) end
local function GetObjectIndexFromEntityIndex(entity) return Citizen.InvokeNative(0x280BBE5601EAA983, entity) end
local function GetCurrentPedWeaponEntityIndex(ped, attachPoint) return Citizen.InvokeNative(0x3B390A939AF0B5FC, ped, attachPoint) end
local function GetItemInteractionFromPed(ped) return Citizen.InvokeNative(0x6AA3DCA2C6F5EB6D,ped) end
local function DisableOnFootFirstPersonViewThisUpdate() return Citizen.InvokeNative(0x9C473089A934C930) end

local function shouldContinueInspect(player)
  if IsEntityDead(player) or IsPedSwimming(player) or not IsPedRunningInspectionTask(player) then
    return false
  end
  return true
end

local function getGuidFromItemId(inventoryId, itemData, category, slotId)
  local outItem = Utils.DataView.ArrayBuffer(4 * 8)

  -- INVENTORY_GET_GUID_FROM_ITEMID
  local success = InventoryGetGuidFromItemId(inventoryId, itemData or 0, category, slotId, outItem:Buffer())

  return success and outItem or nil
end

local function getWeaponStruct(weaponHash)
	local charStruct = getGuidFromItemId(1, nil, GetHashKey("CHARACTER"), -1591664384)
	local unkStruct = getGuidFromItemId(1, charStruct:Buffer(), 923904168, -740156546)
	local weaponStruct = getGuidFromItemId(1, unkStruct:Buffer(), weaponHash, -1591664384)
	return weaponStruct
end

-- Actions to perform before closing inspection
local function cleanupInspectionMenu(uiFlowBlock, uiContainer)
	Citizen.InvokeNative(0x4EB122210A90E2D8, -813354801)
	DatabindingRemoveDataEntry(uiContainer)
	--ReleaseFlowBlock(uiFlowBlock) --Citizen.InvokeNative(0xF320A77DD5F781DF, uiFlowBlock)
	Citizen.InvokeNative(0x8BC7C1F929D07BF3, GetHashKey("HUD_CTX_INSPECT_ITEM")) -- DisableHUDComponent
end

local function updateWeaponStats(player, uiContainer, weaponHash)
  
end

local function initialize(player, weaponHash, bottomText)
	local uiFlowBlock = RequestFlowBlock(GetHashKey("PM_FLOW_WEAPON_INSPECT"))

	local uiContainer = DatabindingAddDataContainerFromPath("", "ItemInspection")
	DatabindingAddDataBool(uiContainer, "Visible", true)

	-- Update Stats in UI
	Citizen.InvokeNative(0x46DB71883EE9D5AF, uiContainer, "stats", getWeaponStruct(weaponHash):Buffer(), player)

	DatabindingAddDataString(uiContainer, "tipText", tostring(bottomText))
	-- Use this if planned rust, dirt and degrade clean differently to show current work
	DatabindingAddDataHash(uiContainer, "itemLabel", GetHashKey(GetWeaponName(weaponHash)))

	Citizen.InvokeNative(0x10A93C057B6BD944, uiFlowBlock)
	Citizen.InvokeNative(0x3B7519720C9DCB45, uiFlowBlock, 0)
	Citizen.InvokeNative(0x4C6F2C4B7A03A266, -813354801, uiFlowBlock)

	Citizen.InvokeNative(0x4CC5F2FC1332577F, GetHashKey("HUD_CTX_INSPECT_ITEM")) -- Remove Map UI 

	return uiFlowBlock, uiContainer
end

local function createStateMachine(uiFlowBlock)
  if not Citizen.InvokeNative(0x10A93C057B6BD944, uiFlowBlock) --[[ UIFLOWBLOCK_IS_LOADED ]] then
    print("uiflowblock failed to load")
    return 0
  end

  Citizen.InvokeNative(0x3B7519720C9DCB45, uiFlowBlock, 0) -- UIFLOWBLOCK_ENTER

  if not Citizen.InvokeNative(0x5D15569C0FEBF757, -813354801) --[[ UI_STATE_MACHINE_EXISTS ]] then
    if not Citizen.InvokeNative(0x4C6F2C4B7A03A266, -813354801, uiFlowBlock) --[[ UI_STATE_MACHINE_CREATE ]] then
      print("uiStateMachine wasn't created")
      return 0
    end
  end

  return 1
end

-- Use type here to make different buttons
local function toggleCleanPrompt(player, weaponObject, hasGunOil)
  if hasGunOil and GetWeaponDamage(weaponObject) ~= 0 and GetWeaponDamage(weaponObject) > 0.0 then
    SetPedBlackboardBool(player, "GENERIC_WEAPON_CLEAN_PROMPT_AVAILABLE", 1, -1)
  else
    SetPedBlackboardBool(player, "GENERIC_WEAPON_CLEAN_PROMPT_AVAILABLE", 0, -1)
  end
end

function Weapon.Inspect(currentWeapon)
	local player = cache.ped
	local weaponHash = currentWeapon.hash
	local interaction

	-- Check here for item to toggle cleanPrompt from inv
	local hasGunOil = true 

	if IsWeaponOneHanded(weaponHash) then -- One Handed
		interaction = GetHashKey("SHORTARM_HOLD_ENTER")
	elseif IsWeaponTwoHanded(weaponHash) then -- Two Handed
		interaction = GetHashKey("LONGARM_HOLD_ENTER")
	end

	TaskItemInteraction(player, weaponHash, interaction, 1, 0, 0)

	local weaponObject = currentWeapon.weaponObject
	
	local uiFlowBlock, uiContainer = initialize(player, weaponHash, currentWeapon.metadata?.serial or "ILLEGAL")

	if uiContainer then
		local state = createStateMachine(uiFlowBlock)

		while shouldContinueInspect(player) do
			Citizen.Wait(1)
			DisableControlAction(0, GetHashKey("INPUT_NEXT_CAMERA"), true) -- V button
			DisableControlAction(0, GetHashKey("INPUT_CONTEXT_LT"), true) -- Right Click
			DisableOnFootFirstPersonViewThisUpdate()

			if state == 0 then
				state = createStateMachine(uiFlowBlock)
			elseif state == 1 then
				toggleCleanPrompt(player, weaponObject, hasGunOil)
				if GetItemInteractionFromPed(player) == GetHashKey("LONGARM_CLEAN_ENTER") or GetItemInteractionFromPed(player) == GetHashKey("SHORTARM_CLEAN_ENTER") then
					if takeGunOilCallback then takeGunOilCallback() end -- Remove Oil From Here
					state = 2
				end
			elseif state == 2 then
				if GetItemInteractionFromPed(player) == GetHashKey("LONGARM_CLEAN_EXIT") or GetItemInteractionFromPed(player) == GetHashKey("SHORTARM_CLEAN_EXIT") then
					state = 3
				else
					local cleanProgress = Citizen.InvokeNative(0xBC864A70AD55E0C1, PlayerPedId(), GetHashKey("INPUT_CONTEXT_X"), Citizen.ResultAsFloat())
					if cleanProgress > 0.0 then
						-- Update Weapon Stats Here
					end
				end
      		elseif state == 3 then
				-- Update weapon stats in UI
				Citizen.InvokeNative(0x46DB71883EE9D5AF, uiContainer, "stats", getWeaponStruct(weaponHash):Buffer(), player)
				state = 1
			end
		end

		cleanupInspectionMenu(uiFlowBlock, uiContainer)
	else
		print('UI Container Not Found')
	end
end

Utils.Disarm = Weapon.Disarm
Utils.ClearWeapons = Weapon.ClearAll

return Weapon
