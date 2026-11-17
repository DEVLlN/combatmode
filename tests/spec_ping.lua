-- Ping actions must exist in the final registry on every supported client.
return function(Check, CM)
  for _, id in ipairs({ "pingattack", "pingwarning", "pingonmyway", "pingassist" }) do
    local action = CM.RadialActions.byId[id]
    Check(id .. " registered", action ~= nil, true)
    Check(id .. " is a ping", action and action.locationPing, true)
  end
  Check("primary command", CM.PingMenuBindingCommands[1], "Combat Mode - Ping Menu")
  Check("secondary command", CM.PingMenuBindingCommands[2], "Combat Mode - Ping Menu Secondary")
end
