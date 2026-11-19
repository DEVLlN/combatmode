-- Ping actions must exist in the final registry on every supported client.
return function(Check, CM, env)
  for _, id in ipairs({ "pingattack", "pingwarning", "pingonmyway", "pingassist" }) do
    local action = CM.RadialActions.byId[id]
    Check(id .. " registered", action ~= nil, true)
    Check(id .. " is a ping", action and action.locationPing, true)
  end
  Check("primary command", CM.PingMenuBindingCommands[1], "Combat Mode - Ping Menu")
  Check("secondary command", CM.PingMenuBindingCommands[2], "Combat Mode - Ping Menu Secondary")
  local oldDB, oldRefresh = CM.DB, CM.RadialRefresh
  CM.RadialRefresh = nil
  CM.DB = { char = { radialMenu = { presetsSeeded = true, wheels = {} } } }
  local index = CM.RadialCreateWheel(nil, "ping")
  local wheel = CM.RadialGetWheels()[index]
  Check("Ping preset is locked", wheel.locked, true)
  Check("Ping preset has four slices", CM.RadialSliceCount(wheel), 4)
  CM.RadialSetSlot(index, 1, nil)
  Check("cannot clear a Ping slot", wheel.slots[1].id, "pingattack")
  Check("cannot add a Ping slice", CM.RadialAddSlice(index), false)
  Check("cannot remove a Ping slice", CM.RadialRemoveSlice(index, 1), false)
  CM.RadialReorderSlots(index, { 4, 3, 2, 1 })
  Check("cannot reorder Ping slots", wheel.slots[1].id, "pingattack")
  CM.RadialDeleteWheel(index)
  Check("can delete the Ping preset", #CM.RadialGetWheels(), 0)
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
  CM.PrepareLocationPingAtReticle()
  Check("ping temporarily releases Mouse Look", CM.locationPingActive, true)
  callbacks[1]()
  Check("a dropped click still restores Mouse Look", CM.locationPingActive, false)
  CM.PrepareLocationPingAtReticle()
  CM.FinishLocationPing()
  callbacks[3]()
  callbacks[2]()
  Check("PostClick restores only once", restored, 2)
  env.C_Timer = oldTimer
  CM.LockFreeLook, CM.UnlockFreeLook = oldLock, oldUnlock
  CM.SetCursorFreelookCentering, CM.ReconcileFreeLook = oldCenter, oldReconcile
  CM.DB, CM.RadialRefresh = oldDB, oldRefresh
end
