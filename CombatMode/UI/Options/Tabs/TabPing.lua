---------------------------------------------------------------------------------------
--  UI/Options/Tabs/TabPing.lua — OPTIONS — dedicated Ping menu
---------------------------------------------------------------------------------------
-- What it does: Provides dedicated Ping controls.
-- Architecture: Secure click buttons share the radial renderer; settings use named bindings.
-- Does not: Change player bindings automatically.
-- Related: Core/RadialMenu/View.lua, Core/FreeLook/FreeLookController.lua.
local _, CM = ...
local L = CM.L
local _G = _G
CM.UI.Options.AddTab({
  id = "ping",
  label = L["Ping"],
  build = function(ctx)
    ctx:Header(L["PING"])
    ctx:Description(
      L["Tap to ping the unit or ground under your reticle. Hold, choose Attack, Warning, On My Way or Assist, then release. Escape or right-click cancels the menu."]
    )
    for index, command in ipairs(CM.PingMenuBindingCommands) do
      ctx:Keybind({
        label = index == 1 and L["Primary Keybind"] or L["Secondary Keybind"],
        desc = L["Open the dedicated Ping menu. Both keybinds have the same tap and hold behavior."],
        get = function()
          return _G.GetBindingKey(command)
        end,
        set = function(binding)
          CM.TryApplyBindingChange(L["Ping menu keybinding"], function()
            CM.AssignNamedKeybind(command, binding)
            CM.RefreshPingMenu()
          end)
        end,
      })
    end
  end,
})
