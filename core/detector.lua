---@type string, TrainWreckerAddon
local ADDON, Addon = ...

local TOY_TRAIN_ITEM_ID = 44606
local TOY_TRAIN_SPELL_ID = 61031
local TRAIN_PULSE_SPELL_ID = 61551
local TRAIN_WRECKER_ITEM_ID = 45057
local TRAIN_WRECKER_SPELL_ID = 62943
local DEDUP_WINDOW_SECONDS = 3
local PLACEMENT_MUTE_SECONDS = 15
local CVAR_ENABLE_DIALOG = "Sound_EnableDialog"

---Checks whether the player owns the Wind-Up Train Wrecker as a toy or bag item.
---@return boolean isOwned, ("toy"|"item")? sourceType
function Addon.HasTrainWrecker()
	if PlayerHasToy and PlayerHasToy(TRAIN_WRECKER_ITEM_ID) then
		return true, "toy"
	end

	local count = 0
	if C_Item and C_Item.GetItemCount then
		count = C_Item.GetItemCount(TRAIN_WRECKER_ITEM_ID) or 0
	end

	if count > 0 then
		return true, "item"
	end

	return false, nil
end

---Checks whether an encounter is currently active.
---@return boolean
local function IsInEncounter()
	if C_InstanceEncounter and C_InstanceEncounter.IsEncounterInProgress then
		return C_InstanceEncounter.IsEncounterInProgress() or false
	end
	return false
end

---Retrieves the value of the Dialog sound CVar.
---@return string?
local function GetDialogCVar()
	if C_CVar and C_CVar.GetCVar then
		return C_CVar.GetCVar(CVAR_ENABLE_DIALOG)
	end
	return nil
end

---Sets the value of the Dialog sound CVar.
---@param value string
local function SetDialogCVar(value)
	if C_CVar and C_CVar.SetCVar then
		C_CVar.SetCVar(CVAR_ENABLE_DIALOG, value)
	end
end

---Checks whether the player currently has the Train buff.
---@return boolean
function Addon.HasTrainBuff()
	if not C_UnitAuras or not C_UnitAuras.GetPlayerAuraBySpellID then
		return false
	end

	local aura = C_UnitAuras.GetPlayerAuraBySpellID(TRAIN_PULSE_SPELL_ID)
	if issecretvalue and issecretvalue(aura) then
		return false
	end

	return aura ~= nil
end

---Mutes the Dialog sound channel if enabled, remembering the previous state.
function Addon.MuteTrainSound()
	if IsInEncounter() then
		return
	end

	local db = _G.TrainWreckerDB
	if not db then
		return
	end

	if not db.soundMuted then
		local isEnabled = GetDialogCVar()
		if isEnabled == "1" then
			db.soundMuted = true
			SetDialogCVar("0")
		end
	end
end

---Restores the Dialog sound channel if previously muted by TrainWrecker.
function Addon.RestoreTrainSound()
	local db = _G.TrainWreckerDB
	if db and db.soundMuted then
		SetDialogCVar("1")
		db.soundMuted = nil
	end
	muteHoldUntil = 0
end

local lastCastGUID = nil
local lastCastTime = 0
local muteHoldUntil = 0

---Evaluates current train presence and restores or maintains sound muting.
local function EvaluateSoundRestore()
	if Addon.HasTrainBuff() then
		Addon.MuteTrainSound()
	elseif GetTime() >= muteHoldUntil then
		Addon.RestoreTrainSound()
	end
end

local detectorFrame = CreateFrame("Frame")
detectorFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
detectorFrame:RegisterEvent("TOYS_UPDATED")
detectorFrame:RegisterEvent("BAG_UPDATE_DELAYED")
detectorFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
detectorFrame:RegisterUnitEvent("UNIT_AURA", "player")

detectorFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unitTarget, castGUID, spellID = ...

		-- Guard against secret values in restricted encounters (Retail 12.0+ / MoP Classic)
		if
			issecretvalue
			and (
				issecretvalue(spellID)
				or issecretvalue(castGUID)
				or issecretvalue(unitTarget)
			)
		then
			return
		end

		if spellID == TOY_TRAIN_SPELL_ID or spellID == TRAIN_PULSE_SPELL_ID then
			local now = GetTime()
			muteHoldUntil = now + PLACEMENT_MUTE_SECONDS
			Addon.MuteTrainSound()
			if C_Timer and C_Timer.After then
				C_Timer.After(PLACEMENT_MUTE_SECONDS, EvaluateSoundRestore)
			end

			if
				(lastCastGUID and castGUID and lastCastGUID == castGUID)
				or ((now - lastCastTime) < DEDUP_WINDOW_SECONDS)
			then
				return
			end
			lastCastGUID = castGUID
			lastCastTime = now

			local culpritName = nil
			if spellID == TOY_TRAIN_SPELL_ID and unitTarget then
				local name = UnitName(unitTarget)
				if
					not (issecretvalue and issecretvalue(name))
					and name
					and name ~= ""
				then
					culpritName = name
				end
			end

			if Addon.ShowTrainDialog then
				Addon.ShowTrainDialog(culpritName)
			end
		elseif spellID == TRAIN_WRECKER_SPELL_ID and unitTarget == "player" then
			muteHoldUntil = 0
			lastCastGUID = nil
			lastCastTime = 0
			EvaluateSoundRestore()

			if Addon.HideTrainDialog then
				Addon.HideTrainDialog()
			end
		end
	elseif event == "UNIT_AURA" or event == "PLAYER_ENTERING_WORLD" then
		EvaluateSoundRestore()
	elseif event == "TOYS_UPDATED" or event == "BAG_UPDATE_DELAYED" then
		if Addon.RefreshTrainDialog then
			Addon.RefreshTrainDialog()
		end
	end
end)
