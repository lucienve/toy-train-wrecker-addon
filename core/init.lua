---@type string, TrainWreckerAddon
local ADDON, Addon = ...

-- Expose addon table globally for inspection and unit testing
_G.TrainWrecker = Addon

-- Initialize pending state flags
Addon.PendingShow = false
Addon.PendingHide = false
Addon.PendingRefresh = false
Addon.PendingCulprit = nil
Addon.CurrentCulprit = nil

-- Lifecycle frame for SavedVariables initialization
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, name)
	if name == ADDON then
		_G.TrainWreckerDB = _G.TrainWreckerDB or {}
		self:UnregisterEvent("ADDON_LOADED")
	end
end)

-- Slash command registrations
SLASH_TRAINWRECKER1 = "/trainwrecker"
SLASH_TRAINWRECKER2 = "/tw"

SlashCmdList["TRAINWRECKER"] = function(_)
	if InCombatLockdown() then
		local msg = Addon.L["Cannot Open In Combat"]
			or "Cannot open the Train Wrecker dialog during combat."
		print("|cffff8000TrainWrecker:|r " .. msg)
		return
	end

	if Addon.ShowTrainDialog then
		Addon.ShowTrainDialog()
	end
end
