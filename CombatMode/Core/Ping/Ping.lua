---------------------------------------------------------------------------------------
--  Core/Ping/Ping.lua — PING — dedicated Ping menu
---------------------------------------------------------------------------------------
-- What it does: Opens the Ping preset from an optional dedicated binding and pings on a centre release.
-- Architecture: Secure click buttons share the radial renderer and Click Casting ping action.
-- Does not: Assign bindings automatically.
-- Related: Core/RadialMenu/View.lua, Core/FreeLook/FreeLookController.lua, Core/ClickCasting/BindingOverrides.lua.
local _, CM = ...
local _G = _G
local L = CM.L
local COMMANDS = { "Combat Mode - Ping Menu", "Combat Mode - Ping Menu Secondary" }
CM.PingMenuBindingCommands = COMMANDS
local pingWheel = CM.RadialBuildPingWheel()
local entries = pingWheel.slots
local pingGeneration = 0
local function FinishLocationPing(generation)
  if generation ~= pingGeneration or not CM.locationPingActive then
    return
  end
  CM.locationPingActive = false
  CM.ReconcileFreeLook()
end

local function BeginLocationPing()
  if not CM.DB then
    return
  end
  pingGeneration = pingGeneration + 1
  CM.locationPingActive = true
  local generation = pingGeneration
  _G.C_Timer.After(0.1, function()
    FinishLocationPing(generation)
  end)
  CM.UnlockFreeLook()
  CM.SetCursorFreelookCentering(false)
end
function CM.FinishLocationPing()
  local generation = pingGeneration
  _G.C_Timer.After(0, function()
    FinishLocationPing(generation)
  end)
end
-- Selecting a radial slice moves the cursor. The existing camera-centering bounce
-- returns it to the reticle without changing the aimed point before the macro fires.
function CM.PrepareLocationPingAtReticle()
  CM.locationPingActive = false
  CM.LockFreeLook()
  BeginLocationPing()
end

local wheel =
  _G.CreateFrame("Frame", "CombatModePingMenu", _G.UIParent, "SecureHandlerBaseTemplate")
wheel:SetSize(CM.RadialLayout.FRAME, CM.RadialLayout.FRAME)
wheel:SetFrameStrata("DIALOG")
wheel:EnableMouse(false)
wheel:Hide()
local key =
  _G.CreateFrame("Button", "CombatModePingMenuKey", _G.UIParent, "SecureActionButtonTemplate")
key:RegisterForClicks("AnyDown", "AnyUp")
key:SetAttribute("type", "click")
key:SetAttribute("useOnKeyDown", true)
key:Hide()
local owner = _G.CreateFrame("Frame")
local HIDE = [[ owner:Hide(); owner:ClearBindings() ]]
local PRE = [[
  local owner = owner or self
  if button == "ESC" then
    if owner:IsShown() then ]] .. HIDE .. [[ end
    return false
  end
  if down then
    local radial = owner:GetFrameRef("radial")
    local party = owner:GetFrameRef("party")
    if (radial and radial:IsShown()) or (party and party:IsShown()) then return false end
    self:SetAttribute("useOnKeyDown", true)
    owner:ClearAllPoints()
    owner:SetPoint("CENTER", "$parent", "CENTER", 0, owner:GetAttribute("yoff") or 0)
    owner:Show()
    owner:SetBindingClick(true, "ESCAPE", "CombatModePingMenuKey", "ESC")
    owner:SetBindingClick(true, "BUTTON2", "CombatModePingMenuKey", "ESC")
    return false
  end
  if not owner:IsShown() then return false end
  local slot = 0
  local mx,my = owner:GetMousePosition()
  if mx then
    local dx,dy = (mx-.5)*owner:GetWidth(), (my-.5)*owner:GetHeight()
    local dead = owner:GetAttribute("dead") or 50
    if dx*dx+dy*dy > dead*dead then
      local best = -100000000
      for i=1,4 do
        local dot = dx*owner:GetAttribute("x"..i)+dy*owner:GetAttribute("y"..i)
        if dot>best then slot=i;best=dot end
      end
    end
  end
  self:SetAttribute("useOnKeyDown", false)
  return "s"..slot, true
]]
for i = 0, #entries do
  local slice =
    _G.CreateFrame("Button", "CombatModePingMenuSlice" .. i, wheel, "SecureActionButtonTemplate")
  slice:SetSize(1, 1)
  slice:RegisterForClicks("AnyUp")
  slice:SetAttribute("useOnKeyDown", false)
  slice:SetAttribute("type", "macro")
  local macro = CM.Constants.ClickCastPingMacros.TOGGLEPINGLISTENER
  if i > 0 then
    local _
    _, macro = CM.RadialEntrySecure(entries[i])
  end
  slice:SetAttribute("macrotext", macro)
  slice:SetAttribute("locationping", true)
  slice:EnableMouse(false)
  CM.HookReticlePingButton(slice)
  _G.SecureHandlerWrapScript(slice, "OnClick", wheel, "return nil, true", HIDE)
  key:SetAttribute("*clickbutton-s" .. i, slice)
end
_G.SecureHandlerWrapScript(key, "OnClick", wheel, PRE)
_G.SecureHandlerSetFrameRef(wheel, "radial", CM.RadialGetWheelFrame())
_G.SecureHandlerSetFrameRef(CM.RadialGetWheelFrame(), "ping", wheel)
local party = CM.PartyWheelGetFrame and CM.PartyWheelGetFrame()
if party then
  _G.SecureHandlerSetFrameRef(party, "ping", wheel)
  _G.SecureHandlerSetFrameRef(wheel, "party", party)
end
wheel:HookScript("OnShow", function()
  CM.RadialViewShown("ping")
  if _G.GameTooltip then
    _G.GameTooltip:Hide()
  end
  if CM.ReconcileFreeLook then
    CM.ReconcileFreeLook()
  end
end)
wheel:HookScript("OnHide", function()
  CM.RadialViewHidden()
  if CM.ReconcileFreeLook then
    CM.ReconcileFreeLook()
  end
end)
function CM.IsPingMenuOpen()
  return wheel:IsShown()
end
function CM.PingMenuGetFrame()
  return wheel
end
function CM.PingMenuCurrent()
  return 1, 0, entries, pingWheel.name
end
function CM.PingMenuAimSlot()
  if not wheel:IsShown() then
    return 0
  end
  local left, bottom, width, height = wheel:GetRect()
  if not left or width <= 0 or height <= 0 then
    return 0
  end
  local cx, cy = _G.GetCursorPosition()
  local scale = wheel:GetEffectiveScale()
  local dx, dy = cx / scale - left - width / 2, cy / scale - bottom - height / 2
  local dead = CM.RadialStyle().dead
  if dx * dx + dy * dy <= dead * dead then
    return 0
  end
  local best, slot = -math.huge, 0
  for i = 1, 4 do
    local x, y = CM.RadialSlotDir(i, 4)
    local dot = dx * x + dy * y
    if dot > best then
      best, slot = dot, i
    end
  end
  return slot
end
function CM.RefreshPingMenu()
  if not CM.DB or _G.InCombatLockdown() then
    return
  end
  wheel:SetAttribute("yoff", CM.DB.char.crosshairY or 0)
  wheel:SetAttribute("dead", CM.RadialStyle().dead)
  for i = 1, 4 do
    local x, y = CM.RadialSlotDir(i, 4)
    wheel:SetAttribute("x" .. i, x)
    wheel:SetAttribute("y" .. i, y)
  end
  _G.ClearOverrideBindings(owner)
  for _, command in ipairs(COMMANDS) do
    for _, binding in ipairs({ _G.GetBindingKey(command) }) do
      _G.SetOverrideBindingClick(owner, true, binding, key:GetName(), "LeftButton")
    end
  end
end
-- Binding changes from Blizzard's keybinding UI also need fresh overrides.
local lifecycle = _G.CreateFrame("Frame")
lifecycle:RegisterEvent("PLAYER_LOGIN")
lifecycle:RegisterEvent("UPDATE_BINDINGS")
lifecycle:SetScript("OnEvent", function()
  CM.TryApplyBindingChange(L["Separate Ping Wheel"], CM.RefreshPingMenu)
end)
