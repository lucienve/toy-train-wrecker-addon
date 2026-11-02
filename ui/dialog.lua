---@type string, TrainWreckerAddon
local ADDON, Addon = ...

local L = Addon.L

---@type TrainWreckerDialog?
local dialogFrame = nil

local function CreateDialogFrame()
	if not InCombatLockdown() then
		dialogFrame = CreateFrame(
			"Frame",
			"TrainWreckerDialogFrame",
			UIParent,
			"BackdropTemplate"
		) --[[@as TrainWreckerDialog]]
		dialogFrame:SetSize(360, 160)
		dialogFrame:SetFrameStrata("DIALOG")
		dialogFrame:SetClampedToScreen(true)
		dialogFrame:SetMovable(true)
		dialogFrame:EnableMouse(true)
		dialogFrame:RegisterForDrag("LeftButton")
		dialogFrame:Hide()

		dialogFrame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 },
		})

		dialogFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)

		-- Dragging handlers with combat lockdown safeguards
		dialogFrame:SetScript("OnDragStart", function(self)
			if not InCombatLockdown() then
				self.isMoving = true
				self:StartMoving()
			end
		end)

		dialogFrame:SetScript("OnDragStop", function(self)
			if self.isMoving then
				self.isMoving = false
				self:StopMovingOrSizing()
				local point, _, relPoint, x, y = self:GetPoint()
				if _G.TrainWreckerDB then
					_G.TrainWreckerDB.point = point
					_G.TrainWreckerDB.relativePoint = relPoint
					_G.TrainWreckerDB.x = x
					_G.TrainWreckerDB.y = y
				end
			end
		end)

		-- Title FontString
		local title = dialogFrame:CreateFontString(
			nil,
			"ARTWORK",
			"GameFontHighlightLarge"
		)
		title:SetPoint("TOP", dialogFrame, "TOP", 0, -16)
		title:SetText(L["Silence the train"])
		dialogFrame.title = title

		-- Close button in top-right corner
		local closeBtn =
			CreateFrame("Button", nil, dialogFrame, "UIPanelCloseButton")
		closeBtn:SetPoint("TOPRIGHT", dialogFrame, "TOPRIGHT", -4, -4)
		closeBtn:SetScript("OnClick", function()
			Addon.HideTrainDialog()
		end)
		dialogFrame.closeBtn = closeBtn

		-- Culprit status text
		local statusText =
			dialogFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		statusText:SetPoint("TOP", title, "BOTTOM", 0, -10)
		statusText:SetWidth(320)
		statusText:SetJustifyH("CENTER")
		statusText:SetText(L["Train Detected Nearby"])
		dialogFrame.statusText = statusText

		-- Action button for owned state
		local actionBtn = CreateFrame(
			"Button",
			"TrainWreckerActionButton",
			dialogFrame,
			"TrainWreckerActionButtonTemplate"
		)
		actionBtn:SetSize(240, 36)
		actionBtn:SetPoint("BOTTOM", dialogFrame, "BOTTOM", 0, 20)
		actionBtn:RegisterForClicks("AnyUp", "AnyDown")
		actionBtn:SetText(L["Wind-Up Train Wrecker"])

		local icon = actionBtn:CreateTexture(nil, "ARTWORK")
		icon:SetSize(28, 28)
		icon:SetPoint("LEFT", actionBtn, "LEFT", 4, 0)
		icon:SetTexture(134152) -- FileDataID: inv_misc_head_clockworkgnome_01
		dialogFrame.icon = icon

		local btnText = actionBtn:GetFontString()
		if btnText then
			btnText:ClearAllPoints()
			btnText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
			btnText:SetPoint("RIGHT", actionBtn, "RIGHT", -6, 0)
			btnText:SetJustifyH("CENTER")
		end

		local cooldown =
			CreateFrame("Cooldown", nil, actionBtn, "CooldownFrameTemplate")
		cooldown:SetAllPoints(icon)
		dialogFrame.cooldown = cooldown
		dialogFrame.actionBtn = actionBtn

		-- Missing toy text and dismiss button for unowned state
		local missingText =
			dialogFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		missingText:SetPoint("TOP", statusText, "BOTTOM", 0, -8)
		missingText:SetPoint("LEFT", dialogFrame, "LEFT", 20, 0)
		missingText:SetPoint("RIGHT", dialogFrame, "RIGHT", -20, 0)
		missingText:SetJustifyH("CENTER")
		missingText:SetText(L["Missing Toy Message"])
		dialogFrame.missingText = missingText

		local dismissBtn =
			CreateFrame("Button", nil, dialogFrame, "UIPanelButtonTemplate")
		dismissBtn:SetSize(120, 26)
		dismissBtn:SetPoint("BOTTOM", dialogFrame, "BOTTOM", 0, 16)
		dismissBtn:SetText(L["Close"])
		dismissBtn:SetScript("OnClick", function()
			Addon.HideTrainDialog()
		end)
		dialogFrame.dismissBtn = dismissBtn

		-- Expose frame widgets on Addon table
		Addon.DialogFrame = dialogFrame
		Addon.ActionButton = actionBtn
		Addon.Cooldown = cooldown
		Addon.StatusText = statusText
		Addon.MissingText = missingText
		Addon.DismissButton = dismissBtn
	end
end

if not InCombatLockdown() then
	CreateDialogFrame()
end

---Updates cooldown display on the action button icon.
function Addon.UpdateCooldown()
	if not dialogFrame or not dialogFrame.cooldown then
		return
	end

	local startTime, duration, enable
	if C_Container and C_Container.GetItemCooldown then
		startTime, duration, enable = C_Container.GetItemCooldown(45057)
	end

	if
		startTime
		and duration
		and startTime > 0
		and duration > 0
		and (enable == 1 or enable == true)
	then
		dialogFrame.cooldown:SetCooldown(startTime, duration)
	else
		dialogFrame.cooldown:Clear()
	end
end

---Updates dialog content based on toy ownership and culprit information.
local function UpdateDialogView()
	if not dialogFrame or InCombatLockdown() then
		return
	end

	-- Restore position from SavedVariables if available
	local db = _G.TrainWreckerDB
	if db and db.point and not dialogFrame.positionRestored then
		dialogFrame:ClearAllPoints()
		dialogFrame:SetPoint(
			db.point,
			UIParent,
			db.relativePoint or db.point,
			db.x or 0,
			db.y or 0
		)
		dialogFrame.positionRestored = true
	end

	-- Update culprit text
	if Addon.CurrentCulprit and Addon.CurrentCulprit ~= "" then
		dialogFrame.statusText:SetText(
			string.format(L["Train Placed By"], Addon.CurrentCulprit)
		)
	else
		dialogFrame.statusText:SetText(L["Train Detected Nearby"])
	end

	-- Evaluate ownership
	local isOwned, sourceType = Addon.HasTrainWrecker()
	if isOwned then
		dialogFrame.missingText:Hide()
		dialogFrame.dismissBtn:Hide()
		dialogFrame.actionBtn:Show()

		if sourceType == "toy" then
			dialogFrame.actionBtn:SetAttribute("type", "toy")
			dialogFrame.actionBtn:SetAttribute("toy", 45057)
			dialogFrame.actionBtn:SetAttribute("item", nil)
		else
			dialogFrame.actionBtn:SetAttribute("type", "item")
			dialogFrame.actionBtn:SetAttribute("item", "item:45057")
			dialogFrame.actionBtn:SetAttribute("toy", nil)
		end

		Addon.UpdateCooldown()
	else
		dialogFrame.actionBtn:Hide()
		dialogFrame.missingText:Show()
		dialogFrame.dismissBtn:Show()
	end
end

---Shows the "Silence the train" dialog.
---@param culpritName? string
function Addon.ShowTrainDialog(culpritName)
	if culpritName and culpritName ~= "" then
		Addon.CurrentCulprit = culpritName
		Addon.PendingCulprit = culpritName
	end

	if InCombatLockdown() then
		Addon.PendingShow = true
		Addon.PendingHide = false
		return
	end

	Addon.PendingShow = false
	Addon.PendingHide = false

	if not dialogFrame then
		CreateDialogFrame()
	end

	if not dialogFrame then
		return
	end

	UpdateDialogView()

	if not dialogFrame:IsShown() then
		dialogFrame:Show()
	end
end

---Hides the "Silence the train" dialog.
function Addon.HideTrainDialog()
	if InCombatLockdown() then
		Addon.PendingHide = true
		Addon.PendingShow = false
		return
	end

	Addon.PendingHide = false
	Addon.PendingShow = false
	Addon.PendingRefresh = false
	Addon.CurrentCulprit = nil
	Addon.PendingCulprit = nil

	if dialogFrame and dialogFrame:IsShown() then
		dialogFrame:Hide()
	end
end

---Refreshes dialog contents if currently visible or queued.
function Addon.RefreshTrainDialog()
	if InCombatLockdown() then
		if (dialogFrame and dialogFrame:IsShown()) or Addon.PendingShow then
			Addon.PendingRefresh = true
		end
		return
	end

	Addon.PendingRefresh = false

	if dialogFrame and dialogFrame:IsShown() then
		UpdateDialogView()
	end
end

-- Event frame for combat lockdown lifecycle and cooldown updates
local lifecycleFrame = CreateFrame("Frame")
lifecycleFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
lifecycleFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
lifecycleFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
lifecycleFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")

lifecycleFrame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_REGEN_ENABLED" then
		if not dialogFrame then
			CreateDialogFrame()
		end

		if Addon.PendingHide then
			Addon.HideTrainDialog()
		elseif Addon.PendingShow then
			local culprit = Addon.PendingCulprit
			Addon.ShowTrainDialog(culprit)
		elseif Addon.PendingRefresh then
			Addon.RefreshTrainDialog()
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		if dialogFrame and dialogFrame.isMoving then
			dialogFrame.isMoving = false
			dialogFrame:StopMovingOrSizing()
			local point, _, relPoint, x, y = dialogFrame:GetPoint()
			if _G.TrainWreckerDB then
				_G.TrainWreckerDB.point = point
				_G.TrainWreckerDB.relativePoint = relPoint
				_G.TrainWreckerDB.x = x
				_G.TrainWreckerDB.y = y
			end
		end
	elseif event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" then
		if dialogFrame and dialogFrame:IsShown() then
			Addon.UpdateCooldown()
		end
	end
end)
