---@type string, TrainWreckerAddon
local ADDON, Addon = ...

---@type TrainWreckerLocale
local L = setmetatable({}, {
	__index = function(_, k)
		return k
	end,
})
Addon.L = L

L["Silence the train"] = "Silence the train"
L["Train Placed By"] = "Toy Train Set placed by %s."
L["Train Detected Nearby"] = "A Toy Train Set was detected nearby."
L["Wind-Up Train Wrecker"] = "Wind-Up Train Wrecker"
L["Missing Toy Message"] =
	"You do not have the Wind-Up Train Wrecker toy. You can purchase it for 250 gold from Jepetto Joybuzz at the Wonderworks toy shop in Dalaran."
L["Close"] = "Close"
L["Cannot Open In Combat"] = "Cannot open the Train Wrecker dialog during combat."
L["Train Pulse Detected"] = "Toy Train Set pulse detected nearby."
L["Train Aura Detected"] = "Toy Train Set aura detected on player."
L["Train Wrecker Deployed"] = "Wind-Up Train Wrecker deployed."
L["Audio Muted"] = "Dialog audio muted while Toy Train Set is active."
L["Audio Restored"] = "Dialog audio re-enabled."
