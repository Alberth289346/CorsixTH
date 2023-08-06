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

local TEXT_BG = {red = 20, green = 150, blue = 200}
local TEXT_FG = {red = 20, green = 20, blue = 20}
local PANEL_BG = {red = 130, green = 70, blue= 43}
local PANEL_FG = {red= 80, green = 170, blue = 100}

--! Get a translated string by name.
--!param name (str) Name of the translated string to get.
--!return (utf-8 text) The retrieved translated string.
local function getTranslatedText(name)
  local text = TreeAccess.readTree(_S, name)
  if text then return text end -- Likely never fails due to _S implementation.

  print("Warning: Translated text named \"" .. name .. "\" does not exist.")
  return name
end

--===================================================================

--! A nummeric value to be edited.
class "LevelValue"

--@type LevelValue
local LevelValue = _G["LevelValue"]

--! Integer level configuration value in the level config editor.
--!param level_cfg_path (str) Absolute path in the level configuration file for
--    this value.
--!param name_path (str) Absolute path to the name string in the language files
--    for this value. XXX shuold allow nil for table values.
--!param tooltip_path (nil or str) If present, absolute path to the tooltip
--    string in the language files for this value.
--!param unit_path (nil or str) If present, the absolute path to the name string
--    of the unit for this value.
--!param min_value (nil or integer) If present the lowest allowed value of this
--    value.
--!param max_value (nil or integer) If present the highest allowed value of this
--    value.
function LevelValue:LevelValue(level_cfg_path, name_path, tooltip_path,
    unit_path, min_value, max_value)
  self.level_cfg_path = level_cfg_path
  self.name_path = name_path
  self.tooltip_path = tooltip_path
  self.unit_path = unit_path
  self.min_value = min_value
  self.max_value = max_value
  assert(not self.min_value or not self.max_value or self.min_value <= self.max_value)

  self._text_box = nil -- Text box in the editor.
  self.current_value = nil -- Current value.
end

--! Load the value from the level config file or write the value into a *new* level
--  config file.
--!param cfg (nested tables with values) Level config file to read or create.
--!param store (bool) If, write the value to a new spot in the level config, else
--  read the value and update the current value.
function LevelValue:loadSaveConfig(cfg, store)
  if store then
    -- Save the value to the configuration.
    TreeAccess.addTree(cfg, self.level_cfg_path, self.current_value)
    return
    -- XXX Needs load as well!
  end

  -- Retrieve the value from the configuration and update this element.
  local number = TreeAccess.readTree(cfg, self.level_cfg_path)
  self:setBoxValue(number)
  if TheApp.config.debug and not number then
    -- Warn developers about non-existing entries in the loaded file.
    print("Warning: Level configuration \"" .. self.level_cfg_path ..
        "\" does not exist in the file.")
  end
end

--! Set the value of the setting to the supplied value or to a default value.
--!param value (optional integer) Value to use if supplied.
function LevelValue:setBoxValue(value)
  if not value then value = self.current_value end

  if type(value) ~= "number" then value = 0 end
  if self.min_value and value < self.min_value then value = self.min_value end
  if self.max_value and value > self.max_value then value = self.max_value end
  self.current_value = math.floor(value) -- Ensure it's an integer even if the bounds are not.

  if self._text_box then -- Avoid a crash when updated without having a text box.
    self._text_box:setText(tostring(self.current_value))
  end
end

--! Callback that the user confirmed entering a new value. Apply it.
function LevelValue:confirm()
  self.current_value = tonumber(self._text_box.text) or self.current_value
  self:setBoxValue()
end

--! Callback that the user aborted editing, revert to the last stored value.
function LevelValue:abort()
  self:setBoxValue()
end

--! Make a bevel for some text.
--!param window Window to attach the panel to.
--!param widgets (Array of Panel) Storage for created panels. Appended in-place.
--!param x (int) X position of the top-left corner.
--!param y (int) Y position of the top-left corner.
--!param size (Size) Width and height of the panel.
--!param name_path (string) String path for the text to display.
--!param tooltip_path (string) String path for the tooltip to show.
local function makeLabel(window, widgets, x, y, size, name_path, tooltip_path)
  local panel = window:addBevelPanel(x, y, size.w, size.h, PANEL_BG, PANEL_FG)
  if name_path then
    panel:setLabel(getTranslatedText(name_path), nil, "left")
    if tooltip_path then
      panel:setTooltip(getTranslatedText(tooltip_path))
    end
  end
  widgets[#widgets + 1] = panel
  return panel
end

--! Make a textbox for entering a number.
--!param window Window to attach the panel to.
--!param widgets (Array of Panel) Storage for created text boxes. Appended in-place.
--!param text_boxes (array of text boxes) Storage for created text boxes, appended in-place.
--!param x (int) X position of the top-left corner.
--!param y (int) Y position of the top-left corner.
--!param size (Size) Width and height of the panel.
--!param value (LevelValue) Value displayed and edited in the box.
local function makeTextBox(window, text_boxes, x, y, size, value)
  local text_box = window:addBevelPanel(x, y, size.w, size.h, TEXT_BG, TEXT_FG)
  local function confirm_cb() value:confirm() end
  local function abort_cb() value:abort() end
  text_box = text_box:makeTextbox(confirm_cb, abort_cb) -- confirm_cb, abort_cb)
  text_boxes[#text_boxes + 1] = text_box

  value.text_box = text_box
  value:setBoxValue()
end

--! Add a panel to display the unit of a value if it has been supplied.
--!param window Window to attach the panel to.
--!param widgets (Array of Panel) Storage for created text boxes. Appended in-place.
--!param x (int) X position of the top-left corner.
--!param y (int) Y position of the top-left corner.
--!param size (Size) Width and height of the panel.
--!param unit_path Name of the string in the translations that contains the unit of the value.
local function makeUnit(window, widgets, x, y, size, unit_path)
  if not unit_path then return end

  local panel = window:addBevelPanel(x, y, size.w, size.h, PANEL_BG, PANEL_FG)
  panel:setLabel(getTranslatedText(unit_path))
  widgets[#widgets + 1] = panel
end

--! Make a button for the tab page.
--!param window Window to attach the panel to.
--!param widgets (Array of Panel) Storage for created buttons. Appended in-place.
--!param x (int) X position of the top-left corner.
--!param y (int) Y position of the top-left corner.
--!param size (Size) Width and height of the panel.
--!param callback Function to call when clicked.
--!param text_path Name of the translated string to display at the button.
local function makeButton(window, widgets, x, y, size, callback, text_path)
  local panel = window:addBevelPanel(x, y, size.w, size.h, PANEL_BG, PANEL_FG)
  local button = panel:makeButton(0, 0, size.w, size.h, nil, callback, nil, nil)
  button.panel_lowered_active = false
  if text_path then button:setLabel(getTranslatedText(text_path)) end
  widgets[#widgets + 1] = button
end

-- ===================================================================

--! Common base class for editable area in the level editor.
class "LevelSection"

--@type LevelSection
local LevelSection = _G["LevelSection"]

--! Base class for editing a group of values.
--!param title_path (str) Language path to the title name string.
function LevelSection:LevelSection(title_path)
  self.title_path = title_path -- Displayed name of the section.
  self._widgets = {} -- Widgets of the section.
  self._text_boxes = {} -- Text boxes of the section.

  self.title_size = Size(100, 25)
end

--! Set visibility of the widgets to the value of the parameter.
--!param (bool) Whether the widgets and/or text boxes should be visible.
function LevelSection:setVisible(is_vsisible)
  for _, widget in ipairs(self._widgets) do
    widget:setVisible(is_vsisible)
  end
  for _, box in ipairs(self._text_boxes) do
    box:setVisible(is_vsisible)
  end
end

--! Configure the size of the title area.
--!param sz Desired size of the title area.
function LevelSection:setTitleSize(sz)
  self.title_size = sz
  return self
end

--! Verify that actual layout size matches with computed size.
--!param sz (Size) Size after performing actual layout.
function LevelSection:verifySize(sz)
  local exp_sz = self:computeSize()
  assert(sz.w == exp_sz.w and sz.h == exp_sz.h, ("Wrong size: expected "
      .. "(" .. exp_sz.w .. ", " .. exp_sz.h .. "), got "
      .. "(" .. sz.w .. ", " .. sz.h .. ")"))
end

--! Construct the elements displayed at the window.
--!param window (Window) Window to add the new widgets.
--!param pos (Pos) Position of the to-left corner.
function LevelSection:layout(window, pos)
  assert(false, "Implement me in " .. class.type(self))
  -- Track size of the created layout (for example from 'pos' to the
  -- bottom-right corner), and verify it with LevelSection:verifySize.
end

--! Compute size of the needed area to display the section.
--!return (Size) Size of the section area.
function LevelSection:computeSize()
  assert(false, "Implement me in " .. class.type(self))
end

-- ===================================================================

--! Section with one or more related values.
class "LevelValuesSection" (LevelSection)

--@type LevelValuesSection
local LevelValuesSection = _G["LevelValuesSection"]

--! Section with one or more related values.
--!param title_path (str) Language path to the title name string.
--!param values (array of LevelValue), values descriptions.
function LevelValuesSection:LevelValuesSection(title_path, values)
  LevelSection.LevelSection(self, title_path)
  self.values = values -- Array.

  self.label_size = Size(100, 20)
  self.value_size = Size(30, 20)
  self.unit_size = Size(20, 20)
  self.title_sep = 10
  self.value_sep = 2 -- Vertical separator between values.
  self.label_sep = 2 -- Horizontal space after label.
end

--! Set the size of the "label" text box of each value in the section.
--!param sz (Size) Desired size of each the label area of each value.
function LevelValuesSection:setLabelSize(sz)
  assert(class.type(sz) == "Size")
  self.label_size = sz
  return self
end

--! Set the size of the "value" text box of each value in the section.
--!param sz (Size) Desired size of each the value text-box of each value.
function LevelValuesSection:setValueSize(sz)
  assert(class.type(sz) == "Size")
  self.value_size = sz
  return self
end

--! Set the size of the "unit" area of each value in the section.
--!param sz (Size) Desired size of each unit area.
function LevelValuesSection:setUnitSize(sz)
  assert(class.type(sz) == "Size")
  self.unit_size = sz
  return self
end

--! Configure vertical spacing.
--!param title_sep (int) Vertical empty space between the title box and the values.
--!param value_sep (int) Vertical empty space between two adjacent values in the section.
function LevelValuesSection:setVertSep(title_sep, value_sep)
  assert(type(title_sep, "number"))
  assert(type(value_sep, "number"))
  self.title_sep = title_sep
  self.value_sep = value_sep
  return self
end

--! Construct widgets in the window, with the top-left corner of the section at pos.
--!param window Window to add the new widgets.
--!param pos Top-left position of the area.
function LevelValuesSection:layout(window, pos)
  -- Clear widgets and text boxes.
  self._widgets = {}
  self._text_boxes = {}

  local x, y = pos.x, pos.y
  local max_x = x
  -- Title.
  if self.title_path then
    makeLabel(window, self._widgets, x, y, self.title_size, self.title_path)
    y = y + self.title_size.h + self.title_sep
    max_x = math.max(max_x, x + self.title_size.w)
  end
  -- Editable values below the title.
  local label_x = x
  local val_x = label_x + self.label_size.w + self.value_sep
  local unit_x = val_x + self.value_size.w
  local right_x = unit_x + self.unit_size.w
  max_x = math.max(max_x, right_x)
  for idx, val in ipairs(self.values) do
    if idx > 1 then y = y + self.value_sep end
    makeLabel(window, self._widgets, label_x, y, self.label_size, val.name_path, val.tooltip_path)
    makeTextBox(window, self._text_boxes, val_x, y, self.value_size, val)
    makeUnit(window, self._widgets, unit_x, y, self.unit_size, self.unit_path)
    y = y + self.label_size.h
  end
  self:verifySize(Size(max_x - pos.x, y - pos.y))
  self:setVisible(false) -- Initially hide all LevelSections.
end

--! Inherited function computing the size of the section without constructing widgets.
function LevelValuesSection:computeSize()
  local w = 0
  if self.title_path then w = math.max(w, self.title_size.w) end
  w = math.max(w, self.label_size.w + self.value_sep + self.value_size.w + self.unit_size.w)

  local h = 0
  if self.title_path then h = h + self.title_size.h + self.title_sep end
  h = h + #self.values * self.label_size.h
  h = h + (#self.values - 1) * self.value_sep

  return Size(w, h)
end

--! Load the values from the level config or write the values into a *new*
--  level config.
--!param cfg (nested tables with values) Level config file to read or create.
--!param store (bool) If set, write the value to a new spot in the level config,
--  else read the value and update the current value.
function LevelValuesSection:loadSaveConfig(cfg, store)
  for _, val in ipairs(self.values) do val:loadSaveConfig(cfg, store) end
end

-- ===================================================================

--! Section with a 2D table of editable values.
class "LevelTableSection" (LevelSection)

---@type LevelTableSection
local LevelTableSection = _G["LevelTableSection"]

--! Section that associates one or more values for each index in a domain.
--!param title_path (str) Language path to the title name string.
--!param row_name_paths String names for row labels.
--!param row_tooltip_paths String names for row label tooltips.
--!param col_name_paths String names for column labels.
--!param col_tooltip_paths String names for column tooltips.
--!param values (array of column array of Value) Values in the table.
function LevelTableSection:LevelTableSection(title_path, row_name_paths,
    row_tooltip_paths, col_name_paths, col_tooltip_paths, values)
  LevelSection.LevelSection(self, title_path)
  self.row_name_paths = row_name_paths or {}
  self.row_tooltip_paths = row_tooltip_paths or {}
  self.col_name_paths = col_name_paths or {}
  self.col_tooltip_paths = col_tooltip_paths or {}
  self.values = values -- Array of column arrays.

  assert(values)

  local table_rows_cols = self:_getTableColsRows()
  -- Verify dimensions (hor, vert).
  assert(#row_name_paths == table_rows_cols.h,
      "Unequal number of rows: names = " .. #row_name_paths
      .. ", values height = " .. table_rows_cols.h)
  assert(#col_name_paths == table_rows_cols.w,
      "Unequal number of columns: names = " .. #col_name_paths
      .. ", values width = " .. table_rows_cols.w)

  for i, c in ipairs(values) do
    assert(#c == table_rows_cols.h,
        "Column " .. i .. ": count=" .. #c .. ", height=" .. table_rows_cols.h)
  end

  self.title_height = 20 -- Amount of vertical space for the title.
  self.title_sep = 10 -- Amount of vertical space between the title and the column names,
  self.row_label_sep = 10 -- Amount of vertical space between the column names and the first row.
  self.col_label_sep = 10 -- Amount of horizontal space between the row names and the first column.
  self.col_width = 100 -- Width of a column values (also sets the column label).
  self.row_height = 20 -- Height of a row values (also sets the row label).
  self.intercol_sep = 5 -- Horizontal space between two columns in the table.
  self.interrow_sep = 2 -- Vertical space between two rows in the table.
end

--! Get the number of rows and columns of the table.
--!return (Size) Number of columns, number of rows.
function LevelTableSection:_getTableColsRows()
  -- 'values' has column arrays.
  local num_cols = #self.values
  local num_rows = #self.values[1]
  return Size(num_cols, num_rows)
end

--! Set the amount of vertical space between the title and the column labels.
--!param sep (int) Vertical space between the title and the column labels.
function LevelTableSection:setTitleSep(sep)
  self.title_sep = sep
  return self
end

--! Construct widgets in the window for displaying and editing values in the table.
--!param window (Window) Window to add the new widgets.
--!param pos (Pos) Position of the to-left corner.
function LevelTableSection:layout(window, pos)
  self._widgets = {}
  self._text_boxes = {}

  local x, y = pos.x, pos.y
  local max_x = x
  -- Title.
  if self.title_path then
    makeLabel(window, self._widgets, x, y, self.title_size, self.title_path)
    y = y + self.title_size.h + self.title_sep
    max_x = math.max(max_x, x + self.title_size.w)
  end

  local table_rows_cols = self:_getTableColsRows()

  -- Column headers
  local label_size = Size(self.col_width, self.row_height)
  x = pos.x + self.col_width + self.col_label_sep -- Skip space for the row labels
  for col = 1, table_rows_cols.w do
    makeLabel(window, self._widgets, x, y, label_size, self.col_name_paths[col],
        self.col_tooltip_paths[col])
    x = x + label_size.w
    if col < table_rows_cols.w then x = x + self.intercol_sep end
  end
  max_x = math.max(max_x, x)
  y = y + self.row_height + self.row_label_sep

  -- Rows
  for row = 1, table_rows_cols.h do
    x = pos.x
    makeLabel(window, self._widgets, x, y, label_size, self.row_name_paths[row], self.row_tooltip_paths[row])
    x = x + label_size.w + self.col_label_sep
    for col = 1, table_rows_cols.w do
      makeTextBox(window, self._text_boxes, x, y, label_size, self.values[col][row])
      x = x + label_size.w
      if col < table_rows_cols.w then x = x + self.intercol_sep end
    end
    max_x = math.max(max_x, x)
    y = y + self.row_height
    if row < table_rows_cols.h then y = y + self.interrow_sep end
  end

  self:verifySize(Size(max_x - pos.x, y - pos.y))
  self:setVisible(false) -- Initially hide all LevelSections.
end

--! Inherited function computing the size of the section without constructing widgets.
function LevelTableSection:computeSize()
  local table_rows_cols = self:_getTableColsRows()

  -- Horizontal size.
  local hor_size = self.col_width + self.col_label_sep + self.col_width
  hor_size = hor_size + (table_rows_cols.w - 1) * (self.intercol_sep + self.col_width)
  if self.title_path then hor_size = math.max(hor_size, self.title_size.w) end

  -- Vertical size.
  local vert_size = self.title_path and (self.title_size.h + self.title_sep) or 0
  vert_size = vert_size + self.row_height + self.row_label_sep + self.row_height
  vert_size = vert_size + (table_rows_cols.h - 1) * (self.interrow_sep + self.row_height)
  return Size(hor_size, vert_size)
end

--! Load the values from the level config or write the values into a *new*
--  level config.
--!param cfg (nested tables with values) Level config file to read or create.
--!param store (bool) If set, write the value to a new spot in the level config,
--  else read the value and update the current value.
function LevelTableSection:loadSaveConfig(cfg, store)
  for _, vals_col in ipairs(self.values) do
    for _, val in ipairs(vals_col) do val:loadSaveConfig(cfg, store) end
  end
end

-- ===================================================================

--! A "page" at the screen for editing level configuration values.
class "LevelPage"
local LevelPage = _G["LevelPage"]

-- Abstract base class.
function LevelPage:LevelPage()
  self._widgets = {}
end

--! Load the values from the level config or write the values into a *new*
--  level config.
--!param cfg (nested tables with values) Level config file to read or create.
--!param store (bool) If set, write the value to a new spot in the level config,
--  else read the value and update the current value.
function LevelPage:loadSaveConfig(cfg, store)
  error("Implement me in " .. class.type(self))
end

--! Set visibility of the widgets to the value of the parameter.
--!param (bool) Whether the widgets and/or text boxes should be visible.
function LevelPage:setVisible(is_vsisible)
  error("Implement me in " .. class.type(self))
end

-- ===================================================================

--! A "screen" with displayed sections that can be edited.
class "LevelEditPage" (LevelPage)

--@type LevelEditPage
local LevelEditPage = _G["LevelEditPage"]

--! A 'screen' with values that can be modified.
--!param name_path Path in _S with the name of the page.
--!param sections (array of LevelSection) Sections of settings that can be
--    edited in this screen.
function LevelEditPage:LevelEditPage(title_path, name_path, sections)
  LevelPage.LevelPage(self)

  assert(name_path) -- Needed by a tab page.

  self.name_path = name_path -- Name of the page in a tab of a tab-page.
  self.title_path = title_path -- title of the edit page, may be nil.
  self.sections = sections -- Array of sections displayed at the page.

  self._widgets = {} -- Widgets of the page.

  self.title_size = Size(100, 15)
  self.title_sep = 5
  self.section_sep = 5 -- Space between sections in a column.
  self.column_sep = 5 -- Space between 'columns'.
end

--! Set visibility of the widgets to the value of the parameter.
--!param (bool) Whether the widgets and/or text boxes should be visible.
function LevelEditPage:setVisible(is_vsisible)
  for _, widget in ipairs(self._widgets) do
    widget:setVisible(is_vsisible)
  end
  for _, section in ipairs(self.sections) do
    section:setVisible(is_vsisible)
  end
end

--! Set the size of the title name at the page.
--!param sz (Size) Desired size of the title area.
function LevelEditPage:setTitleSize(sz)
  assert(class.type(sz) == "Size")
  self.title_size = sz
  return self
end

--! Configure vertical space between the title of the page and the first
--  section as well as vertical space between two sections.
function LevelEditPage:setTitleSep(title_sep, section_sep)
  if title_sep then self.title_sep = title_sep end
  if section_sep then self.section_sep = section_sep end
  return self
end

-- Empty space between placed sections.
local SECT_VERT_SPACE = 30
local SECT_HOR_SPACE = 20

--! Compute placemen of a section with a given size inside a given rectangle, where
--! the top-left area of the rectangle is already used.
--!param sect_size (Size) Size of the new section to add in the rectangle.
--!param rect_pos (Pos) Top-left position of the rectangle to place the section in.
--!param rect_size (Size) Size of the rectangle to place the section in.
--!return (sect_pos, rect_pos, rect_size, used_size) or nil.
local function computePlacement(sect_size, rect_pos, rect_size, used_size)
  if sect_size.h > sect_size.h then return nil end -- Too high to ever fit.

  local delta
  while true do
    if sect_size.w >= rect_size.w then return nil end -- Too wide to ever fit.

    -- Does it fit below the current used area?
    if rect_size.h - used_size.h >= sect_size.h then
      local sect_pos = Pos(rect_pos.x, rect_pos.y + used_size.h)
      local new_used_w = math.max(used_size.w, sect_size.w)
      local new_used_h = math.min(used_size.h + sect_size.h + SECT_VERT_SPACE, rect_size.h)
      return {
        sect_pos = sect_pos,
        rect_pos = rect_pos,
        rect_size = rect_size,
        used_size = Size(new_used_w, new_used_h)
      }
    end

    -- Too long to fit, try at the right of the used area.
    delta = used_size.w + SECT_HOR_SPACE
    rect_pos = Pos(rect_pos.x + delta, rect_pos.y)
    rect_size = Size(rect_size.w - delta, rect_size.h)
    used_size = Size(0, 0)

    -- Note that this loop terminates. If the remaining space is too narrow it
    -- will bail out in the next check. Otherwise, as the section is not too high
    -- and the vertical size of the rectangle is now fully available, the section
    -- will fit otherwise.
  end
end

--! Compute layout of the elements at the page.
--!param window Window to add the new widgets.
--!param pos (Pos) Position of the to-left corner.
--!param size (Size) Size if the page.
function LevelEditPage:layout(window, pos, size)
  self._widgets = {}

  local section_top = pos.y

  -- Name.
  if self.title_path then
    makeLabel(window, self._widgets, pos.x, section_top, self.title_size, self.title_path)
    section_top = section_top + self.title_size.h + self.title_sep
  end

  local rect_pos = Pos(pos.x, section_top)
  local rect_size = Size(size.w, math.max(0, size.h - section_top - pos.y))
  local used_size = Size(0, 0)

  local placed_sections = {}
  for _, section in ipairs(self.sections) do -- For each 'column of sections' do
    local sect_size = section:computeSize()
    local placement = computePlacement(sect_size, rect_pos, rect_size, used_size)
    if placement then
      local sect_pos = placement.sect_pos
      rect_pos = placement.rect_pos
      rect_size = placement.rect_size
      used_size = placement.used_size
      section:layout(window, sect_pos)
      placed_sections[#placed_sections + 1] = section
    else
      print("Section dropped (too big!!)")
    end
  end
  self.sections = placed_sections -- Discard dropped sections
  self:setVisible(false) -- Hide the level edit page initially.
end

--! Load the value from the level config or write the value into a *new* level
--  config file.
--!param cfg (nested tables with values) Level config file to read or create.
--!param store (bool) If, write the value to a new spot in the level config, else
--  read the value and update the current value.
function LevelEditPage:loadSaveConfig(cfg, store)
  for _, sect in ipairs(self.sections) do sect:loadSaveConfig(cfg, store) end
end

-- ===================================================================

--! Class with one or more level edit pages.
class "LevelTabPage" (LevelPage)

--@type LevelTabPage
local LevelTabPage = _G["LevelTabPage"]

function LevelTabPage:LevelTabPage(title_path, level_pages)
  LevelPage.LevelPage(self)

  self.title_path = title_path -- Name in the translation for the title of the tab page.
  self._level_pages = level_pages -- Array of LevelPage.
  self._selected_page = nil -- Index of selected page in level_pages.

  self.title_size = Size(100, 25)
  self.title_sep = 10 -- Amount of vertical space between the title and page tabs.
  self.page_tab_size = Size(80, 25) -- Size of a tab with a edit page name
  self.edit_sep = 10 -- Amount of vertical space between the page tabs and the edit pages.
end

--! Compute layout of the elements at the page.
--!param window Window to add the new widgets.
--!param pos (Pos) Position of the to-left corner.
--!param size (Size) Size if the page.
function LevelTabPage:layout(window, pos, size)
  local x, y = pos.x, pos.y
  -- Add title.
  if self.title_path then
    makeLabel(window, self._widgets, x, y, self.title_size, self.title_path)
    y = y + self.title_size.h + self.title_sep
  end
  -- Add edit-page tabs.
  local xpos = pos.x -- Left position of a tab button.
  local remaining_width = size.w
  for i, level_page in ipairs(self._level_pages) do
    if self.page_tab_size.w > remaining_width then -- Row is full.
      xpos = pos.x
      remaining_width = size.w
      y = y + self.page_tab_size.h
    end
    local callback =  --[[persistable:LevelTabPage_onClickTab]] function() self:onClickTab(i) end
    makeButton(window, self._widgets, xpos, y, self.page_tab_size, callback, level_page.name_path)
    xpos = xpos + self.page_tab_size.w
    remaining_width = remaining_width - self.page_tab_size.w
  end
  y = y + self.page_tab_size.h + self.edit_sep -- First row + empty space below the rows.

  -- Add edit pages.
  for _, level_page in ipairs(self._level_pages) do
    level_page:layout(window, Pos(pos.x, y), Size(size.w, size.h - (y - pos.y)))
  end
end

-- User selected a page to display.
--!param page_num Selected page.
function LevelTabPage:onClickTab(page_num)
  if page_num ~= self._selected_page then
    if page_num >= 1 and page_num <= #self._level_pages then
      if self._selected_page then -- Hide previous selection, first time there is none.
        self._level_pages[self._selected_page]:setVisible(false)
      end
      self._selected_page = page_num -- And select/show new selection.
      self._level_pages[self._selected_page]:setVisible(true)
    end
  end
end

function LevelTabPage:loadSaveConfig(cfg, store)
  for _, page in ipairs(self._level_pages) do
    page:loadSaveConfig(cfg, store)
  end
end
