class "Pos"
---@type Pos
local Size = _G["Pos"]

function Pos:Pos(x, y)
  self.x = x
  self.y = y
end

class "Size"
---@type Size
local Size = _G["Size"]

function Size:Size(w, h)
  self.w = w
  self.h = h
end
