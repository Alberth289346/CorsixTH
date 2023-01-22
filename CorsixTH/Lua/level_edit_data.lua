--[[ Copyright (c) 2023 Albert "Alberth" Hofkamp

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

require("pos_size")
require("tree_access")

local lang_prefix = "level_editor"

-- Temporary language strings of the level editor values.
local default_translations = {
  -- Pages
  ["level_editor.pages.staffpage"] = "Staff properties",
  -- Min salaries
  ["level_editor.titles.min_salaries_title"] = "Minimum salaries",
  ["level_editor.nurse.min_salary.name"] = "Nurse minimum",
  ["level_editor.doctor.min_salary.name"] = "Doctor minimum",
  ["level_editor.handyman.min_salary.name"] = "Handyman minimum",
  ["level_editor.receptionist.min_salary.name"] = "Receptionist minimum",
  ["level_editor.nurse.min_salary.tooltip"] = "Minimum salary of a Nurse",
  ["level_editor.doctor.min_salary.tooltip"] = "Minimum salary of a Doctor",
  ["level_editor.handyman.min_salary.tooltip"] = "Minimum salary of a Handyman",
  ["level_editor.receptionist.min_salary.tooltip"] = "Minimum salary of a Receptionist",
  -- Doctors salaries
  ["level_editor.junior.salary.name"] = "Junior addition",
  ["level_editor.junior.salary.tooltip"] = "Relative to minimum doctor salary, make negative",
  ["level_editor.doctor.salary.name"] = "Doctor addition",
  ["level_editor.doctor.salary.tooltip"] = "Relative to minimum doctor salary",
  ["level_editor.surgeon.salary.name"] = "Surgeon addition",
  ["level_editor.surgeon.salary.tooltip"] = "Relative to minimum doctor salary",
  ["level_editor.shrink.salary.name"] = "Psychiatrist addition",
  ["level_editor.shrink.salary.tooltip"] = "Relative to minimum doctor salary",
  ["level_editor.consultant.salary.name"] = "Consultant addition",
  ["level_editor.consultant.salary.tooltip"] = "Relative to minimum doctor salary",
  ["level_editor.research.salary.name"] = "Research addition",
  ["level_editor.research.salary.tooltip"] = "Relative to minimum doctor salary",
  -- Staff resting amounts
  ["level_editor.staff_rest.standing"] = "Amount of rest while standing in the staff room",
  ["level_editor.staff_rest.sofa"] = "Amount of rest while sitting at a sofa in the staff room",
  ["level_editor.staff_rest.game"] = "Amount of rest while playing a game in the staff room",
  ["level_editor.staff_rest.snooker"] = "Amount of rest while playing snooker in the staff room",
  ["level_editor.staff_tiring.work"] = "Amount of tiring while working",
  -- Unit names
  ["level_editor.unit_names.money"] = "$",
}

local function substBrackets(text, insert_value)
  if not insert_value then return text end
  return string.gsub(text, "[[]]", "[" .. insert_value .. "]")
end

local function makeNumericValue(level_cfg_path, path_identifier, min_value, max_value, unit_name_path, key_value)
  local base_path = lang_prefix .. "."
  return {
    level_cfg_path = substBrackets(level_cfg_path, key_value),
    name_path = substBrackets(base_path .. path_identifier ..".name", key_value),
    tooltip_path = substBrackets(base_path .. path_identifier ..".tooltip", key_value),
    unit_path = unit_name_path and lang_prefix .. ".unit_names." .. unit_name_path,
    min_value = min_value,
    max_value = max_value
  }
end

local min_salary_values = {
  makeNumericValue("#staff[].MinSalary", "nurse.min_salary", 0, nil, "money", 0),
  makeNumericValue("#staff[].MinSalary", "doctor.min_salary", 0, nil, "money", 1),
  makeNumericValue("#staff[].MinSalary", "handyman.min_salary", 0, nil, "money", 2),
  makeNumericValue("#staff[].MinSalary", "receptionist.min_salary", 0, nil, "money", 3),
  makeNumericValue("#gbv.SalaryAdd[]", "junior.salary", nil, 0, "money", 3),
  makeNumericValue("#gbv.SalaryAdd[]", "doctor.salary", 0, nil, "money", 4),
  makeNumericValue("#gbv.SalaryAdd[]", "surgeon.salary", 0, nil, "money", 5),
  makeNumericValue("#gbv.SalaryAdd[]", "shrink.salary", 0, nil, "money", 6),
  makeNumericValue("#gbv.SalaryAdd[]", "consultant.salary", 0, nil, "money", 7),
  makeNumericValue("#gbv.SalaryAdd[]", "research.salary", 0, nil, "money", 8),
}

local towns = {}
for i = 0, 12 do
  local start_cash = makeNumericValue("#towns[].StartCash", "towns[].start_cash", 0, nil, "money", i)
  local ill_rate = makeNumericValue("#towns[].IllRate", "towns[].ill_rate", 0, nil, nil, i)
  local interest_rate = makeNumericValue("#towns[].InterestRate", "towns[].interest_rate", 0, nil, "percentage100", i)
  towns[#towns + 1] = {start_cash, ill_rate, interest_rate}
end

local PANEL_BG = {red = 100, green = 100, blue = 100}
local PANEL_FG = {red = 200, green = 200, blue = 200}
local TEXT_BG = {red = 0, green = 0, blue = 0}
local TEXT_FG = {red = 250, green = 250, blue = 250}

local function getTranslatedText(name)
  local text = TreeAccess.readTree(_S, name)
  if type(text) == "string" then return text end
  text = default_translations[name]
  if text then return text end

  print("Warning: Translated text named " .. name .. " does not exist.")
  return name
end

local function makeLabel(window, widgets, x, y, size, name_path, tooltip_path)
  local panel = window:addBevelPanel(x, y, size.w, size.h, PANEL_BG, PANEL_FG)
  if name_path then
    panel:setLabel(getTranslatedText(name_path), nil, "left")
    if tooltip_path then
      panel:setTooltip(getTranslatedText(tooltip_path))
    end
  end
  widgets[#widgets + 1] = panel
end

local function makeTextBox(window, text_boxes, x, y, size, min_val, max_val)
  local text_box = window:addBevelPanel(x, y, size.w, size.h, TEXT_BG, TEXT_FG)
  text_box = text_box:makeTextbox(nil, nil) -- confirm_cb, abort_cb)
  text_box:allowedInput("numbers")
  local length = math.max(#tostring(min_val), #tostring(max_val))
  text_box:characterLimit(length)

  text_boxes[#text_boxes + 1] = text_box
end

local function makeUnit(window, widgets, x, y, size, unit_path)
  if not unit_path then return end

  local panel = window:addBevelPanel(x, y, size.w, size.h, PANEL_BG, PANEL_FG)
  panel:setLabel(getTranslatedText(unit_path))
  widgets[#widgets + 1] = panel
end


-- {{{ Section base class
class "Section"
---@type Section
local Section = _G["Section"]

--! Base class for grouping values on some topic.
--!param title_path (str) Language path to the title name string.
function Section:Section(title_path)
  self.title_path = title_path -- Displayed name of the section.
  self.widgets = {} -- Array.

  self.title_size = Size(100, 15)
end

--! Verify that actual layout size matches with computed size.
--!param sz (Size) Size after layout.
function Section:verifySize(sz)
  local exp_sz = self:computeSize()
  assert(sz.w == exp_sz.w and sz.h == exp_sz.h, ("Wrong size: expected "
      .. "(" .. exp_sz.w .. ", " .. exp_sz.h .. "), got "
      .. "(" .. sz.w .. ", " .. sz.h .. ")"))
end

--! Compute size of the needed area to display the section.
--!return (Size) Size of the section area.
function Section:computeSize()
  assert(false, "Implement me in " .. class.type(self))
end

function Section:setTitleSize(sz)
  self.title_size = sz
  return self
end
-- }}}
-- {{{ ValueSection (Section with one or more related values).
class "ValueSection" (Section)

--! Section with one or more related values.
--!param title_path (str) Language path to the title name string.
--!param values (array of ConfigValue), values descriptions.
function ValueSection:ValueSection(title_path, values)
  Section.Section(self, title_path)
  self.values = values -- Array.
  self.text_boxes = {} -- Textbox widget for each value.

  self.label_size = Size(100, 20)
  self.value_size = Size(30, 20)
  self.unit_size = Size(20, 20)
  self.title_sep = 5
  self.value_sep = 3
end

function ValueSection:setLabelSize(sz)
  assert(class.type(sz) == "Size")
  self.label_size = sz
  return self
end

function ValueSection:setValueSize(sz)
  assert(class.type(sz) == "Size")
  self.value_size = sz
  return self
end

function ValueSection:setUnitSize(sz)
  assert(class.type(sz) == "Size")
  self.unit_size = sz
  return self
end

function ValueSection:setVertSep(title_sep, value_sep)
  self.title_sep = title_sep
  self.value_sep = value_sep
  return  self
end

--! Construct widgets in the window, with the top-left corner of the section at pos.
--!param window Window to store the new widgets.
--!param pos Top-left position of the area.
function ValueSection:layout(window, pos)
  -- Clear widgets and text boxes.
  self.widgets = {}
  self.boxes = {}

  local x, y = pos.x, pos.y
  local max_x = x
  -- Title.
  if self.title_path then
    makeLabel(window, self.widgets, x, y, self.title_size, self.title_path)
    y = y + self.title_size.h + self.title_sep
    max_x = math.max(max_x, x + self.title_size.w)
  end
  -- Editable values below the title.
  local label_x = x
  local val_x = label_x + self.label_size.w
  local unit_x = val_x + self.value_size.w
  local right_x = unit_x + self.unit_size.w
  max_x = math.max(max_x, right_x)
  for idx, val in ipairs(self.values) do
    if idx > 1 then y = y + self.value_sep end
    makeLabel(window, self.widgets, label_x, y, self.label_size, val.name_path, val.tooltip_path)
    makeTextBox(window, self.text_boxes, val_x, y, self.value_size)
    makeUnit(window, self.widgets, unit_x, y, self.unit_size, self.unit_path)
    y = y + self.label_size.h
  end
  self:verifySize(Size(max_x - pos.x, y - pos.y))
end

--! Function to compute the size of the area for this section.
--  It is highly recommended to verify the computed size against the real use
--  after layout by means of self.verifySize().
function ValueSection:computeSize()
  local w = 0
  if self.title_path then w = math.max(w, self.title_size.w) end
  w = math.max(w, self.label_size.w + self.value_size.w + self.unit_size.w)

  local h = 0
  if self.title_path then h = h + self.title_size.h + self.title_sep end
  h = h + #self.values * self.label_size.h
  h = h + (#self.values - 1) * self.value_sep

  return Size(w, h)
end
-- }}}
-- {{{ TableSection
class "TableSection" (Section)

---@type TableSection
local TableSection = _G["TableSection"]

--! Section that associates one or more values for each index in the domain.
--!param title_path (str) Language path to the title name string.
--!param values (array of ConfigValue), ConfigValue descriptions.
function TableSection:TableSection(title_path, values)
  Section.Section(self, title_path)
  self.values = values -- Array of row arrays.


  self.title_sep = 5
end

function TableSection:setTitleSep(sep)
  self.title_sep = sep
  return self
end

function TableSection:layout(window, pos)
  local x, y = pos.x, pos.y
  local max_x = x
  -- Title.
  if self.title_path then
    makeLabel(window, self.widgets, x, y, self.title_size, self.title_path)
    y = y + self.title_size.h + self.title_sep
    max_x = math.max(max_x, x + self.title_size.w)
  end

  self.col_headers = {}
  self.row_headers = {}
  XXX

end

-- }}}
-- {{{ EditPage (some screen area to display and modify level-config values).
class "EditPage"

--@type EditPage
local EditPage = _G["EditPage"]

--! A 'screen' with values that can be modified.
--!param name_path Path in _S with the name of the page.
--!param Values that can be edited in this screen.
function EditPage:EditPage(name_path, sections)
  self.name_path = name_path -- Can be nil
  self.sections = sections -- Array.

  self.window = nil -- Containing window.
  self.widgets = {} -- Widgets of the page.

  self.name_size = Size(100, 15)
  self.name_sep = 5
  self.section_sep = 5
end

function EditPage:setNameSize(sz)
  assert(class.type(sz) == "Size")
  self.name_size = sz
  return self
end

function EditPage:setNameSep(name_sep, section_sep)
  self.name_sep = name_sep
  self.section_sep = section_sep
  return self
end

function EditPage:computeSize()
  local w, h = 0, 0
  if self.name_path then
    w = math.max(w, self.name_size.w)
    h = h + self.name_size.h + self.name_sep
  end

  h = h + (#self.sections - 1) * self.section_sep
  for _, sec in ipairs(self.sections) do
    local sz = sec:computeSize()
    w = math.max(w, sz.w)
    h = h + sz.h
  end
  return Size(w, h)
end

--! Compute layout of the elements at the page.
--!param x Left edge of the area available for layout.
--!param y Top edge of the area available for layout.
--!param w Horizontal size of the area.
--!param h vertical size of the area.
function EditPage:layout(window, pos, size)
  -- Clear widgets.
  self.widgets = {}

  local x, y = pos.x, pos.y
  local right_x = x
  -- Name.
  if self.name_path then
    makeLabel(window, self.widgets, x, y, self.name_size, self.name_path)
    y = y + self.name_size.h + self.name_sep
    right_x = math.max(right_x, x + self.name_size.w)
  end
  for idx, sec in ipairs(self.sections) do
    if idx > 1 then y = y + self.section_sep end
    sec:layout(window, Pos(x, y))
    local sz = sec:computeSize()
    y = y + sz.h
    right_x = math.max(right_x, x + sz.w)
  end
  -- XXX self:verifySize(Size(right_x - pos.x, y - pos.y)) not needed?
end
-- }}}

class "LevelEditorValues"


---@type LevelEditorValues
local LevelEditorValues = _G["LevelEditorValues"]

--! Get the language string associated with the given path.
--!param path (str) Name of the string to retrieve.
--!return The found string or a stub text.
function LevelEditorValues.getLanguageText(path)
  local text = _S
  local index = 1
  while text and index <= #path do
    local j = path:find(".", index, true)
    local name = path:sub(index, j)
    index = j + 1
    if #name > 2 and name:sub(1, 1) == "[" and name:sub(-1, -1) == "]" then
      text = text[tonumber(name:sub(2, -2))]
    else
      text = text[name]
    end
  end
  return text and text or "???"
end

function LevelEditorValues.getRootPage()
  local min_salary_section = ValueSection(lang_prefix .. ".titles.min_salaries_title", min_salary_values)
  min_salary_section:setTitleSize(Size(220, 20))
  min_salary_section:setLabelSize(Size(140, 20))
  min_salary_section:setValueSize(Size(50, 20))

  local towns_section = TableSection(lang_prefix .. ".titles.towns_title", towns)

  local salariesPage = EditPage("level_editor.pages.staffpage", {min_salary_section, towns_section})
  salariesPage:setNameSize(Size(250, 30))
  return salariesPage
--  return EditPage(nil, {min_salary_section, doctor_salaries_section, towns_section})
end
