-- Ping actions must exist in the final registry on every supported client.
return function(Check, CM, env)
  for _, id in ipairs({ "pingattack", "pingwarning", "pingonmyway", "pingassist" }) do
    local action = CM.RadialActions.byId[id]
    Check(id .. " registered", action ~= nil, true)
    Check(id .. " is a ping", action and action.locationPing, true)
  end
  for _, id in ipairs({ "readycheck", "countdown", "rolepoll", "tm0", "wm1", "pingwarning" }) do
    Check(
      id .. " belongs on the Ping wheel",
      CM.RadialActions.IsPingWheelAction(CM.RadialActions.byId[id]),
      true
    )
  end
  for _, id in ipairs({ "reloadui", "leaveparty", "mount", "roll", "clearfocus" }) do
    Check(
      id .. " is excluded from the Ping wheel",
      CM.RadialActions.IsPingWheelAction(CM.RadialActions.byId[id]),
      false
    )
    Check(
      id .. " in old Ping slots cannot run",
      CM.RadialEntrySecure({ kind = "action", id = id }, true),
      nil
    )
  end
  local skull = { kind = "action", id = "tm8" }
  local kind, markerText, isMacroText, aim = CM.RadialEntrySecure(skull, true)
  Check("Ping target marker is a secure macro", kind, "macro")
  Check("target marker needs the cursor recentered", aim, true)
  Check("secure macro text is enabled", isMacroText, true)
  Check(
    "the marker prefers the aimed unit or a selected target",
    markerText:match("^[^\n]+"),
    "/tm [@mouseover,exists][@target,exists] 8"
  )
  Check(
    "soft targeting is available before engaging a unit",
    markerText:match("[^\n]+$"),
    "/tm [@softenemy,exists][@softfriend,exists] 8"
  )
  Check(
    "soft targeting does not mark a locked unit on a miss",
    markerText:find("[@focus,exists]", 1, true) ~= nil,
    true
  )
  local _, regularMarker = CM.RadialEntrySecure(skull)
  Check("ordinary radial markers retain their selected-target behavior", regularMarker, "/tm 8")
  local _, worldMarker, _, worldAim = CM.RadialEntrySecure({ kind = "action", id = "wm1" }, true)
  Check("world markers keep Blizzard's placement cursor", worldMarker, "/wm 1")
  Check("world markers do not use unit aiming", worldAim, nil)
  local contextual = CM.Constants.ClickCastPingMacros.TOGGLEPINGLISTENER
  Check(
    "quick ping follows the cursor independently of soft targets",
    contextual,
    "/ping [@mouseover,exists]" .. "\n/stopmacro [@mouseover,exists]\n/ping"
  )
  Check(
    "the existing Click Casting action uses the ground fallback",
    CM.Constants.BlizzardActionMacros.TOGGLEPINGLISTENER,
    contextual
  )
  local oldDB, oldRefresh = CM.DB, CM.RadialRefresh
  CM.RadialRefresh = nil
  CM.DB =
    { char = { radialMenu = { presetsSeeded = true, wheels = {} }, separatePingPrimaryMouse = {} } }
  local index = 1
  local wheel = CM.RadialGetWheels()[index]
  Check("existing configurations get Ping by default", CM.RadialIsPingWheel(wheel), true)
  Check("Ping preset is editable", wheel.locked, nil)
  Check("Ping preset has four slices", CM.RadialSliceCount(wheel), 4)
  CM.RadialSetSlot(index, 1, nil)
  Check("can clear a Ping slot", wheel.slots[1], nil)
  Check("can add a Ping slice", CM.RadialAddSlice(index), true)
  Check("can remove a Ping slice", CM.RadialRemoveSlice(index, 5), true)
  CM.RadialReorderSlots(index, { 4, 3, 2, 1 })
  Check("can reorder Ping slots", wheel.slots[1].id, "pingassist")
  wheel.locked, wheel.preset = true, "ping"
  Check("old locked wheel stays in place", CM.RadialGetWheels()[1], wheel)
  Check("old locked wheel unlocks without resetting its slots", wheel.locked, nil)
  Check("adding Ping again selects the existing wheel", CM.RadialCreateWheel(nil, "ping"), 1)
  Check("only one Ping wheel is created", #CM.RadialGetWheels(), 1)
  CM.RadialDeleteWheel(index)
  Check("can delete the Ping preset", #CM.RadialGetWheels(), 0)
  Check("explicitly adding Ping remains available", CM.RadialCreateWheel(nil, "ping"), 1)
  local oldAssign, oldOverride = CM.AssignNamedKeybind, CM.OverrideDefaultButtons
  local oldGetKey, oldSetClick = env.GetBindingKey, env.SetOverrideBindingClick
  local oldSetMouse = env.SetMouselookOverrideBinding
  local oldInCombat = env.InCombatLockdown
  local primary = "Combat Mode - Ping Menu"
  local native, direct, cleared = {}, {}, {}
  local oldClearOverrides = env.ClearOverrideBindings
  env.InCombatLockdown = function()
    return false
  end
  env.GetBindingKey = function(command)
    return native[command]
  end
  env.ClearOverrideBindings = function()
    direct = {}
  end
  env.SetOverrideBindingClick = function(_, _, binding, _, route)
    direct[binding] = route
  end
  env.SetMouselookOverrideBinding = function(binding, action)
    cleared[binding] = action == nil
  end
  CM.OverrideDefaultButtons = function() end
  CM.AssignNamedKeybind = function(command, binding)
    native[command] = binding ~= "" and binding or nil
  end
  CM.RadialRefresh = CM.RefreshPingMenu
  Check(
    "a new character starts with Separate Ping Wheel off",
    CM.IsSeparatePingWheelEnabled(),
    false
  )
  native[primary] = "BUTTON3"
  Check("an existing middle-mouse binding opts in", CM.IsSeparatePingWheelEnabled(), true)
  native[primary] = nil
  CM.SetSeparatePingWheelEnabled(true)
  Check("the toggle stays on while waiting for a bind", CM.IsSeparatePingWheelEnabled(), true)
  Check(
    "Ping stays available in the shared wheel while unbound",
    CM.HasSeparatePingBinding(),
    false
  )
  CM.SetSeparatePingBinding("BUTTON2")
  Check("right-click binding is visible in the panel", CM.GetSeparatePingBinding(), "BUTTON2")
  Check(
    "right-click uses the Mouse Look binding",
    CM.GetPingMouseLookAction("BUTTON2") ~= nil,
    true
  )
  Check("right-click keeps its ordinary WoW binding", native[primary], nil)
  CM.SetSeparatePingBinding("CTRL-BUTTON5")
  Check("modifier plus side button gets a route", direct["CTRL-BUTTON5"], "ping")
  CM.SetSeparatePingBinding("PAD1")
  Check("gamepad gets a route", direct.PAD1, "ping")
  CM.SetSeparatePingBinding("SHIFT-Q")
  Check("keyboard chord gets a route", direct["SHIFT-Q"], "ping")
  Check("rebinding clears the old Mouse Look override", cleared.BUTTON2, true)
  Check("rebinding restores the right-click slot", CM.GetPingMouseLookAction("BUTTON2"), nil)
  local frame = CM.RadialGetWheelFrame()
  local oldRead, oldWrite = frame.GetAttribute, frame.SetAttribute
  local attrs = {}
  frame.GetAttribute = function(_, name)
    return attrs[name]
  end
  frame.SetAttribute = function(_, name, value)
    attrs[name] = value
  end
  local oldApply, oldViewRefresh = CM.TryApplyBindingChange, CM.RadialViewRefresh
  CM.TryApplyBindingChange = function(_, apply)
    apply()
  end
  CM.RadialViewRefresh = nil
  CM.RadialRefresh = oldRefresh
  CM.RadialRefresh()
  local _, pages = CM.RadialCurrent()
  Check("dedicated Ping skips the shared wheel", pages, 0)
  local dedicated = CM.RadialGetDedicatedPingWheel()
  Check("both modes use the same editable wheel", dedicated, CM.RadialGetWheels()[1])
  Check("can add a slice by wheel reference", CM.RadialAddSlice(dedicated), true)
  CM.RadialSetSlot(dedicated, 5, { kind = "spell", id = 123 })
  Check("Ping rejects new spells", dedicated.slots[5], nil)
  CM.RadialSetSlot(dedicated, 5, { kind = "macro", id = "Custom Ping" })
  Check("Ping rejects new macros", dedicated.slots[5], nil)
  CM.RadialSetSlot(dedicated, 5, { kind = "action", id = "reloadui" })
  Check("Ping rejects unrelated commands through the setter", dedicated.slots[5], nil)
  CM.RadialSetSlot(dedicated, 5, { kind = "action", id = "tm0" })
  Check("Ping accepts raid markers", dedicated.slots[5].id, "tm0")
  CM.RadialSetSlot(dedicated, 5, { kind = "action", id = "readycheck" })
  Check("Ping accepts commands", dedicated.slots[5].id, "readycheck")
  CM.RadialReorderSlots(dedicated, { 5, 4, 3, 2, 1 })
  local _, _, dedicatedEntries = CM.PingMenuCurrent()
  Check("dedicated menu uses edited order", dedicatedEntries[1].id, "readycheck")
  Check("dedicated menu supports more than four slices", #dedicatedEntries, 5)
  Check("dedicated menu retains normal ping actions", dedicatedEntries[5].id, "pingattack")
  CM.SetSeparatePingWheelEnabled(false)
  _, pages = CM.RadialCurrent()
  Check("turning off the toggle restores the shared wheel", pages, 1)
  local _, _, sharedEntries = CM.RadialCurrent()
  Check("returning to the shared menu keeps the custom slice", sharedEntries[1].id, "readycheck")
  Check("the disabled binding does not run a secure override", direct["SHIFT-Q"], nil)
  Check("turning off the toggle remembers the key", CM.GetSeparatePingBinding(), "SHIFT-Q")
  CM.SetSeparatePingWheelEnabled(true)
  _, pages = CM.RadialCurrent()
  Check("re-enabling restores the dedicated bind", direct["SHIFT-Q"], "ping")
  Check("the shared wheel skips Ping again", pages, 0)
  CM.SetSeparatePingBinding("")
  _, pages = CM.RadialCurrent()
  Check("clearing the bind restores the shared wheel", pages, 1)
  Check(
    "clearing the key leaves the binding control enabled",
    CM.IsSeparatePingWheelEnabled(),
    true
  )
  frame.GetAttribute, frame.SetAttribute = oldRead, oldWrite
  CM.TryApplyBindingChange, CM.RadialViewRefresh = oldApply, oldViewRefresh
  env.ClearOverrideBindings = oldClearOverrides
  CM.AssignNamedKeybind, CM.OverrideDefaultButtons = oldAssign, oldOverride
  env.GetBindingKey, env.SetOverrideBindingClick = oldGetKey, oldSetClick
  env.SetMouselookOverrideBinding, env.InCombatLockdown = oldSetMouse, oldInCombat
  local oldTimer = env.C_Timer
  local oldLock, oldUnlock = CM.LockFreeLook, CM.UnlockFreeLook
  local oldCenter, oldReconcile = CM.SetCursorFreelookCentering, CM.ReconcileFreeLook
  local callbacks, restored = {}, 0
  env.C_Timer = {
    After = function(_, callback)
      callbacks[#callbacks + 1] = callback
    end,
  }
  CM.LockFreeLook = function() end
  CM.UnlockFreeLook = function() end
  CM.SetCursorFreelookCentering = function() end
  CM.ReconcileFreeLook = function()
    restored = restored + 1
  end
  local locationPing, hooks = true, {}
  local button = {
    GetAttribute = function(_, name)
      return name == "locationping" and locationPing
    end,
    HookScript = function(_, name, handler)
      hooks[name] = handler
    end,
  }
  CM.HookReticlePingButton(button)
  hooks.PreClick(button, "LeftButton", true)
  Check("press does not unlock before the release", #callbacks, 0)
  locationPing = false
  hooks.PreClick(button, "LeftButton", false)
  hooks.PostClick(button, "LeftButton", false)
  Check("ordinary Click Casting actions leave Mouse Look alone", #callbacks, 0)
  locationPing = true
  hooks.PreClick(button, "LeftButton", false)
  Check("ping temporarily releases Mouse Look", CM.locationPingActive, true)
  callbacks[1]()
  Check("a dropped click still restores Mouse Look", CM.locationPingActive, false)
  hooks.PreClick(button, "LeftButton", false)
  hooks.PostClick(button, "LeftButton", false)
  callbacks[3]()
  callbacks[2]()
  Check("PostClick restores only once", restored, 2)
  local oldCursor = env.GetCursorPosition
  local recenterCount = 0
  CM.LockFreeLook = function()
    recenterCount = recenterCount + 1
  end
  local wheelFrame = {
    GetCenter = function()
      return 250, 300
    end,
    GetEffectiveScale = function()
      return 2
    end,
  }
  env.GetCursorPosition = function()
    return 501, 600
  end
  CM.PrepareLocationPingAtReticle(wheelFrame)
  Check("a centered tap preserves mouseover", recenterCount, 0)
  env.GetCursorPosition = function()
    return 540, 600
  end
  CM.PrepareLocationPingAtReticle(wheelFrame)
  Check("releasing over a slice recenters", recenterCount, 1)
  callbacks[#callbacks]()
  env.GetCursorPosition = oldCursor
  env.C_Timer = oldTimer
  CM.LockFreeLook, CM.UnlockFreeLook = oldLock, oldUnlock
  CM.SetCursorFreelookCentering, CM.ReconcileFreeLook = oldCenter, oldReconcile
  CM.DB, CM.RadialRefresh = oldDB, oldRefresh
end
