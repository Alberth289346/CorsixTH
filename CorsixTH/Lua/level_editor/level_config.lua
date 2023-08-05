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

corsixth.require("level_editor.data_storage")

--! Construct a language string name if path_value is set.
--!param path_value (nil, true, or string) If true a name is constructed, else
--  if set the string name itself.
--!param prefix (str) The prefix before the level configuration path to make the
--  name unique,
--!param level_cfg_path (str) The path in the level configuration file.
--!return (nil or string) The Name of the string in the language file if set.
local function _make_path(path_value, prefic, level_cfg_path)
  if path_value then
    if path_value == true then
      return "level_editor." .. prefic .. "." .. level_cfg_path
    else
      return path_value
    end
  end
  return nil
end

--! Construct a LevelValue instance (an elementary editable numeric value).
--!param settings (table) Settings for the instance.
--!return (LevelValue) The constructed level value.
local function makeValue(settings)
  -- settings fields:
  --  * "level_cfg_path" Obligatory path in the level configuration.
  --  * "name_path" The path of the name string in the language file or "true"
  --    to construct a name string from the level_cfg_path.
  --  * "tooltip_path" The path of the tooltip string in the language file or
  --    "true" to construct a tooltip string from the level_cfg_path.
  --  * "unit_path" The path of the unit string in the language file or "true"
  --    to construct unit string from the level_cfg_path.
  --  * "min_value" If set, the smallest value that is allowed.
  --  * "max_value" If set, the largest value that is allowed.
  local name_path = _make_path(settings.name_path, "name", settings.level_cfg_path)
  local tooltip_path = _make_path(settings.tooltip_path, "tooltip", settings.level_cfg_path)
  local unit_path = _make_path(settings.unit_path, "unit", settings.level_cfg_path)
  return LevelValue(settings.level_cfg_path, name_path, tooltip_path, unit_path,
      settings.min_value, settings.max_value)
end

--! Construct a LevelValueSection instance.
--!param settings (table) Settings for the instance.
--!return (LevelValueSection) The constructed instance.
local function makeValuesSection(settings)
  -- settings fields:
  --  * "title_path" (string) Language string with the title of the section.
  --  * "label_size" (Size) Optional size of the value name part.
  --  * "value_size" (Size) Optional size of the numeric value part.
  --  * "unit_size" (Size) Optional size of the unit name part.
  local section = LevelValuesSection(settings.title_path, settings)
  if settings.label_size then section.setLabelSize(settings.label_size) end
  if settings.value_size then section.setvalueSize(settings.value_size) end
  if settings.unit_size then section.setUnitSize(settings.unit_size) end
  return section
end

local function makeTableSection(settings)
  local row_names = settings.row_names
  local col_names = settings.col_names
  local col_values = settings.col_values
  local section = LevelTableSection(settings.title_path, row_names, nil, col_names, nil, col_values)
  if settings.title_height then section.title_height = settings.title_height end
  if settings.title_sep then section.title_sep = settings.title_sep end
  if settings.row_label_sep then section.row_label_sep = settings.row_label_sep end
  if settings.col_label_sep then section.col_label_sep = settings.col_label_sep end
  if settings.col_width then section.col_width = settings.col_width end
  if settings.row_height then section.row_height = settings.row_height end
  if settings.intercol_sep then section.intercol_sep = settings.intercol_sep end
  if settings.interrow_sep then section.interrow_sep = settings.interrow_sep end
  return section
end

local function makeEditPageSection(settings)
  local section = LevelEditPage(settings.name_path, settings)
  if settings.name_size then section:setNameSize(settings.name_size) end
  section:setNameSep(settings.name_sep, settings.section_sep)
  return section
end

local function makeTabPageSection(settings)
  local section = LevelTabPage(settings.name_path, settings)
  if settings.title_size then section.title_size = settings.title_size end
  if settings.title_sep then section.title_sep = settings.title_sep end
  if settings.page_tab_size then section.page_tab_size = settings.page_tab_size end
  if settings.edit_sep then section.edit_sep = settings.edit_sep end
  return section
end

-- TODO Not all settings above are documented, have a function, do parameter checking.
-- TODO Not for every setting it makes sense to use a number.

-- TODO No all data below is used, is ordered on topic, or useful.
-- TODO Some sections should be extendable with more rows.


-- ===============================================================
-- Level config data.

local town_values = makeValuesSection({
  title_path = "level_editor.town_section.title",
  -- label_size
  -- value_size
  -- unit_size
  -- TODO title_sep, value_sep
  makeValue({level_cfg_path = "town.InterestRate", name_path = true}),
  makeValue({level_cfg_path = "town.StartCash", name_path = true}),
  makeValue({level_cfg_path = "town.StartRep", name_path = true}),
  makeValue({level_cfg_path = "town.OverdraftDiff", name_path = true}),
})
--[[
local staff_min_salaries = makeValuesSection({
  title_path = "level_editor.staff_salaries_section.title",
  makeValue({level_cfg_path = "staff[0].MinSalary", name_path = true}),
  makeValue({level_cfg_path = "staff[1].MinSalary", name_path = true}),
  makeValue({level_cfg_path = "staff[2].MinSalary", name_path = true}),
  makeValue({level_cfg_path = "staff[3].MinSalary", name_path = true}),
  makeValue({level_cfg_path = "payroll.MaxSalary", name_path = true}),
})

local doctor_additional_salaries = makeValuesSection({
  title_path = "level_editor.additional_salaries_section.title",
  makeValue({level_cfg_path = "gbv.SalaryAdd[3]", name_path = true}),
  makeValue({level_cfg_path = "gbv.SalaryAdd[4]", name_path = true}),
  makeValue({level_cfg_path = "gbv.SalaryAdd[5]", name_path = true}),
  makeValue({level_cfg_path = "gbv.SalaryAdd[6]", name_path = true}),
  makeValue({level_cfg_path = "gbv.SalaryAdd[7]", name_path = true}),
  makeValue({level_cfg_path = "gbv.SalaryAdd[8]", name_path = true}),
})

local various_settings = makeValuesSection({
  title_path = "level_editor.various_settings.title",
  -- TODO Split this in a more sane way.
  makeValue({level_cfg_path = "gbv.SalaryAbilityDivisor", name_path = true}),
  makeValue({level_cfg_path = "gbv.ResearchPointsDivisor", name_path = true}),
  makeValue({level_cfg_path = "gbv.StartRating", name_path = true}),
  makeValue({level_cfg_path = "gbv.StartCost", name_path = true}),
  makeValue({level_cfg_path = "gbv.MinDrugCost", name_path = true}),
  makeValue({level_cfg_path = "gbv.HowContagious", name_path = true}),
  makeValue({level_cfg_path = "gbv.ContagiousSpreadFactor", name_path = true}),
  makeValue({level_cfg_path = "gbv.ReduceContMonths", name_path = true}),
  makeValue({level_cfg_path = "gbv.ReduceContPeepCount", name_path = true}),
  makeValue({level_cfg_path = "gbv.ReduceContRate", name_path = true}),
  makeValue({level_cfg_path = "gbv.HoldVisualMonths", name_path = true}),
  makeValue({level_cfg_path = "gbv.HoldVisualPeepCount", name_path = true}),
  makeValue({level_cfg_path = "gbv.MaxObjectStrength", name_path = true}),
  makeValue({level_cfg_path = "gbv.ResearchIncrement", name_path = true}),
  makeValue({level_cfg_path = "gbv.ScoreMaxInc", name_path = true}),
  makeValue({level_cfg_path = "gbv.VacCost", name_path = true}),
  makeValue({level_cfg_path = "gbv.EpidemicFine", name_path = true}),
  makeValue({level_cfg_path = "gbv.EpidemicCompLo", name_path = true}),
  makeValue({level_cfg_path = "gbv.EpidemicCompHi", name_path = true}),
  makeValue({level_cfg_path = "gbv.EpidemicRepLossMinimum", name_path = true}),
  makeValue({level_cfg_path = "gbv.EpidemicEvacMinimum", name_path = true}),
  makeValue({level_cfg_path = "gbv.EpidemicConcurrentLimit", name_path = true}),
  makeValue({level_cfg_path = "gbv.AutopsyRschPercent", name_path = true}),
  makeValue({level_cfg_path = "gbv.AutopsyRepHitPercent", name_path = true}),
  makeValue({level_cfg_path = "gbv.MayorLaunch", name_path = true}),
  makeValue({level_cfg_path = "gbv.TrainingRate", name_path = true}),
  makeValue({level_cfg_path = "gbv.DrugImproveRate", name_path = true}),
  makeValue({level_cfg_path = "gbv.AllocDelay", name_path = true})
})

local trainings_settings = makeValuesSection({
  title_path = "level_editor.training_settings.title",
  makeValue({level_cfg_path = "gbv.AbilityThreshold[0]", name_path = true}),
  makeValue({level_cfg_path = "gbv.AbilityThreshold[1]", name_path = true}),
  makeValue({level_cfg_path = "gbv.AbilityThreshold[2]", name_path = true}),
  makeValue({level_cfg_path = "gbv.TrainingValue[0]", name_path = true}),
  makeValue({level_cfg_path = "gbv.TrainingValue[1]", name_path = true}),
  makeValue({level_cfg_path = "gbv.TrainingValue[2]", name_path = true}),
  makeValue({level_cfg_path = "gbv.DoctorThreshold", name_path = true}),
  makeValue({level_cfg_path = "gbv.ConsultantThreshold", name_path = true}),
  makeValue({level_cfg_path = "gbv.RschImproveCostPercent", name_path = true}),
  makeValue({level_cfg_path = "gbv.RschImproveIncrementPercent", name_path = true})
})

local towns_col1 = {
  makeValue({level_cfg_path = "gbv.towns[0].StartCash"}),
  makeValue({level_cfg_path = "gbv.towns[1].StartCash"}),
  makeValue({level_cfg_path = "gbv.towns[2].StartCash"}),
  makeValue({level_cfg_path = "gbv.towns[3].StartCash"}),
  makeValue({level_cfg_path = "gbv.towns[4].StartCash"}),
  makeValue({level_cfg_path = "gbv.towns[5].StartCash"}),
  makeValue({level_cfg_path = "gbv.towns[6].StartCash"}),
  makeValue({level_cfg_path = "gbv.towns[7].StartCash"}),
  makeValue({level_cfg_path = "gbv.towns[8].StartCash"}),
  makeValue({level_cfg_path = "gbv.towns[9].StartCash"}),
  makeValue({level_cfg_path = "gbv.towns[10].StartCash"}),
  makeValue({level_cfg_path = "gbv.towns[11].StartCash"}),
  makeValue({level_cfg_path = "gbv.towns[12].StartCash"}),
}
local towns_col2 = {
  makeValue({level_cfg_path = "gbv.towns[0].InterestRate"}),
  makeValue({level_cfg_path = "gbv.towns[1].InterestRate"}),
  makeValue({level_cfg_path = "gbv.towns[2].InterestRate"}),
  makeValue({level_cfg_path = "gbv.towns[3].InterestRate"}),
  makeValue({level_cfg_path = "gbv.towns[4].InterestRate"}),
  makeValue({level_cfg_path = "gbv.towns[5].InterestRate"}),
  makeValue({level_cfg_path = "gbv.towns[6].InterestRate"}),
  makeValue({level_cfg_path = "gbv.towns[7].InterestRate"}),
  makeValue({level_cfg_path = "gbv.towns[8].InterestRate"}),
  makeValue({level_cfg_path = "gbv.towns[9].InterestRate"}),
  makeValue({level_cfg_path = "gbv.towns[10].InterestRate"}),
  makeValue({level_cfg_path = "gbv.towns[11].InterestRate"}),
  makeValue({level_cfg_path = "gbv.towns[12].InterestRate"}),
}
local towns_col3 = {
  makeValue({level_cfg_path = "gbv.towns[0].StartRep"}),
  makeValue({level_cfg_path = "gbv.towns[1].StartRep"}),
  makeValue({level_cfg_path = "gbv.towns[2].StartRep"}),
  makeValue({level_cfg_path = "gbv.towns[3].StartRep"}),
  makeValue({level_cfg_path = "gbv.towns[4].StartRep"}),
  makeValue({level_cfg_path = "gbv.towns[5].StartRep"}),
  makeValue({level_cfg_path = "gbv.towns[6].StartRep"}),
  makeValue({level_cfg_path = "gbv.towns[7].StartRep"}),
  makeValue({level_cfg_path = "gbv.towns[8].StartRep"}),
  makeValue({level_cfg_path = "gbv.towns[9].StartRep"}),
  makeValue({level_cfg_path = "gbv.towns[10].StartRep"}),
  makeValue({level_cfg_path = "gbv.towns[11].StartRep"}),
  makeValue({level_cfg_path = "gbv.towns[12].StartRep"}),
}
local towns_col4 = {
  makeValue({level_cfg_path = "gbv.towns[0].OverdraftDiff"}),
  makeValue({level_cfg_path = "gbv.towns[1].OverdraftDiff"}),
  makeValue({level_cfg_path = "gbv.towns[2].OverdraftDiff"}),
  makeValue({level_cfg_path = "gbv.towns[3].OverdraftDiff"}),
  makeValue({level_cfg_path = "gbv.towns[4].OverdraftDiff"}),
  makeValue({level_cfg_path = "gbv.towns[5].OverdraftDiff"}),
  makeValue({level_cfg_path = "gbv.towns[6].OverdraftDiff"}),
  makeValue({level_cfg_path = "gbv.towns[7].OverdraftDiff"}),
  makeValue({level_cfg_path = "gbv.towns[8].OverdraftDiff"}),
  makeValue({level_cfg_path = "gbv.towns[9].OverdraftDiff"}),
  makeValue({level_cfg_path = "gbv.towns[10].OverdraftDiff"}),
  makeValue({level_cfg_path = "gbv.towns[11].OverdraftDiff"}),
  makeValue({level_cfg_path = "gbv.towns[12].OverdraftDiff"}),
}

local towns_row_names = {}
for i = 0, 12 do
  towns_row_names[#towns_row_names + 1] = "level_editor.row_names.gbv.towns[" .. i .. "]"
end
local towns_col_names = {
  "level_editor.col_names.gbv.towns.start_cash",
  "level_editor.col_names.gbv.towns.interest_rate",
  "level_editor.col_names.gbv.towns.start_rep",
  "level_editor.col_names.gbv.towns.overdraft_diff",
}
local towns_section = makeTableSection({
  title_path = "level_editor.gbv.towns.title",
  row_names = towns_row_names,
  col_values = {towns_col1, towns_col2, towns_col3, towns_col4},
  col_names = towns_col_names
})
--]]
local popn_col1 = {
  makeValue({level_cfg_path = "gbv.popn[0].Month"}),
  makeValue({level_cfg_path = "gbc.popn[1].Month"}),
  makeValue({level_cfg_path = "gbc.popn[2].Month"}),
}
local popn_col2 = {
  makeValue({level_cfg_path = "gbv.popn[0].Change"}),
  makeValue({level_cfg_path = "gbc.popn[1].Change"}),
  makeValue({level_cfg_path = "gbc.popn[2].Change"}),
}
local popn_row_names = {
  "level_editor.row_names.gbv.popn[0]",
  "level_editor.row_names.gbv.popn[1]",
  "level_editor.row_names.gbv.popn[2]",
}
local popn_col_names = {
  "level_editor.col_names.gbv.popn.month",
  "level_editor.col_names.gbv.popn.change",
}
local popn_sectiom = makeTableSection({
  title_path = "level_editor.gbv.popn.title",
  row_names = popn_row_names,
  col_values = {popn_col1, popn_col2},
  col_names = popn_col_names
})
--[[
local expertise_diseases_col1 = {
  makeValue({level_cfg_path = "expertise[2].StartPrice"}),
  makeValue({level_cfg_path = "expertise[3].StartPrice"}),
  makeValue({level_cfg_path = "expertise[4].StartPrice"}),
  makeValue({level_cfg_path = "expertise[5].StartPrice"}),
  makeValue({level_cfg_path = "expertise[6].StartPrice"}),
  makeValue({level_cfg_path = "expertise[7].StartPrice"}),
  makeValue({level_cfg_path = "expertise[8].StartPrice"}),
  makeValue({level_cfg_path = "expertise[9].StartPrice"}),
  makeValue({level_cfg_path = "expertise[10].StartPrice"}),
  makeValue({level_cfg_path = "expertise[11].StartPrice"}),
  makeValue({level_cfg_path = "expertise[12].StartPrice"}),
  makeValue({level_cfg_path = "expertise[13].StartPrice"}),
  makeValue({level_cfg_path = "expertise[14].StartPrice"}),
  makeValue({level_cfg_path = "expertise[15].StartPrice"}),
  makeValue({level_cfg_path = "expertise[16].StartPrice"}),
  makeValue({level_cfg_path = "expertise[17].StartPrice"}),
  makeValue({level_cfg_path = "expertise[18].StartPrice"}),
  makeValue({level_cfg_path = "expertise[19].StartPrice"}),
  makeValue({level_cfg_path = "expertise[20].StartPrice"}),
  makeValue({level_cfg_path = "expertise[21].StartPrice"}),
  makeValue({level_cfg_path = "expertise[22].StartPrice"}),
  makeValue({level_cfg_path = "expertise[23].StartPrice"}),
  makeValue({level_cfg_path = "expertise[24].StartPrice"}),
  makeValue({level_cfg_path = "expertise[25].StartPrice"}),
  makeValue({level_cfg_path = "expertise[26].StartPrice"}),
  makeValue({level_cfg_path = "expertise[27].StartPrice"}),
  makeValue({level_cfg_path = "expertise[28].StartPrice"}),
  makeValue({level_cfg_path = "expertise[29].StartPrice"}),
  makeValue({level_cfg_path = "expertise[30].StartPrice"}),
  makeValue({level_cfg_path = "expertise[31].StartPrice"}),
  makeValue({level_cfg_path = "expertise[32].StartPrice"}),
  makeValue({level_cfg_path = "expertise[33].StartPrice"}),
  makeValue({level_cfg_path = "expertise[34].StartPrice"}),
  makeValue({level_cfg_path = "expertise[35].StartPrice"}),
}
local expertise_diseases_col2 = {
  makeValue({level_cfg_path = "expertise[2].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[3].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[4].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[5].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[6].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[7].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[8].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[9].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[10].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[11].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[12].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[13].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[14].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[15].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[16].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[17].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[18].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[19].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[20].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[21].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[22].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[23].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[24].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[25].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[26].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[27].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[28].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[29].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[30].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[31].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[32].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[33].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[34].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[35].Known", min_value = 0, max_value = 1}),
}
local expertise_diseases_col3 = {
  makeValue({level_cfg_path = "expertise[2].RschReqd"}),
  makeValue({level_cfg_path = "expertise[3].RschReqd"}),
  makeValue({level_cfg_path = "expertise[4].RschReqd"}),
  makeValue({level_cfg_path = "expertise[5].RschReqd"}),
  makeValue({level_cfg_path = "expertise[6].RschReqd"}),
  makeValue({level_cfg_path = "expertise[7].RschReqd"}),
  makeValue({level_cfg_path = "expertise[8].RschReqd"}),
  makeValue({level_cfg_path = "expertise[9].RschReqd"}),
  makeValue({level_cfg_path = "expertise[10].RschReqd"}),
  makeValue({level_cfg_path = "expertise[11].RschReqd"}),
  makeValue({level_cfg_path = "expertise[12].RschReqd"}),
  makeValue({level_cfg_path = "expertise[13].RschReqd"}),
  makeValue({level_cfg_path = "expertise[14].RschReqd"}),
  makeValue({level_cfg_path = "expertise[15].RschReqd"}),
  makeValue({level_cfg_path = "expertise[16].RschReqd"}),
  makeValue({level_cfg_path = "expertise[17].RschReqd"}),
  makeValue({level_cfg_path = "expertise[18].RschReqd"}),
  makeValue({level_cfg_path = "expertise[19].RschReqd"}),
  makeValue({level_cfg_path = "expertise[20].RschReqd"}),
  makeValue({level_cfg_path = "expertise[21].RschReqd"}),
  makeValue({level_cfg_path = "expertise[22].RschReqd"}),
  makeValue({level_cfg_path = "expertise[23].RschReqd"}),
  makeValue({level_cfg_path = "expertise[24].RschReqd"}),
  makeValue({level_cfg_path = "expertise[25].RschReqd"}),
  makeValue({level_cfg_path = "expertise[26].RschReqd"}),
  makeValue({level_cfg_path = "expertise[27].RschReqd"}),
  makeValue({level_cfg_path = "expertise[28].RschReqd"}),
  makeValue({level_cfg_path = "expertise[29].RschReqd"}),
  makeValue({level_cfg_path = "expertise[30].RschReqd"}),
  makeValue({level_cfg_path = "expertise[31].RschReqd"}),
  makeValue({level_cfg_path = "expertise[32].RschReqd"}),
  makeValue({level_cfg_path = "expertise[33].RschReqd"}),
  makeValue({level_cfg_path = "expertise[34].RschReqd"}),
  makeValue({level_cfg_path = "expertise[35].RschReqd"}),
}
local expertise_diseases_col4 = {
  makeValue({level_cfg_path = "expertise[2].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[3].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[4].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[5].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[6].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[7].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[8].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[9].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[10].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[11].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[12].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[13].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[14].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[15].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[16].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[17].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[18].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[19].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[20].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[21].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[22].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[23].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[24].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[25].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[26].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[27].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[28].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[29].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[30].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[31].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[32].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[33].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[34].MaxDiagDiff"}),
  makeValue({level_cfg_path = "expertise[35].MaxDiagDiff"}),
}
local expertise_disease_row_names = {}
for i = 2, 35 do
  expertise_disease_row_names[#expertise_disease_row_names + 1] = "level_editor.row_names.expertise_disease[" .. i .. "]"
end

local expertise_disease_section = makeTableSection({
  title_path = "level_editor.expertise_disease.title",
  row_names = expertise_disease_row_names,
  col_values = {
    expertise_diseases_col1,
    expertise_diseases_col2,
    expertise_diseases_col3,
    expertise_diseases_col4
  },
  col_names = {
    "level_editor.col_names.expertise_diseases.StartPrice",
    "level_editor.col_names.expertise_diseases.Known",
    "level_editor.col_names.expertise_diseases.RschReqd",
    "level_editor.col_names.expertise_diseases.MaxDiagDiff",
  }
})

local expertise_room_col1 = {
  makeValue({level_cfg_path = "expertise[1].StartPrice"}),
  makeValue({level_cfg_path = "expertise[36].StartPrice"}),
  makeValue({level_cfg_path = "expertise[37].StartPrice"}),
  makeValue({level_cfg_path = "expertise[38].StartPrice"}),
  makeValue({level_cfg_path = "expertise[39].StartPrice"}),
  makeValue({level_cfg_path = "expertise[40].StartPrice"}),
  makeValue({level_cfg_path = "expertise[41].StartPrice"}),
  makeValue({level_cfg_path = "expertise[42].StartPrice"}),
  makeValue({level_cfg_path = "expertise[43].StartPrice"}),
  makeValue({level_cfg_path = "expertise[44].StartPrice"}),
  makeValue({level_cfg_path = "expertise[45].StartPrice"}),
  makeValue({level_cfg_path = "expertise[46].StartPrice"}),
}
local expertise_room_col2 = {
  makeValue({level_cfg_path = "expertise[1].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[36].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[37].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[38].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[39].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[40].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[41].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[42].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[43].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[44].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[45].Known", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "expertise[46].Known", min_value = 0, max_value = 1}),
}
local expertise_room_col3 = {
  makeValue({level_cfg_path = "expertise[1].RschReqd"}),
  makeValue({level_cfg_path = "expertise[36].RschReqd"}),
  makeValue({level_cfg_path = "expertise[37].RschReqd"}),
  makeValue({level_cfg_path = "expertise[38].RschReqd"}),
  makeValue({level_cfg_path = "expertise[39].RschReqd"}),
  makeValue({level_cfg_path = "expertise[40].RschReqd"}),
  makeValue({level_cfg_path = "expertise[41].RschReqd"}),
  makeValue({level_cfg_path = "expertise[42].RschReqd"}),
  makeValue({level_cfg_path = "expertise[43].RschReqd"}),
  makeValue({level_cfg_path = "expertise[44].RschReqd"}),
  makeValue({level_cfg_path = "expertise[45].RschReqd"}),
  makeValue({level_cfg_path = "expertise[46].RschReqd"}),
}
local expertise_room_row_names = {
  "level_editor.expertise_room[1]",
}
for i = 36, 46 do
  expertise_room_row_names[#expertise_room_row_names + 1] = "level_editor.expertise_room[" .. i .. "]"
end

local expertise_room_section = makeTableSection({
  title_path = "level_editor.expertise.title",
  row_names = expertise_room_row_names,
  col_values = {expertise_room_col1, expertise_room_col2, expertise_room_col3},
  col_names = {
    "level_editor.col_names.expertise.StartPrice",
    "level_editor.col_names.expertise.Known",
    "level_editor.col_names.expertise.RschReqd",
  }
})

local objects_col1 = {
  makeValue({level_cfg_path = "objects[1].StartCost"}),
  makeValue({level_cfg_path = "objects[2].StartCost"}),
  makeValue({level_cfg_path = "objects[3].StartCost"}),
  makeValue({level_cfg_path = "objects[4].StartCost"}),
  makeValue({level_cfg_path = "objects[5].StartCost"}),
  makeValue({level_cfg_path = "objects[6].StartCost"}),
  makeValue({level_cfg_path = "objects[7].StartCost"}),
  makeValue({level_cfg_path = "objects[8].StartCost"}),
  makeValue({level_cfg_path = "objects[9].StartCost"}),
  makeValue({level_cfg_path = "objects[10].StartCost"}),
  makeValue({level_cfg_path = "objects[11].StartCost"}),
  makeValue({level_cfg_path = "objects[12].StartCost"}),
  makeValue({level_cfg_path = "objects[13].StartCost"}),
  makeValue({level_cfg_path = "objects[14].StartCost"}),
  makeValue({level_cfg_path = "objects[15].StartCost"}),
  makeValue({level_cfg_path = "objects[16].StartCost"}),
  makeValue({level_cfg_path = "objects[17].StartCost"}),
  makeValue({level_cfg_path = "objects[18].StartCost"}),
  makeValue({level_cfg_path = "objects[19].StartCost"}),
  makeValue({level_cfg_path = "objects[20].StartCost"}),
  makeValue({level_cfg_path = "objects[21].StartCost"}),
  makeValue({level_cfg_path = "objects[22].StartCost"}),
  makeValue({level_cfg_path = "objects[23].StartCost"}),
  makeValue({level_cfg_path = "objects[24].StartCost"}),
  makeValue({level_cfg_path = "objects[25].StartCost"}),
  makeValue({level_cfg_path = "objects[26].StartCost"}),
  makeValue({level_cfg_path = "objects[27].StartCost"}),
  makeValue({level_cfg_path = "objects[28].StartCost"}),
  makeValue({level_cfg_path = "objects[29].StartCost"}),
  makeValue({level_cfg_path = "objects[30].StartCost"}),
  makeValue({level_cfg_path = "objects[31].StartCost"}),
  makeValue({level_cfg_path = "objects[32].StartCost"}),
  makeValue({level_cfg_path = "objects[33].StartCost"}),
  makeValue({level_cfg_path = "objects[34].StartCost"}),
  makeValue({level_cfg_path = "objects[35].StartCost"}),
  makeValue({level_cfg_path = "objects[36].StartCost"}),
  makeValue({level_cfg_path = "objects[37].StartCost"}),
  makeValue({level_cfg_path = "objects[38].StartCost"}),
  makeValue({level_cfg_path = "objects[39].StartCost"}),
  makeValue({level_cfg_path = "objects[40].StartCost"}),
  makeValue({level_cfg_path = "objects[41].StartCost"}),
  makeValue({level_cfg_path = "objects[42].StartCost"}),
  makeValue({level_cfg_path = "objects[43].StartCost"}),
  makeValue({level_cfg_path = "objects[44].StartCost"}),
  makeValue({level_cfg_path = "objects[45].StartCost"}),
  makeValue({level_cfg_path = "objects[46].StartCost"}),
  makeValue({level_cfg_path = "objects[47].StartCost"}),
  makeValue({level_cfg_path = "objects[48].StartCost"}),
  makeValue({level_cfg_path = "objects[49].StartCost"}),
  makeValue({level_cfg_path = "objects[50].StartCost"}),
  makeValue({level_cfg_path = "objects[51].StartCost"}),
  makeValue({level_cfg_path = "objects[52].StartCost"}),
  makeValue({level_cfg_path = "objects[53].StartCost"}),
  makeValue({level_cfg_path = "objects[54].StartCost"}),
  makeValue({level_cfg_path = "objects[55].StartCost"}),
  makeValue({level_cfg_path = "objects[56].StartCost"}),
  makeValue({level_cfg_path = "objects[57].StartCost"}),
  makeValue({level_cfg_path = "objects[58].StartCost"}),
  makeValue({level_cfg_path = "objects[59].StartCost"}),
  makeValue({level_cfg_path = "objects[60].StartCost"}),
  makeValue({level_cfg_path = "objects[61].StartCost"}),
}
local objects_col2 = {
  makeValue({level_cfg_path = "objects[1].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[2].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[3].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[4].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[5].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[6].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[7].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[8].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[9].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[10].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[11].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[12].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[13].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[14].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[15].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[16].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[17].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[18].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[19].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[20].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[21].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[22].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[23].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[24].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[25].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[26].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[27].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[28].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[29].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[30].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[31].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[32].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[33].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[34].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[35].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[36].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[37].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[38].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[39].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[40].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[41].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[42].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[43].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[44].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[45].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[46].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[47].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[48].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[49].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[50].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[51].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[52].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[53].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[54].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[55].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[56].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[57].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[58].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[59].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[60].StartAvail", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[61].StartAvail", min_value = 0, max_value = 1}),
}
local objects_col3 = {
  makeValue({level_cfg_path = "objects[1].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[2].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[3].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[4].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[5].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[6].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[7].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[8].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[9].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[10].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[11].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[12].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[13].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[14].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[15].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[16].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[17].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[18].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[19].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[20].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[21].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[22].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[23].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[24].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[25].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[26].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[27].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[28].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[29].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[30].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[31].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[32].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[33].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[34].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[35].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[36].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[37].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[38].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[39].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[40].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[41].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[42].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[43].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[44].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[45].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[46].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[47].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[48].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[49].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[50].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[51].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[52].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[53].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[54].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[55].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[56].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[57].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[58].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[59].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[60].WhenAvail", min_value = 0}),
  makeValue({level_cfg_path = "objects[61].WhenAvail", min_value = 0}),
}
local objects_col4 = {
  makeValue({level_cfg_path = "objects[1].StartStrength"}),
  makeValue({level_cfg_path = "objects[2].StartStrength"}),
  makeValue({level_cfg_path = "objects[3].StartStrength"}),
  makeValue({level_cfg_path = "objects[4].StartStrength"}),
  makeValue({level_cfg_path = "objects[5].StartStrength"}),
  makeValue({level_cfg_path = "objects[6].StartStrength"}),
  makeValue({level_cfg_path = "objects[7].StartStrength"}),
  makeValue({level_cfg_path = "objects[8].StartStrength"}),
  makeValue({level_cfg_path = "objects[9].StartStrength"}),
  makeValue({level_cfg_path = "objects[10].StartStrength"}),
  makeValue({level_cfg_path = "objects[11].StartStrength"}),
  makeValue({level_cfg_path = "objects[12].StartStrength"}),
  makeValue({level_cfg_path = "objects[13].StartStrength"}),
  makeValue({level_cfg_path = "objects[14].StartStrength"}),
  makeValue({level_cfg_path = "objects[15].StartStrength"}),
  makeValue({level_cfg_path = "objects[16].StartStrength"}),
  makeValue({level_cfg_path = "objects[17].StartStrength"}),
  makeValue({level_cfg_path = "objects[18].StartStrength"}),
  makeValue({level_cfg_path = "objects[19].StartStrength"}),
  makeValue({level_cfg_path = "objects[20].StartStrength"}),
  makeValue({level_cfg_path = "objects[21].StartStrength"}),
  makeValue({level_cfg_path = "objects[22].StartStrength"}),
  makeValue({level_cfg_path = "objects[23].StartStrength"}),
  makeValue({level_cfg_path = "objects[24].StartStrength"}),
  makeValue({level_cfg_path = "objects[25].StartStrength"}),
  makeValue({level_cfg_path = "objects[26].StartStrength"}),
  makeValue({level_cfg_path = "objects[27].StartStrength"}),
  makeValue({level_cfg_path = "objects[28].StartStrength"}),
  makeValue({level_cfg_path = "objects[29].StartStrength"}),
  makeValue({level_cfg_path = "objects[30].StartStrength"}),
  makeValue({level_cfg_path = "objects[31].StartStrength"}),
  makeValue({level_cfg_path = "objects[32].StartStrength"}),
  makeValue({level_cfg_path = "objects[33].StartStrength"}),
  makeValue({level_cfg_path = "objects[34].StartStrength"}),
  makeValue({level_cfg_path = "objects[35].StartStrength"}),
  makeValue({level_cfg_path = "objects[36].StartStrength"}),
  makeValue({level_cfg_path = "objects[37].StartStrength"}),
  makeValue({level_cfg_path = "objects[38].StartStrength"}),
  makeValue({level_cfg_path = "objects[39].StartStrength"}),
  makeValue({level_cfg_path = "objects[40].StartStrength"}),
  makeValue({level_cfg_path = "objects[41].StartStrength"}),
  makeValue({level_cfg_path = "objects[42].StartStrength"}),
  makeValue({level_cfg_path = "objects[43].StartStrength"}),
  makeValue({level_cfg_path = "objects[44].StartStrength"}),
  makeValue({level_cfg_path = "objects[45].StartStrength"}),
  makeValue({level_cfg_path = "objects[46].StartStrength"}),
  makeValue({level_cfg_path = "objects[47].StartStrength"}),
  makeValue({level_cfg_path = "objects[48].StartStrength"}),
  makeValue({level_cfg_path = "objects[49].StartStrength"}),
  makeValue({level_cfg_path = "objects[50].StartStrength"}),
  makeValue({level_cfg_path = "objects[51].StartStrength"}),
  makeValue({level_cfg_path = "objects[52].StartStrength"}),
  makeValue({level_cfg_path = "objects[53].StartStrength"}),
  makeValue({level_cfg_path = "objects[54].StartStrength"}),
  makeValue({level_cfg_path = "objects[55].StartStrength"}),
  makeValue({level_cfg_path = "objects[56].StartStrength"}),
  makeValue({level_cfg_path = "objects[57].StartStrength"}),
  makeValue({level_cfg_path = "objects[58].StartStrength"}),
  makeValue({level_cfg_path = "objects[59].StartStrength"}),
  makeValue({level_cfg_path = "objects[60].StartStrength"}),
  makeValue({level_cfg_path = "objects[61].StartStrength"}),
}
local objects_col5 = {
  makeValue({level_cfg_path = "objects[1].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[2].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[3].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[4].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[5].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[6].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[7].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[8].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[9].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[10].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[11].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[12].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[13].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[14].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[15].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[16].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[17].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[18].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[19].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[20].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[21].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[22].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[23].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[24].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[25].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[26].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[27].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[28].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[29].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[30].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[31].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[32].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[33].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[34].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[35].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[36].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[37].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[38].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[39].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[40].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[41].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[42].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[43].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[44].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[45].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[46].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[47].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[48].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[49].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[50].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[51].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[52].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[53].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[54].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[55].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[56].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[57].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[58].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[59].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[60].AvailableForLevel", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "objects[61].AvailableForLevel", min_value = 0, max_value = 1}),
}
local rooms = {
  makeValue({level_cfg_path = "gbv.rooms[7].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[8].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[9].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[10].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[11].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[12].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[13].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[14].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[15].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[16].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[17].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[18].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[19].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[20].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[21].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[22].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[23].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[24].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[25].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[26].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[27].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[28].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[29].Cost"}),
  makeValue({level_cfg_path = "gbv.rooms[30].Cost"}),
}
local visuals_col1 = {
  makeValue({level_cfg_path = "visuals[0]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "visuals[1]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "visuals[2]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "visuals[3]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "visuals[4]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "visuals[5]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "visuals[6]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "visuals[7]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "visuals[8]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "visuals[9]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "visuals[10]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "visuals[11]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "visuals[12]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "visuals[13]", min_value = 0, max_value = 1})
}
local visuals_col2 = {
  makeValue({level_cfg_path = "visuals_available[0]"}),
  makeValue({level_cfg_path = "visuals_available[1]"}),
  makeValue({level_cfg_path = "visuals_available[2]"}),
  makeValue({level_cfg_path = "visuals_available[3]"}),
  makeValue({level_cfg_path = "visuals_available[4]"}),
  makeValue({level_cfg_path = "visuals_available[5]"}),
  makeValue({level_cfg_path = "visuals_available[6]"}),
  makeValue({level_cfg_path = "visuals_available[7]"}),
  makeValue({level_cfg_path = "visuals_available[8]"}),
  makeValue({level_cfg_path = "visuals_available[9]"}),
  makeValue({level_cfg_path = "visuals_available[10]"}),
  makeValue({level_cfg_path = "visuals_available[11]"}),
  makeValue({level_cfg_path = "visuals_available[12]"}),
  makeValue({level_cfg_path = "visuals_available[13]"})
}

local visuals_row_names = { }
for i = 0, 13 do
  visuals_row_names[#visuals_row_names + 1] = "level_editor.row_names.visuals_available[" .. i .. "]"
end
local visuals_col_names = {
  "level_editor.col_names.visuals",
  "level_editor.col_names.visuals_available",
}
local visuals_section = makeTableSection({
  title_path = "level_editor.visuals.title",
  row_names = visuals_row_names,
  col_values = {visuals_col1, visuals_col2},
  col_names = visuals_col_names
})

local non_visuals_col1 = {
  makeValue({level_cfg_path = "non_visuals[0]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[1]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[2]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[3]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[4]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[5]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[6]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[7]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[8]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[9]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[10]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[11]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[12]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[13]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[14]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[15]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[16]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[17]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[18]", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "non_visuals[19]", min_value = 0, max_value = 1}),
}
local non_visuals_col2 = {
  makeValue({level_cfg_path = "non_visuals_available[0]"}),
  makeValue({level_cfg_path = "non_visuals_available[1]"}),
  makeValue({level_cfg_path = "non_visuals_available[2]"}),
  makeValue({level_cfg_path = "non_visuals_available[3]"}),
  makeValue({level_cfg_path = "non_visuals_available[4]"}),
  makeValue({level_cfg_path = "non_visuals_available[5]"}),
  makeValue({level_cfg_path = "non_visuals_available[6]"}),
  makeValue({level_cfg_path = "non_visuals_available[7]"}),
  makeValue({level_cfg_path = "non_visuals_available[8]"}),
  makeValue({level_cfg_path = "non_visuals_available[9]"}),
  makeValue({level_cfg_path = "non_visuals_available[10]"}),
  makeValue({level_cfg_path = "non_visuals_available[11]"}),
  makeValue({level_cfg_path = "non_visuals_available[12]"}),
  makeValue({level_cfg_path = "non_visuals_available[13]"}),
  makeValue({level_cfg_path = "non_visuals_available[14]"}),
  makeValue({level_cfg_path = "non_visuals_available[15]"}),
  makeValue({level_cfg_path = "non_visuals_available[16]"}),
  makeValue({level_cfg_path = "non_visuals_available[17]"}),
  makeValue({level_cfg_path = "non_visuals_available[18]"}),
  makeValue({level_cfg_path = "non_visuals_available[19]"}),
}

local win_conditions_col1 = {
  makeValue({level_cfg_path = "win_criteria[0].Criteria"}),
  makeValue({level_cfg_path = "win_criteria[1].Criteria"}),
  makeValue({level_cfg_path = "win_criteria[2].Criteria"}),
  makeValue({level_cfg_path = "win_criteria[3].Criteria"}),
  makeValue({level_cfg_path = "win_criteria[4].Criteria"}),
  makeValue({level_cfg_path = "win_criteria[5].Criteria"}),
}
local win_conditions_col2 = {
  makeValue({level_cfg_path = "win_criteria[0].MaxMin"}),
  makeValue({level_cfg_path = "win_criteria[1].MaxMin"}),
  makeValue({level_cfg_path = "win_criteria[2].MaxMin"}),
  makeValue({level_cfg_path = "win_criteria[3].MaxMin"}),
  makeValue({level_cfg_path = "win_criteria[4].MaxMin"}),
  makeValue({level_cfg_path = "win_criteria[5].MaxMin"}),
}
local win_conditions_col3 = {
  makeValue({level_cfg_path = "win_criteria[0].Value"}),
  makeValue({level_cfg_path = "win_criteria[1].Value"}),
  makeValue({level_cfg_path = "win_criteria[2].Value"}),
  makeValue({level_cfg_path = "win_criteria[3].Value"}),
  makeValue({level_cfg_path = "win_criteria[4].Value"}),
  makeValue({level_cfg_path = "win_criteria[5].Value"}),
}
local win_conditions_col4 = {
  makeValue({level_cfg_path = "win_criteria[0].Group"}),
  makeValue({level_cfg_path = "win_criteria[1].Group"}),
  makeValue({level_cfg_path = "win_criteria[2].Group"}),
  makeValue({level_cfg_path = "win_criteria[3].Group"}),
  makeValue({level_cfg_path = "win_criteria[4].Group"}),
  makeValue({level_cfg_path = "win_criteria[5].Group"}),
}
local win_conditions_col5 = {
  makeValue({level_cfg_path = "win_criteria[0].Bound"}),
  makeValue({level_cfg_path = "win_criteria[1].Bound"}),
  makeValue({level_cfg_path = "win_criteria[2].Bound"}),
  makeValue({level_cfg_path = "win_criteria[3].Bound"}),
  makeValue({level_cfg_path = "win_criteria[4].Bound"}),
  makeValue({level_cfg_path = "win_criteria[5].Bound"}),
}
-- TODO ADD win criteria table

local lose_conditions_col1 = {
  makeValue({level_cfg_path = "lose_criteria[0].Criteria"}),
  makeValue({level_cfg_path = "lose_criteria[1].Criteria"}),
  makeValue({level_cfg_path = "lose_criteria[2].Criteria"}),
  makeValue({level_cfg_path = "lose_criteria[3].Criteria"}),
  makeValue({level_cfg_path = "lose_criteria[4].Criteria"}),
  makeValue({level_cfg_path = "lose_criteria[5].Criteria"}),
}
local lose_conditions_col2 = {
  makeValue({level_cfg_path = "lose_criteria[0].MaxMin"}),
  makeValue({level_cfg_path = "lose_criteria[1].MaxMin"}),
  makeValue({level_cfg_path = "lose_criteria[2].MaxMin"}),
  makeValue({level_cfg_path = "lose_criteria[3].MaxMin"}),
  makeValue({level_cfg_path = "lose_criteria[4].MaxMin"}),
  makeValue({level_cfg_path = "lose_criteria[5].MaxMin"}),
}
local lose_conditions_col3 = {
  makeValue({level_cfg_path = "lose_criteria[0].Value"}),
  makeValue({level_cfg_path = "lose_criteria[1].Value"}),
  makeValue({level_cfg_path = "lose_criteria[2].Value"}),
  makeValue({level_cfg_path = "lose_criteria[3].Value"}),
  makeValue({level_cfg_path = "lose_criteria[4].Value"}),
  makeValue({level_cfg_path = "lose_criteria[5].Value"}),
}
local lose_conditions_col4 = {
  makeValue({level_cfg_path = "lose_criteria[0].Group"}),
  makeValue({level_cfg_path = "lose_criteria[1].Group"}),
  makeValue({level_cfg_path = "lose_criteria[2].Group"}),
  makeValue({level_cfg_path = "lose_criteria[3].Group"}),
  makeValue({level_cfg_path = "lose_criteria[4].Group"}),
  makeValue({level_cfg_path = "lose_criteria[5].Group"}),
}
local lose_conditions_col5 = {
  makeValue({level_cfg_path = "lose_criteria[0].Bound"}),
  makeValue({level_cfg_path = "lose_criteria[1].Bound"}),
  makeValue({level_cfg_path = "lose_criteria[2].Bound"}),
  makeValue({level_cfg_path = "lose_criteria[3].Bound"}),
  makeValue({level_cfg_path = "lose_criteria[4].Bound"}),
  makeValue({level_cfg_path = "lose_criteria[5].Bound"}),
}
-- TODO ADD lose criteria table

local staff_levels = makeValuesSection({
  title_path = "level_editor.staff_levels.title",
  -- label_size
  -- value_size
  -- unit_size
  -- TODO title_sep, value_sep
  makeValue({level_cfg_path = "staff_levels[0].Month"}),
  makeValue({level_cfg_path = "staff_levels[0].Nurses"}),
  makeValue({level_cfg_path = "staff_levels[0].Doctors"}),
  makeValue({level_cfg_path = "staff_levels[0].Handymen"}),
  makeValue({level_cfg_path = "staff_levels[0].Receptionists"}),
  makeValue({level_cfg_path = "staff_levels[0].ShrkRate"}),
  makeValue({level_cfg_path = "staff_levels[0].SurgRate"}),
  makeValue({level_cfg_path = "staff_levels[0].RschRate"}),
  makeValue({level_cfg_path = "staff_levels[0].ConsRate"}),
  makeValue({level_cfg_path = "staff_levels[0].JrRate"}),
})

local emergency_control = {
  makeValue({level_cfg_path = "emergency_control[0].StartMonth"}),
  makeValue({level_cfg_path = "emergency_control[0].EndMonth"}),
  makeValue({level_cfg_path = "emergency_control[0].Min"}),
  makeValue({level_cfg_path = "emergency_control[0].Max"}),
  makeValue({level_cfg_path = "emergency_control[0].Illness"}),
  makeValue({level_cfg_path = "emergency_control[0].PercWin"}),
  makeValue({level_cfg_path = "emergency_control[0].Bonus"}),
}
-- TODO ADD emergency control table

local computer_playing_col = {
  makeValue({level_cfg_path = "computer[0].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[1].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[2].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[3].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[4].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[5].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[6].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[7].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[8].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[9].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[10].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[11].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[12].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[13].Playing", min_value = 0, max_value = 1}),
  makeValue({level_cfg_path = "computer[14].Playing", min_value = 0, max_value = 1}),
}
local computer_name_col = {
  makeValue({level_cfg_path = "computer[0].Name"}),
  makeValue({level_cfg_path = "computer[1].Name"}),
  makeValue({level_cfg_path = "computer[2].Name"}),
  makeValue({level_cfg_path = "computer[3].Name"}),
  makeValue({level_cfg_path = "computer[4].Name"}),
  makeValue({level_cfg_path = "computer[5].Name"}),
  makeValue({level_cfg_path = "computer[6].Name"}),
  makeValue({level_cfg_path = "computer[7].Name"}),
  makeValue({level_cfg_path = "computer[8].Name"}),
  makeValue({level_cfg_path = "computer[9].Name"}),
  makeValue({level_cfg_path = "computer[10].Name"}),
  makeValue({level_cfg_path = "computer[11].Name"}),
  makeValue({level_cfg_path = "computer[12].Name"}),
  makeValue({level_cfg_path = "computer[13].Name"}),
  makeValue({level_cfg_path = "computer[14].Name"}),
}
local computerplayers_row_names = {}
for i = 0, 14 do
  computerplayers_row_names[#computerplayers_row_names + 1] = "level_editor.row_names.computer[" .. i .. "]"
end
local computer_players = makeTableSection({
  title_path = "level_editor.computer.title",
  row_names = computerplayers_row_names,
  col_values = {computer_playing_col, computer_name_col},
  col_names = {"level_editor.col_names.computer.playing", "level_editor.col_names.computer.name"}
})

-- XXX TABLE with trophies??

local trophy_criteria = {
  makeValue({level_cfg_path = "awards_trophies.RatKillsAbsolute", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.CansofCoke", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.Reputation", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.Plant", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.TrophyStaffHappiness", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.RatKillsPercentage", name_path = true}),
}
local trophy_bonuses = {
  makeValue({level_cfg_path = "awards_trophies.RatKillsAbsoluteBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.RatKillsPercentageBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.CansofCokeBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.TrophyReputationBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.PlantBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.TrophyStaffHappinessBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.TrophyAllCuredBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.TrophyDeathBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.TrophyCuresBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.TrophyMayorBonus", name_path = true}),
}

local award_criteria = {
  makeValue({level_cfg_path = "awards_trophies.CuresAward", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.CuresPoor", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.DeathsAward", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.DeathsPoor", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.PopulationPercentageAward", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.PopulationPercentagePoor", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.CuresVDeathsAward", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.CuresVDeathsPoor", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.ReputationAward", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.ReputationPoor", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.HospValueAward", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.HospValuePoor", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.CleanlinessAward", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.CleanlinessPoor", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.EmergencyAward", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.EmergencyPoor", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.StaffHappinessAward", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.StaffHappinessPoor", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.PeepHappinessAward", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.PeepHappinessPoor", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.WaitingTimesAward", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.WaitingTimesPoor", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.WellKeptTechAward", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.WellKeptTechPoor", name_path = true}),
}

local award_bonuses = {
  makeValue({level_cfg_path = "awards_trophies.CuresBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.CuresPenalty", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.AllCuresBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.DeathsBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.DeathsPenalty", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.PopulationPercentageBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.PopulationPercentagePenalty", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.CuresVDeathsBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.CuresVDeathsPenalty", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.AwardReputationBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.AwardReputationPenalty", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.HospValueBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.HospValuePenalty", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.CleanlinessBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.CleanlinessPenalty", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.EmergencyBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.EmergencyPenalty", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.AwardStaffHappinessBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.AwardStaffHappinessPenalty", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.PeepHappinessBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.PeepHappinessPenalty", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.WaitingTimesBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.WaitingTimesPenalty", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.WellKeptTechBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.WellKeptTechPenalty", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.NewTechAward", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.NewTechPoor", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.ResearchBonus", name_path = true}),
  makeValue({level_cfg_path = "awards_trophies.ResearchPenalty", name_path = true}),
}
--]]

local town_page = makeEditPageSection({
  name_path = "level_editor.edit_page.town_page",
  town_values,
--  towns_section,
  popn_sectiom
})

--[[
local staff_page = makeEditPageSection({
  name_path = "level_editor.edit_page.staff_page",
  staff_min_salaries,
  doctor_additional_salaries,
  staff_levels,
})

local hospital_page = makeEditPageSection({
  name_path = "level_editor.edit_page.hospital_page",
  various_settings,
  trainings_settings,
})

local diseases_page = makeEditPageSection({
  name_path = "level_editor.edit_page.diseases_page",
  expertise_disease_section,
  visuals_section,
})

local rooms_page = makeEditPageSection({
  name_path = "level_editor.edit_page.rooms_page",
  expertise_room_section
})

local players_page = makeEditPageSection({
  name_path = "level_editor.edit_page.players_page",
  computer_players
})
--]]
return makeTabPageSection({
  title_path = "level_editor.tab_page.main",
  town_page,
--  staff_page,
--  hospital_page,
--  diseases_page,
--  rooms_page,
--  players_page
})
