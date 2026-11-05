--- Standalone Lua 5.1 unit test suite for TrainWrecker

local registeredFrames = {}
local currentTime = 1000
local inCombat = false
local inEncounter = false
local mockToys = {}
local mockItems = {}
local mockCooldowns = {}
local mockUnits = {}
local mockCVars = {
	["Sound_EnableDialog"] = "1",
}
local mockPlayerAuras = {}
local scheduledTimers = {}
local printedMessages = {}
local realPrint = print
_G.print = function(...)
	local args = { ... }
	table.insert(printedMessages, table.concat(args, "\t"))
	realPrint(...)
end

local function HasMessage(sub)
	for i = #printedMessages, 1, -1 do
		if string.find(printedMessages[i], sub, 1, true) then
			return true
		end
	end
	return false
end

local function ClearMessages()
	printedMessages = {}
end

-- Mock global WoW environment
rawset(_G, "UIParent", {})
_G.TrainWreckerDB = {}
_G.SlashCmdList = {}

_G.GetTime = function()
	return currentTime
end

_G.InCombatLockdown = function()
	return inCombat
end

_G.UnitName = function(unit)
	return mockUnits[unit]
end

_G.PlayerHasToy = function(id)
	return mockToys[id] == true
end

_G.C_Item = {
	GetItemCount = function(id)
		return mockItems[id] or 0
	end,
}

_G.C_Container = {
	GetItemCooldown = function(id)
		local cd = mockCooldowns[id]
		if cd then
			return cd.start, cd.duration, cd.enable
		end
		return 0, 0, 0
	end,
}

_G.C_CVar = {
	GetCVar = function(name)
		return mockCVars[name]
	end,
	SetCVar = function(name, val)
		mockCVars[name] = tostring(val)
	end,
}
_G.GetCVar = _G.C_CVar.GetCVar
_G.SetCVar = _G.C_CVar.SetCVar

_G.C_UnitAuras = {
	GetPlayerAuraBySpellID = function(spellID)
		return mockPlayerAuras[spellID]
	end,
}

_G.C_InstanceEncounter = {
	IsEncounterInProgress = function()
		return inEncounter
	end,
}

_G.C_Timer = {
	After = function(seconds, callback)
		table.insert(scheduledTimers, {
			triggerTime = currentTime + seconds,
			callback = callback,
		})
	end,
}

local function AdvanceTime(seconds)
	currentTime = currentTime + seconds
	local remaining = {}
	for _, timer in ipairs(scheduledTimers) do
		if currentTime >= timer.triggerTime then
			timer.callback()
		else
			table.insert(remaining, timer)
		end
	end
	scheduledTimers = remaining
end

_G.issecretvalue = function(val)
	return val == "SECRET_VALUE"
end

local function CreateMockWidget(widgetType, name, parent)
	local widget = {
		widgetType = widgetType,
		name = name,
		parent = parent,
		shown = false,
		points = {},
		attributes = {},
		events = {},
		unitEvents = {},
		scripts = {},
		text = "",
	}

	function widget:SetSize(w, h)
		self.width = w
		self.height = h
	end

	function widget:GetSize()
		return self.width or 0, self.height or 0
	end

	function widget:SetWidth(w)
		self.width = w
	end

	function widget:SetFrameStrata(strata)
		self.strata = strata
	end

	function widget:SetClampedToScreen(bool)
		self.clamped = bool
	end

	function widget:SetMovable(bool)
		self.movable = bool
	end

	function widget:EnableMouse(bool)
		self.mouseEnabled = bool
	end

	function widget:RegisterForDrag(...)
		self.dragButtons = { ... }
	end

	function widget:RegisterForClicks(...)
		self.clickButtons = { ... }
	end

	function widget:SetBackdrop(backdrop)
		self.backdrop = backdrop
	end

	function widget:ClearAllPoints()
		self.points = {}
	end

	function widget:SetPoint(point, relFrame, relPoint, x, y)
		table.insert(self.points, {
			point = point,
			relFrame = relFrame,
			relPoint = relPoint,
			x = x,
			y = y,
		})
	end

	function widget:GetPoint(index)
		local p = self.points[index or 1]
		if p then
			return p.point, p.relFrame, p.relPoint, p.x, p.y
		end
		return "CENTER", _G.UIParent, "CENTER", 0, 0
	end

	function widget:SetAllPoints(frame)
		self.allPoints = frame
	end

	function widget:Show()
		self.shown = true
	end

	function widget:Hide()
		self.shown = false
	end

	function widget:IsShown()
		return self.shown
	end

	function widget:SetScript(handler, fn)
		self.scripts[handler] = fn
	end

	function widget:GetScript(handler)
		return self.scripts[handler]
	end

	function widget:RegisterEvent(event)
		self.events[event] = true
	end

	function widget:RegisterUnitEvent(event, unit)
		self.events[event] = true
		self.unitEvents[event] = unit
	end

	function widget:UnregisterEvent(event)
		self.events[event] = nil
	end

	function widget:SetText(txt)
		self.text = txt
	end

	function widget:GetText()
		return self.text
	end

	function widget:SetJustifyH(j)
		self.justifyH = j
	end

	function widget:SetTexture(tex)
		self.texture = tex
	end

	function widget:SetAttribute(name, val)
		self.attributes[name] = val
	end

	function widget:GetAttribute(name)
		return self.attributes[name]
	end

	function widget:SetCooldown(start, dur)
		self.cooldownStart = start
		self.cooldownDur = dur
	end

	function widget:Clear()
		self.cooldownStart = nil
		self.cooldownDur = nil
	end

	function widget:CreateFontString(childName, layer, template)
		local fs = CreateMockWidget("FontString", childName, self)
		return fs
	end

	function widget:CreateTexture(childName, layer)
		local tex = CreateMockWidget("Texture", childName, self)
		return tex
	end

	function widget:GetFontString()
		if not self.fontString then
			self.fontString = self:CreateFontString()
		end
		return self.fontString
	end

	function widget:StartMoving()
		self.isMoving = true
	end

	function widget:StopMovingOrSizing()
		self.isMoving = false
	end

	table.insert(registeredFrames, widget)
	return widget
end

_G.CreateFrame = function(frameType, name, parent, template)
	return CreateMockWidget(frameType, name, parent)
end

local function FireEvent(eventName, ...)
	for _, frame in ipairs(registeredFrames) do
		if frame.events[eventName] and frame.scripts["OnEvent"] then
			frame.scripts["OnEvent"](frame, eventName, ...)
		end
	end
end

-- Load addon files
local Addon = {}
local ADDON_NAME = "TrainWrecker"

local function loadScript(path)
	local chunk, err = loadfile(path)
	if not chunk then
		error("Failed to load script " .. path .. ": " .. tostring(err))
	end
	chunk(ADDON_NAME, Addon)
end

print("Loading TrainWrecker scripts...")
loadScript("locales/enUS.lua")
loadScript("core/init.lua")
loadScript("core/detector.lua")
loadScript("ui/dialog.lua")

-- Trigger ADDON_LOADED
FireEvent("ADDON_LOADED", ADDON_NAME)

local passed = 0
local failed = 0

local function assertTest(name, condition, msg)
	if condition then
		passed = passed + 1
		print(string.format("  [PASS] %s", name))
	else
		failed = failed + 1
		print(string.format("  [FAIL] %s: %s", name, msg or "assertion failed"))
	end
end

print("\nRunning Test Suite:")

-- Test 1: Localization
assertTest(
	"L1: Silence the train string",
	Addon.L["Silence the train"] == "Silence the train"
)
assertTest(
	"L2: Fallback metatable",
	Addon.L["NonExistentKey"] == "NonExistentKey"
)

-- Test 2: Ownership verification
mockToys[45057] = false
mockItems[45057] = 0
local owned, kind = Addon.HasTrainWrecker()
assertTest("Ownership: Unowned", owned == false and kind == nil)

mockToys[45057] = true
owned, kind = Addon.HasTrainWrecker()
assertTest("Ownership: In ToyBox", owned == true and kind == "toy")

mockToys[45057] = false
mockItems[45057] = 1
owned, kind = Addon.HasTrainWrecker()
assertTest("Ownership: In Bags", owned == true and kind == "item")

-- Test 3: Placement detection with culprit name
mockUnits["party1"] = "GnomishEngineer"
mockToys[45057] = true
currentTime = 2000

FireEvent("UNIT_SPELLCAST_SUCCEEDED", "party1", "guid-1", 61031)
assertTest("Detection: Dialog Shown", Addon.DialogFrame:IsShown() == true)
assertTest(
	"Detection: Culprit Preserved",
	Addon.CurrentCulprit == "GnomishEngineer"
)
assertTest(
	"Detection: Status Text",
	Addon.StatusText:GetText() == "Toy Train Set placed by GnomishEngineer."
)
assertTest(
	"UI: Action button shown when owned",
	Addon.ActionButton:IsShown() == true
)
assertTest("UI: Toy attribute set", Addon.ActionButton:GetAttribute("toy") == 45057)

-- Test 4: Pulse detection preserves previous culprit name
currentTime = 2005
FireEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "guid-2", 61551)
assertTest(
	"Pulse: Culprit Preserved Across Pulse",
	Addon.StatusText:GetText() == "Toy Train Set placed by GnomishEngineer."
)

-- Test 5: Deduplication window
local lastShowCallTime = currentTime
currentTime = 2006 -- within 3 seconds
Addon.CurrentCulprit = nil
FireEvent("UNIT_SPELLCAST_SUCCEEDED", "party2", "guid-3", 61031)
assertTest(
	"Dedup: Ignored within 3 seconds",
	Addon.CurrentCulprit == nil
)

-- Test 6: Auto-dismiss on Train Wrecker cast
Addon.ShowTrainDialog("Someone")
assertTest("Dismiss: Before cast", Addon.DialogFrame:IsShown() == true)
FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid-wrecker", 62943)
assertTest("Dismiss: Auto-hidden after cast", Addon.DialogFrame:IsShown() == false)

-- Test 7: Secret value protection
Addon.HideTrainDialog()
FireEvent("UNIT_SPELLCAST_SUCCEEDED", "party1", "guid-sec", "SECRET_VALUE")
assertTest(
	"Secret Guard: Ignored secret spellID",
	Addon.DialogFrame:IsShown() == false
)

-- Test 8: Combat lockdown queueing
inCombat = true
currentTime = 3000
mockUnits["raid1"] = "CombatPlayer"
FireEvent("UNIT_SPELLCAST_SUCCEEDED", "raid1", "guid-combat", 61031)
assertTest(
	"Combat: Dialog NOT shown during combat",
	Addon.DialogFrame:IsShown() == false
)
assertTest("Combat: PendingShow is true", Addon.PendingShow == true)
assertTest(
	"Combat: PendingCulprit preserved",
	Addon.PendingCulprit == "CombatPlayer"
)

-- Leave combat
inCombat = false
FireEvent("PLAYER_REGEN_ENABLED")
assertTest(
	"Combat: Dialog shown after combat ended",
	Addon.DialogFrame:IsShown() == true
)
assertTest(
	"Combat: Status text after combat",
	Addon.StatusText:GetText() == "Toy Train Set placed by CombatPlayer."
)

-- Test 9: Mid-session toy learning
mockToys[45057] = false
mockItems[45057] = 0
Addon.RefreshTrainDialog()
assertTest("Unowned: Missing text shown", Addon.MissingText:IsShown() == true)
assertTest("Unowned: Action button hidden", Addon.ActionButton:IsShown() == false)
assertTest("Unowned: Dismiss button shown", Addon.DismissButton:IsShown() == true)

-- Player learns toy
mockToys[45057] = true
FireEvent("TOYS_UPDATED")
assertTest(
	"Learned: Action button shown",
	Addon.ActionButton:IsShown() == true
)
assertTest("Learned: Missing text hidden", Addon.MissingText:IsShown() == false)

-- Test 10: Cooldown updates
mockCooldowns[45057] = { start = 100, duration = 1800, enable = 1 }
Addon.UpdateCooldown()
assertTest(
	"Cooldown: Start and duration set",
	Addon.Cooldown.cooldownStart == 100 and Addon.Cooldown.cooldownDur == 1800
)

mockCooldowns[45057] = { start = 0, duration = 0, enable = 0 }
Addon.UpdateCooldown()
assertTest(
	"Cooldown: Cleared when off cooldown",
	Addon.Cooldown.cooldownStart == nil
)

-- Test 11: Muting on placement cast (61031)
mockCVars["Sound_EnableDialog"] = "1"
_G.TrainWreckerDB.soundMuted = nil
currentTime = 4000
FireEvent("UNIT_SPELLCAST_SUCCEEDED", "party1", "guid-mute1", 61031)
assertTest(
	"Mute: Placement cast sets Sound_EnableDialog to 0",
	mockCVars["Sound_EnableDialog"] == "0"
)
assertTest(
	"Mute: soundMuted recorded in TrainWreckerDB",
	_G.TrainWreckerDB.soundMuted == true
)

-- Test 12: Placement grace period holds mute against unrelated UNIT_AURA
mockPlayerAuras[61551] = nil
FireEvent("UNIT_AURA", "player")
assertTest(
	"Grace: Mute held during placement window even without buff",
	mockCVars["Sound_EnableDialog"] == "0" and _G.TrainWreckerDB.soundMuted == true
)

-- Test 13: Muting persists when player buff is active
mockPlayerAuras[61551] = { name = "Train", spellId = 61551 }
FireEvent("UNIT_AURA", "player")
assertTest(
	"Aura: Mute maintained while Train buff active",
	mockCVars["Sound_EnableDialog"] == "0" and _G.TrainWreckerDB.soundMuted == true
)

-- Test 14: Unmuting after buff expires and grace period passes
mockPlayerAuras[61551] = nil
AdvanceTime(20)
FireEvent("UNIT_AURA", "player")
assertTest(
	"Restore: Sound_EnableDialog restored to 1 when buff and grace period expire",
	mockCVars["Sound_EnableDialog"] == "1"
)
assertTest(
	"Restore: soundMuted flag cleared from TrainWreckerDB",
	_G.TrainWreckerDB.soundMuted == nil
)

-- Test 15: Pre-disabled Dialog sound is preserved
mockCVars["Sound_EnableDialog"] = "0"
_G.TrainWreckerDB.soundMuted = nil
currentTime = 5000
FireEvent("UNIT_SPELLCAST_SUCCEEDED", "party1", "guid-pre-disabled", 61031)
assertTest(
	"Preserve Disabled: soundMuted flag is NOT set if already disabled",
	_G.TrainWreckerDB.soundMuted == nil
)
assertTest(
	"Preserve Disabled: Sound_EnableDialog remains 0",
	mockCVars["Sound_EnableDialog"] == "0"
)
AdvanceTime(20)
FireEvent("UNIT_AURA", "player")
assertTest(
	"Preserve Disabled: Dialog sound remains 0 after expiration",
	mockCVars["Sound_EnableDialog"] == "0"
)

-- Test 16: Active boss encounter prevents muting
mockCVars["Sound_EnableDialog"] = "1"
_G.TrainWreckerDB.soundMuted = nil
inEncounter = true
currentTime = 6000
FireEvent("UNIT_SPELLCAST_SUCCEEDED", "party1", "guid-encounter", 61031)
assertTest(
	"Encounter: Dialog sound not muted during boss encounters",
	mockCVars["Sound_EnableDialog"] == "1"
)
assertTest(
	"Encounter: soundMuted not set during boss encounters",
	_G.TrainWreckerDB.soundMuted == nil
)
inEncounter = false

-- Test 17: Train Wrecker cast (62943) cancels hold window and restores sound
mockCVars["Sound_EnableDialog"] = "1"
_G.TrainWreckerDB.soundMuted = nil
mockPlayerAuras[61551] = nil
currentTime = 7000
FireEvent("UNIT_SPELLCAST_SUCCEEDED", "party1", "guid-train-wrecker-test", 61031)
assertTest(
	"Wrecker Restore: Muted on train placement",
	mockCVars["Sound_EnableDialog"] == "0" and _G.TrainWreckerDB.soundMuted == true
)
FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid-wrecker-used", 62943)
assertTest(
	"Wrecker Restore: Sound restored immediately upon Train Wrecker cast",
	mockCVars["Sound_EnableDialog"] == "1"
)
assertTest(
	"Wrecker Restore: soundMuted cleared upon Train Wrecker cast",
	_G.TrainWreckerDB.soundMuted == nil
)

-- Test 18: Login / reload recovery restores sound if player logged out muted
mockCVars["Sound_EnableDialog"] = "0"
_G.TrainWreckerDB.soundMuted = true
mockPlayerAuras[61551] = nil
FireEvent("PLAYER_ENTERING_WORLD", true, false)
assertTest(
	"Login Recovery: Restores Dialog sound if logged out while muted",
	mockCVars["Sound_EnableDialog"] == "1"
)
assertTest(
	"Login Recovery: Clears soundMuted on login",
	_G.TrainWreckerDB.soundMuted == nil
)

-- Test 19: Login / reload recovery keeps muted if player still has buff
mockCVars["Sound_EnableDialog"] = "0"
_G.TrainWreckerDB.soundMuted = true
mockPlayerAuras[61551] = { name = "Train", spellId = 61551 }
FireEvent("PLAYER_ENTERING_WORLD", false, true)
assertTest(
	"Reload with Buff: Dialog sound remains muted if player still has buff",
	mockCVars["Sound_EnableDialog"] == "0" and _G.TrainWreckerDB.soundMuted == true
)
mockPlayerAuras[61551] = nil
FireEvent("UNIT_AURA", "player")
assertTest(
	"Reload with Buff: Sound restored after buff expires",
	mockCVars["Sound_EnableDialog"] == "1" and _G.TrainWreckerDB.soundMuted == nil
)

-- Test 20: Walking near an active toy train triggers dialog and muting via aura
Addon.HideTrainDialog()
mockCVars["Sound_EnableDialog"] = "1"
_G.TrainWreckerDB.soundMuted = nil
mockPlayerAuras[61551] = { name = "Train", spellId = 61551 }
currentTime = 9000
ClearMessages()
FireEvent("UNIT_AURA", "player")
assertTest(
	"Aura Walk-Up: Dialog shown when player receives train aura",
	Addon.DialogFrame:IsShown() == true
)
assertTest(
	"Aura Walk-Up: Audio muted when player receives train aura",
	mockCVars["Sound_EnableDialog"] == "0" and _G.TrainWreckerDB.soundMuted == true
)
assertTest(
	"Aura Walk-Up: Chat message for aura detection printed",
	HasMessage("Toy Train Set aura detected on player.")
)
assertTest(
	"Aura Walk-Up: Chat message for audio muting printed",
	HasMessage("Dialog audio muted while Toy Train Set is active.")
)

-- Test 21: Aura expiration restores audio and prints chat message
mockPlayerAuras[61551] = nil
ClearMessages()
FireEvent("UNIT_AURA", "player")
assertTest(
	"Aura Fade: Sound restored when train aura expires",
	mockCVars["Sound_EnableDialog"] == "1" and _G.TrainWreckerDB.soundMuted == nil
)
assertTest(
	"Aura Fade: Chat message for audio restoration printed",
	HasMessage("Dialog audio re-enabled.")
)

-- Test 22: Timer jitter guard restores audio across frame boundaries
mockCVars["Sound_EnableDialog"] = "1"
_G.TrainWreckerDB.soundMuted = nil
mockPlayerAuras[61551] = nil
currentTime = 10000
FireEvent("UNIT_SPELLCAST_SUCCEEDED", "party1", "guid-jitter", 61031)
assertTest(
	"Jitter Guard: Muted on placement",
	mockCVars["Sound_EnableDialog"] == "0" and _G.TrainWreckerDB.soundMuted == true
)
-- Simulate timer triggering slightly before exact integer threshold (e.g., 14.98s)
AdvanceTime(14.98)
assertTest(
	"Jitter Guard: Audio restored despite sub-millisecond timer jitter",
	mockCVars["Sound_EnableDialog"] == "1" and _G.TrainWreckerDB.soundMuted == nil
)

-- Test 23: Immediate sound restoration when 62943 is cast while player still has buff
mockCVars["Sound_EnableDialog"] = "1"
_G.TrainWreckerDB.soundMuted = nil
mockPlayerAuras[61551] = { name = "Train", spellId = 61551 }
currentTime = 11000
FireEvent("UNIT_AURA", "player")
assertTest(
	"Wrecker Immediate: Muted while buff active",
	_G.TrainWreckerDB.soundMuted == true
)
ClearMessages()
FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "guid-wrecker-immediate", 62943)
assertTest(
	"Wrecker Immediate: Sound restored immediately upon wrecker deployment",
	mockCVars["Sound_EnableDialog"] == "1" and _G.TrainWreckerDB.soundMuted == nil
)
assertTest(
	"Wrecker Immediate: Chat message for wrecker deployment printed",
	HasMessage("Wind-Up Train Wrecker deployed.")
)
assertTest(
	"Wrecker Immediate: Chat message for audio restoration printed",
	HasMessage("Dialog audio re-enabled.")
)
assertTest(
	"Wrecker Immediate: Dialog hidden",
	Addon.DialogFrame:IsShown() == false
)

-- Test 24: Chat message verification for pulse and placement without culprit
currentTime = 12000
ClearMessages()
FireEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "guid-anon", 61031)
assertTest(
	"Chat Messages: Anonymous placement message",
	HasMessage("A Toy Train Set was detected nearby.")
)
currentTime = 12010
ClearMessages()
FireEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "guid-pulse-msg", 61551)
assertTest(
	"Chat Messages: Pulse message",
	HasMessage("Toy Train Set pulse detected nearby.")
)

print(string.format("\nResults: %d passed, %d failed", passed, failed))
if failed > 0 then
	os.exit(1)
end
