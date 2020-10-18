local AddonName, Addon = ...

-- locals and speed
local pairs = pairs
local ipairs = ipairs
local select = select

local _G = _G
local CreateFrame = CreateFrame

local UnitDebuff = UnitDebuff
local UnitClass = UnitClass

local ActionButton_ShowOverlayGlow = ActionButton_ShowOverlayGlow
local ActionButton_HideOverlayGlow = ActionButton_HideOverlayGlow

local GetActionInfo = GetActionInfo
local GetSpellInfo = GetSpellInfo
local GetMacroSpell = GetMacroSpell

local ACTION_BUTTON_TEMPLATES = {
  "ActionButton",
  "MultiBarBottomLeftButton",
  "MultiBarBottomRightButton",
  "MultiBarLeftButton",
  "MultiBarRightButton"
}

local UNIT_TAG_PLAYER = "player"

local ABILITY_TYPE_SPELL = "spell"
local ABILITY_TYPE_MACRO = "macro"

local CLEANSE_SPELLS = {
  ["PALADIN"] = {
    ["Cleanse Toxins"] = {
      "Poison",
      "Disease"
    },
    ["Cleanse"] = {
      "Poison",
      "Disease",
      "Magic"
    }
  },
  ["MONK"] = {
    ["Detox"] = {
      "Poison",
      "Disease"
    }
  },
  ["SHAMAN"] = {
    ["Cleanse Spirit"] = {
      "Curse"
    }
  },
  ["DRUID"] = {
    ["Nature's Cure"] = {
      "Magic",
      "Curse",
      "Poison"
    }
  }
}

function Addon:GetTypes(spell)
  return CLEANSE_SPELLS[self.class][spell]
end

function Addon:CanRemoveDebuff(types)
  for _, type in pairs(types) do
    if (self.types[type]) then
      return true
    end
  end

  return false
end

-- main
function Addon:Load()
  self.frame = CreateFrame("Frame", nil)

  self.frame:SetScript("OnEvent", function(_, ...)
      self:OnEvent(...)
    end)

  self.frame:RegisterEvent("ADDON_LOADED")
  self.frame:RegisterEvent("PLAYER_LOGIN")
end

function Addon:OnEvent(event, ...)
  local action = self[event]
  
  if (action) then
    action(self, ...)
  end
end

function Addon:UpdateActionButtons()
  self.buttons = {}

  for _, template in pairs(ACTION_BUTTON_TEMPLATES) do
    for i = 1, 12 do
      local button = _G[template..i]
      local type, id = GetActionInfo(button.action)
      local spell = nil

      if (id and type == ABILITY_TYPE_SPELL) then
        spell = GetSpellInfo(id)
      end

      if (id and type == ABILITY_TYPE_MACRO) then
        spell = GetSpellInfo(select(1, GetMacroSpell(id)))
      end

      local types = self:GetTypes(spell)
      if (types) then
        self.buttons[button] = types
      end
    end
  end
end

function Addon:UpdateButtonOverlays()
  self.types = {}

  local i = 1
  local name, _, _, type = UnitDebuff(UNIT_TAG_PLAYER, i)

  while (name) do
    if (type) then
      self.types[type] = true
    end

    i = i + 1
    name, _, _, type = UnitDebuff(UNIT_TAG_PLAYER, i)
  end

  for button, types in pairs(self.buttons) do
    if (self:CanRemoveDebuff(types)) then
      ActionButton_ShowOverlayGlow(button)
    else
      ActionButton_HideOverlayGlow(button)
    end
  end
end

function Addon:ADDON_LOADED(name)
  if (AddonName == name) then
    self.frame:RegisterUnitEvent("UNIT_AURA", UNIT_TAG_PLAYER)

    self.buttons = {}
    self.class = select(2, UnitClass(UNIT_TAG_PLAYER))

    print(name, "loaded")

    self.frame:UnregisterEvent("ADDON_LOADED")
  end
end

function Addon:UNIT_AURA()
  self:UpdateActionButtons()
  self:UpdateButtonOverlays()
end

function Addon:PLAYER_LOGIN()
  self:UpdateActionButtons()
  self:UpdateButtonOverlays()

  self.frame:UnregisterEvent("PLAYER_LOGIN")
end

Addon:Load()