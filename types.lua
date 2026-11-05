---@meta

---@class TrainWreckerDB
---@field point? string
---@field relativePoint? string
---@field x? number
---@field y? number
---@field soundMuted? boolean

---@class TrainWreckerLocale
---@field ["Silence the train"] string
---@field ["Train Placed By"] string
---@field ["Train Detected Nearby"] string
---@field ["Wind-Up Train Wrecker"] string
---@field ["Missing Toy Message"] string
---@field ["Close"] string
---@field ["Cannot Open In Combat"] string
---@field ["Train Pulse Detected"] string
---@field ["Train Aura Detected"] string
---@field ["Train Wrecker Deployed"] string
---@field ["Audio Muted"] string
---@field ["Audio Restored"] string
---@field [string] string

---@class TrainWreckerDialog : Frame, BackdropTemplate
---@field isMoving? boolean
---@field positionRestored? boolean
---@field title? FontString
---@field closeBtn? Button
---@field statusText? FontString
---@field missingText? FontString
---@field dismissBtn? Button
---@field actionBtn? Button
---@field icon? Texture
---@field cooldown? Cooldown

---@class TrainWreckerAddon
---@field L TrainWreckerLocale
---@field Print fun(msg: string)
---@field HasTrainWrecker fun(): boolean, ("toy"|"item")?
---@field HasTrainBuff fun(): boolean
---@field MuteTrainSound fun()
---@field RestoreTrainSound fun()
---@field ShowTrainDialog fun(culpritName?: string)
---@field HideTrainDialog fun()
---@field RefreshTrainDialog fun()
---@field UpdateCooldown fun()
---@field DialogFrame? TrainWreckerDialog
---@field ActionButton? Button
---@field Cooldown? Cooldown
---@field StatusText? FontString
---@field MissingText? FontString
---@field DismissButton? Button
---@field PendingShow boolean
---@field PendingHide boolean
---@field PendingRefresh boolean
---@field PendingCulprit? string
---@field CurrentCulprit? string

---@type TrainWreckerDB
TrainWreckerDB = TrainWreckerDB

---@type TrainWreckerAddon
TrainWrecker = TrainWrecker

---@type string
SLASH_TRAINWRECKER1 = SLASH_TRAINWRECKER1

---@type string
SLASH_TRAINWRECKER2 = SLASH_TRAINWRECKER2
