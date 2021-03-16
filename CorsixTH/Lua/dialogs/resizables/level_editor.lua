--[[ Copyright (c) 2021 Albert "Alberth" Hofkamp

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. --]]


local CHAR_WIDTH = 7 -- Assumed general width of a character.
local HEIGHT = 15

local function getLabelWidth(field)
  return #field.label * CHAR_WIDTH
end

local function getMaxLabelWidth(list)
  local max_val = 0
  for _, field in pairs(list) do
    max_val = math.max(max_val, getMaxLabelWidth(field))
  end
  return max_val
end


class "SalariesPage"

--@type SalariesPage
local SalariesPage = _G["SalariesPage"]


function SalariesPage:SalariesPage()
end

local min_salaries_fields = {
  { path = "staff.0.MinSalary",
    tool_tip = "Minimum salary of a nurse.",
    min_val = 0,
    label = "Nurse",
    default_val = 45,
  },
  { path = "staff.1.MinSalary",
    tool_tip = "Minimum salary of a doctor.",
    min_val = 0,
    label = "Doctor",
    default_val = 60,
  },
  { path = "staff.2.MinSalary",
    tool_tip = "Minimum salary of a handyman.",
    min_val = 0,
    label = "Handyman",
    default_val = 20,
  },
  { path = "staff.3.MinSalary",
    tool_tip = "Minimum salary of a receptionist.",
    min_val = 0,
    label = "Receptionist",
    default_val = 15,
  },
}
local doctor_salary_adjustment_fields = {
  { path = "gbv.SalaryAdd.3",
    tool_tip = "Salary adjustment for juniors (make negative).",
    label = "Junior",
    default_val = -30,
  },
  { path = "gbv.SalaryAdd.4",
    tool_tip = "Salary adjustment for doctors.",
    label = "Doctor",
    default_val = 15,
  },
  { path = "gbv.SalaryAdd.5",
    tool_tip = "Salary adjustment for doctors.",
    label = "Surgeon",
    default_val = 20,
  },
  { path = "gbv.SalaryAdd.6",
    tool_tip = "Salary adjustment for shrinks.",
    label = "Shrink",
    default_val = 15,
  },
  { path = "gbv.SalaryAdd.7",
    tool_tip = "Salary adjustment for consultants.",
    label = "Consultant",
    default_val = 50,
  },
  { path = "gbv.SalaryAdd.8",
    tool_tip = "Salary adjustment for researchers.",
    label = "Research",
    default_val = 10,
  },
}
-- XXX name = "Salary adjustments for doctors",
-- XXX  name = "Minimum salaries",
function SalariesPage:getFields()
  return {salaries_fields, doctor_salaries_adjustment_fields}
end

function SalariesPage:constructPage(window)
  local labelWidth = getMaxLabelWidth(min_salaries_fields)
  local x = 5
  local y = 10
  for _, field in ipairs(min_salaries_fields) do
    
  end

end

class "UILevelEditor" (UIResizable)


--@type UILevelEditor
local UILevelEditor = _G["UILevelEditor"]


local window_xsize = 500
local window_ysize = 500
local col_bg = {red = 154, green = 146, blue = 198}

function UILevelEditor:UILevelEditor(ui)
  self:UIResizable(ui, window_xsize, window_ysize, col_bg)
  self.resizable = false
  self.ui = ui
  self:setPosition(0.1, 0.1)

  self.label_font = TheApp.gfx:loadFont("QData", "Font01V")

local col_bg = { red = 154, green = 146, blue = 198, }
local col_textbox = { red = 0, green = 0, blue = 0, }
local col_highlight = { red = 174, green = 166, blue = 218, }
local col_shadow = { red = 134, green = 126, blue = 178, }
local col_caption = { red = 174, green = 166, blue = 218, }

local myvalues = {}

local function label_value_column(window, column_params, elements, values)
  local y = column_params.top
  local h = column_params.height
  local dy = h + column_params.vspace

  local cx = column_params.column_x
  local mid_space = math.floor(column_params.mid_space / 2)
  local lw = column_params.label_width
  local lx = cx - mid_space - lw
  local rx = cx + mid_space
  local rw = column_params.value_width

  local panel
  if column_params.title then -- Add a title if available.
    panel = window:addBevelPanel(lx, y, rx + rw - lx, h,
        col_shadow, col_bg, col_bg)
    panel:setLabel(column_params.title)
    y = y + dy
  end

  -- Add all elements.
  for _, element in pairs(elements) do
    local textbox
    local function confirm()
      local val = math.floor(tonumber(textbox.text))
      if element.min_val then val = math.max(val, element.min_val) end
      if element.max_val then val = math.min(val, element.max_val) end
      values[element.path] = val
    end
    local function abort()
      local val = values[element.path] or element.default_val
      textbox:setText(tostring(val))
    end

    panel = window:addBevelPanel(lx, y, lw, h, col_shadow, col_bg, col_bg)
    panel:setLabel(element.label)

    panel = window:addBevelPanel(rx, y, rw, h, col_textbox, col_highlight,
        col_shadow)
    if element.tool_tip then panel:setTooltip(element.tool_tip) end
    textbox = panel:makeTextbox(confirm, abort)
    textbox:allowedInput("numbers")
    textbox:characterLimit(column_params.max_value_chars)

    local val = values[element.path] or element.default_val
    textbox:setText(tostring(val))

    y = y + dy
  end
end

local column_params = {
  top = 40, -- Horizontal top of the first element.
  column_x = 150, -- Center x position between label and value.
  label_width = 120, -- Length of the label.
  mid_space = 10, -- Amount of space between label and value.
  value_width = 70, -- Length of the value.
  height = 20, -- Height of both label and value.
  vspace = 5, -- Amount of space between two values.
  max_value_chars = 4, -- Maximum number of characters in the value.

  title = "Minimum salaries"
}

local column_params2 = {
  top = 190, -- Horizontal top of the first element.
  column_x = 150, -- Center x position between label and value.
  label_width = 120, -- Length of the label.
  mid_space = 10, -- Amount of space between label and value.
  value_width = 70, -- Length of the value.
  height = 20, -- Height of both label and value.
  vspace = 5, -- Amount of space between two values.
  max_value_chars = 4, -- Maximum number of characters in the value.

  title = "Adjustments for doctors"
}


  label_value_column(self, column_params, min_salaries_fields, myvalues)
  label_value_column(self, column_params2, doctor_salary_adjustment_fields, myvalues)


--local function cf() print("confirm") end
--local function ab() print("abort") end
--  self:addBevelPanel(20, 40, 80, 20, col_shadow, col_bg, col_bg):setLabel("width")
--  self.width_textbox = self:addBevelPanel(100, 40, 80, 20, col_textbox, col_highlight, col_shadow)
--    :setTooltip("width of the window")
--    :makeTextbox(cf,ab):allowedInput("numbers"):characterLimit(4):setText("345")

end
