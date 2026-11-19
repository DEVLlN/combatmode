-- Exercise the Click Casting entry point without a bar slot or Target Lock setting.
return function(Check, CM)
  local original = CM.SetModeMacroText
  local frame, normal, support
  CM.SetModeMacroText = function(proxy, normalText, supportText)
    frame, normal, support = proxy, normalText, supportText
  end

  CM.SetNewBinding({ enabled = true, key = "BUTTON1", value = "LOCKANDATTACK" })
  local baseFrame = frame
  local macro = normal
  CM.SetNewBinding({ enabled = true, key = "SHIFT-BUTTON2", value = "LOCKANDATTACK" })
  CM.SetModeMacroText = original

  Check(
    "base and modifier slots use distinct proxies",
    baseFrame ~= nil and frame ~= baseFrame,
    true
  )
  Check("both slots run the same macro", normal, macro)
  Check(
    "aimed living enemy takes priority over the existing enemy lock",
    macro,
    table.concat({
      "/clearfocus [@focus,dead]",
      "/focus [@mouseover,harm,nodead][@focus,harm,nodead][harm,nodead]",
      "/tar [@focus,harm,nodead]",
      "/startattack [harm,nodead]",
    }, "\n")
  )
  Check("Support Mode keeps its ally focus", support, CM.Constants.Macros.CM_StartAttack)
end
