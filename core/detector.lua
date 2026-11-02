---@type string, TrainWreckerAddon
local ADDON, Addon = ...

local TOY_TRAIN_ITEM_ID = 44606
local TOY_TRAIN_SPELL_ID = 61031
local TRAIN_PULSE_SPELL_ID = 61551
local TRAIN_WRECKER_ITEM_ID = 45057
local TRAIN_WRECKER_SPELL_ID = 62943
local DEDUP_WINDOW_SECONDS = 3

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

local lastCastGUID = nil
local lastCastTime = 0

local detectorFrame = CreateFrame("Frame")
detectorFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
detectorFrame:RegisterEvent("TOYS_UPDATED")
detectorFrame:RegisterEvent("BAG_UPDATE_DELAYED")

detectorFrame:SetScript("OnEvent", function(self, event, unitTarget, castGUID, spellID)
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
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
			if Addon.HideTrainDialog then
				Addon.HideTrainDialog()
			end
		end
	elseif event == "TOYS_UPDATED" or event == "BAG_UPDATE_DELAYED" then
		if Addon.RefreshTrainDialog then
			Addon.RefreshTrainDialog()
		end
	end
end)
