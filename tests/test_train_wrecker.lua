--- Standalone Lua 5.1 unit test suite for TrainWrecker

local registeredFrames = {}
local currentTime = 1000
local inCombat = false
local mockToys = {}
local mockItems = {}
local mockCooldowns = {}
local mockUnits = {}

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

print(string.format("\nResults: %d passed, %d failed", passed, failed))
if failed > 0 then
	os.exit(1)
end
