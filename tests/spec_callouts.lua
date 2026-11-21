return function(check, CM)
  local db, refresh = CM.DB, CM.RadialRefresh
  CM.DB = { char = { radialMenu = { presetsSeeded = true, wheels = {} } } }
  CM.RadialRefresh = nil
  local wheels = CM.RadialGetWheels()
  check("Callouts does not add a wheel automatically", #wheels, 0)

  local fixed = CM.RadialCreateWheel(nil, "ping")
  local custom = CM.RadialCreateWheel(nil, "callouts")
  check("the Ping preset remains locked", wheels[fixed].locked, true)
  check("Callouts is a separate editable preset", CM.RadialIsCalloutWheel(wheels[custom]), true)
  check("Callouts starts with the four ping actions", CM.RadialSliceCount(wheels[custom]), 4)
  check("Callouts supports additional slices", CM.RadialAddSlice(custom), true)
  CM.RadialSetSlot(custom, 5, { kind = "macro", id = "Test" })
  CM.RadialSetSlot(custom, 5, { kind = "spell", id = 123 })
  CM.RadialSetSlot(custom, 5, { kind = "action", id = "reloadui" })
  check("other types and unrelated commands cannot be added", wheels[custom].slots[5], nil)
  CM.RadialSetSlot(custom, 5, { kind = "action", id = "readycheck" })
  check("group checks are available", wheels[custom].slots[5].id, "readycheck")
  CM.RadialSetSlot(custom, 5, { kind = "action", id = "tm8" })
  check("target markers are available", wheels[custom].slots[5].id, "tm8")
  CM.RadialReorderSlots(custom, { 5, 1, 2, 3, 4 })
  check("the marker can be moved", wheels[custom].slots[1].id, "tm8")

  local skull = wheels[custom].slots[1]
  local kind, text, isText, aim = CM.RadialEntrySecure(skull, true)
  check("marker uses a secure macro", kind, "macro")
  check("marker supplies macro text", isText, true)
  check("marker reuses the cursor-centering hook", aim, true)
  check(
    "marker prefers mouseover and falls back to the selected target",
    text:match("^[^\n]+"),
    "/tm [@mouseover,exists][@target,exists] 8"
  )
  check(
    "marker can use an unselected soft target",
    text:match("[^\n]+$"),
    "/tm [@softenemy,exists][@softfriend,exists] 8"
  )
  check(
    "marker guards the soft target fallback when there is a lock",
    text:find("[@focus,exists]", 1, true) ~= nil,
    true
  )
  local _, ordinaryMarker = CM.RadialEntrySecure(skull)
  check(
    "target marker on the ordinary wheel still uses the selected target",
    ordinaryMarker,
    "/tm 8"
  )
  local _, worldMarker, _, worldAim = CM.RadialEntrySecure({ kind = "action", id = "wm1" }, true)
  check("world marker uses normal placement", worldMarker, "/wm 1")
  check("world marker skips unit aiming", worldAim, nil)
  check(
    "unsupported actions in saved Callouts slots are skipped",
    CM.RadialEntrySecure({ kind = "action", id = "mount" }, true),
    nil
  )

  CM.DB, CM.RadialRefresh = db, refresh
end
