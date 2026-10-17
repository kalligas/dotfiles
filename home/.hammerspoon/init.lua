-- The local CLI lets configuration checks report errors without opening a console.
require("hs.ipc")
hs.autoLaunch(true)

local log = hs.logger.new("minimize-all", "info")

local function minimizeAllWindows()
  if not hs.accessibilityState() then
    hs.alert.show("Enable Hammerspoon in Privacy & Security > Accessibility")
    return
  end

  -- Keep window objects before minimizing; app window ordering can change.
  local targets = {}
  for _, window in ipairs(hs.window.allWindows()) do
    local element = hs.axuielement.windowElement(window)
    if element and not window:isFullScreen() and element:attributeValue("AXMinimized") == false then
      table.insert(targets, { window = window, element = element })
      window:minimize()
    end
  end

  hs.timer.doAfter(0.3, function()
    for _, target in ipairs(targets) do
      if target.element:attributeValue("AXMinimized") == false then
        local button = target.element:attributeValue("AXMinimizeButton")
        if button then button:performAction("AXPress") end
      end
    end
    hs.timer.doAfter(0.3, function()
      local remaining = 0
      for _, target in ipairs(targets) do
        if target.element:attributeValue("AXMinimized") == false then
          remaining = remaining + 1
        end
      end
      if remaining > 0 then
        log.wf("%d windows did not minimize", remaining)
        hs.alert.show(string.format("%d windows could not be minimized", remaining))
      end
    end)
  end)
end

-- A global hotkey intercepts Command-M before the active app's Minimize command.
minimizeAllHotkey = assert(hs.hotkey.bind({ "cmd" }, "m", minimizeAllWindows),
  "Could not register Command-M")
