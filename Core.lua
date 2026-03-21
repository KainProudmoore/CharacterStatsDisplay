local addonName, addon = ...

local defaults = {
    point = "BOTTOMLEFT",
    relativePoint = "BOTTOMLEFT",
    xOfs = 20,
    yOfs = 20,
    locked = false,
    panelStyle = "minimal",
    fontSize = 14,
    bgAlpha = 0.8,
    lineSpacing = 6,
    showLeech = false,
    showParry = false,
    showDodge = false,
    showBlock = false,
}

local function InitDB()
    if not CharacterStatsDisplayDB then
        CharacterStatsDisplayDB = {}
    end

    for key, value in pairs(defaults) do
        if CharacterStatsDisplayDB[key] == nil then
            CharacterStatsDisplayDB[key] = value
        end
    end

    if CharacterStatsDisplayDB.panelStyle == "wow_stats" then
        CharacterStatsDisplayDB.panelStyle = defaults.panelStyle
    end
end

local CharacterStatsDisplay = CreateFrame("Frame", "CharacterStatsDisplayFrame", UIParent, "BackdropTemplate")
addon.frame = CharacterStatsDisplay
CharacterStatsDisplay:SetFrameStrata("HIGH")

local BASE_FRAME_WIDTH = 112
local LEFT_PADDING = 12
local RIGHT_PADDING = 10
local TOP_PADDING = 10
local BOTTOM_PADDING = 8
local LABEL_VALUE_GAP = 0
local BASE_VALUE_COLUMN_START = 60

local function GetLineSpacing()
    return CharacterStatsDisplayDB and CharacterStatsDisplayDB.lineSpacing or defaults.lineSpacing
end

local function GetFontSize()
    return CharacterStatsDisplayDB and CharacterStatsDisplayDB.fontSize or defaults.fontSize
end

local function GetLineHeight()
    return GetFontSize() + GetLineSpacing()
end

local function GetTitleHeight()
    return GetFontSize() + 10
end

local function GetFrameWidth()
    local fontDelta = GetFontSize() - defaults.fontSize
    return BASE_FRAME_WIDTH + math.max(0, fontDelta * 10)
end

local function GetValueColumnStart()
    local fontDelta = GetFontSize() - defaults.fontSize
    return BASE_VALUE_COLUMN_START + math.max(0, fontDelta * 6)
end

local statNames = {
    { key = "itemLevel", label = "装等", color = "|cFFFFFF00" },
    { key = "primaryStat", label = "主属性", color = "|cFFFFFFFF" },
    { key = "crit", label = "暴击", color = "|cFFFF0000" },
    { key = "haste", label = "急速", color = "|cFF00FF00" },
    { key = "mastery", label = "精通", color = "|cFF00FFFF" },
    { key = "versatility", label = "全能", color = "|cFFFFA500" },
    { key = "leech", label = "吸血", color = "|cFF00FF00", optional = true },
    { key = "parry", label = "招架", color = "|cFFFFFFFF", optional = true },
    { key = "dodge", label = "闪避", color = "|cFFFFFFFF", optional = true },
    { key = "block", label = "格挡", color = "|cFFFFFFFF", optional = true },
    { key = "speed", label = "移速", color = "|cFFFFFFFF" },
}

local function ShouldSkipStat(statInfo)
    if not statInfo.optional then
        return false
    end

    if statInfo.key == "leech" and not CharacterStatsDisplayDB.showLeech then
        return true
    end
    if statInfo.key == "parry" and not CharacterStatsDisplayDB.showParry then
        return true
    end
    if statInfo.key == "dodge" and not CharacterStatsDisplayDB.showDodge then
        return true
    end
    if statInfo.key == "block" and not CharacterStatsDisplayDB.showBlock then
        return true
    end

    return false
end

local function GetVisibleStatCount()
    local count = 7
    if CharacterStatsDisplayDB.showLeech then count = count + 1 end
    if CharacterStatsDisplayDB.showParry then count = count + 1 end
    if CharacterStatsDisplayDB.showDodge then count = count + 1 end
    if CharacterStatsDisplayDB.showBlock then count = count + 1 end
    return count
end

local function UpdateFrameSize()
    local statCount = GetVisibleStatCount()
    local height = GetTitleHeight() + (statCount * GetLineHeight()) + TOP_PADDING + BOTTOM_PADDING
    CharacterStatsDisplay:SetSize(GetFrameWidth(), height)
end

CharacterStatsDisplay:SetMovable(true)
CharacterStatsDisplay:EnableMouse(true)
CharacterStatsDisplay:RegisterForDrag("LeftButton")

CharacterStatsDisplay:SetScript("OnDragStart", function(self)
    if not CharacterStatsDisplayDB.locked then
        self:StartMoving()
    end
end)

CharacterStatsDisplay:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    CharacterStatsDisplayDB.point = point
    CharacterStatsDisplayDB.relativePoint = relativePoint
    CharacterStatsDisplayDB.xOfs = xOfs
    CharacterStatsDisplayDB.yOfs = yOfs
end)

CharacterStatsDisplay.title = CharacterStatsDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
CharacterStatsDisplay.title:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", LEFT_PADDING, -TOP_PADDING)
CharacterStatsDisplay.title:SetText("角色属性")

CharacterStatsDisplay.stats = {}
CharacterStatsDisplay.styleLayers = {}

local function CreateStyleTexture(name, layer, subLevel)
    local texture = CharacterStatsDisplay:CreateTexture(nil, layer)
    if subLevel then
        texture:SetDrawLayer(layer, subLevel)
    end
    texture:SetTexture("Interface\\Buttons\\WHITE8X8")
    texture:Hide()
    CharacterStatsDisplay.styleLayers[name] = texture
    return texture
end

CreateStyleTexture("minimalBg", "BACKGROUND", 0)
CreateStyleTexture("wowBg", "BACKGROUND", 0)
CreateStyleTexture("wowHeader", "BACKGROUND", 1)
CreateStyleTexture("wowHeaderGlow", "BACKGROUND", 2)
CreateStyleTexture("wowTopEdge", "ARTWORK", 0)
CreateStyleTexture("wowBottomEdge", "ARTWORK", 0)
CreateStyleTexture("wowLeftEdge", "ARTWORK", 0)
CreateStyleTexture("wowRightEdge", "ARTWORK", 0)
CreateStyleTexture("wowTopFadeOuter", "ARTWORK", 1)
CreateStyleTexture("wowTopFadeInner", "ARTWORK", 2)
CreateStyleTexture("wowBottomFadeOuter", "ARTWORK", 1)
CreateStyleTexture("wowBottomFadeInner", "ARTWORK", 2)
CreateStyleTexture("wowLeftFadeOuter", "ARTWORK", 1)
CreateStyleTexture("wowLeftFadeInner", "ARTWORK", 2)
CreateStyleTexture("wowRightFadeOuter", "ARTWORK", 1)
CreateStyleTexture("wowRightFadeInner", "ARTWORK", 2)

local function HideStyleLayers()
    for _, texture in pairs(CharacterStatsDisplay.styleLayers) do
        texture:Hide()
    end
end

local function UpdateStyleLayout()
    local layers = CharacterStatsDisplay.styleLayers

    layers.minimalBg:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", 3, -3)
    layers.minimalBg:SetPoint("BOTTOMRIGHT", CharacterStatsDisplay, "BOTTOMRIGHT", -3, 3)

    layers.wowBg:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", 4, -4)
    layers.wowBg:SetPoint("BOTTOMRIGHT", CharacterStatsDisplay, "BOTTOMRIGHT", -4, 4)

    layers.wowHeader:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", 4, -4)
    layers.wowHeader:SetPoint("TOPRIGHT", CharacterStatsDisplay, "TOPRIGHT", -4, -4)
    layers.wowHeader:SetHeight(26)

    layers.wowHeaderGlow:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", 4, -26)
    layers.wowHeaderGlow:SetPoint("TOPRIGHT", CharacterStatsDisplay, "TOPRIGHT", -4, -26)
    layers.wowHeaderGlow:SetHeight(8)

    layers.wowTopEdge:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", 4, -4)
    layers.wowTopEdge:SetPoint("TOPRIGHT", CharacterStatsDisplay, "TOPRIGHT", -4, -4)
    layers.wowTopEdge:SetHeight(1)

    layers.wowBottomEdge:SetPoint("BOTTOMLEFT", CharacterStatsDisplay, "BOTTOMLEFT", 4, 4)
    layers.wowBottomEdge:SetPoint("BOTTOMRIGHT", CharacterStatsDisplay, "BOTTOMRIGHT", -4, 4)
    layers.wowBottomEdge:SetHeight(1)

    layers.wowLeftEdge:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", 4, -4)
    layers.wowLeftEdge:SetPoint("BOTTOMLEFT", CharacterStatsDisplay, "BOTTOMLEFT", 4, 4)
    layers.wowLeftEdge:SetWidth(1)

    layers.wowRightEdge:SetPoint("TOPRIGHT", CharacterStatsDisplay, "TOPRIGHT", -4, -4)
    layers.wowRightEdge:SetPoint("BOTTOMRIGHT", CharacterStatsDisplay, "BOTTOMRIGHT", -4, 4)
    layers.wowRightEdge:SetWidth(1)

    layers.wowTopFadeOuter:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", 4, -4)
    layers.wowTopFadeOuter:SetPoint("TOPRIGHT", CharacterStatsDisplay, "TOPRIGHT", -4, -4)
    layers.wowTopFadeOuter:SetHeight(16)

    layers.wowTopFadeInner:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", 4, -8)
    layers.wowTopFadeInner:SetPoint("TOPRIGHT", CharacterStatsDisplay, "TOPRIGHT", -4, -8)
    layers.wowTopFadeInner:SetHeight(22)

    layers.wowBottomFadeOuter:SetPoint("BOTTOMLEFT", CharacterStatsDisplay, "BOTTOMLEFT", 4, 4)
    layers.wowBottomFadeOuter:SetPoint("BOTTOMRIGHT", CharacterStatsDisplay, "BOTTOMRIGHT", -4, 4)
    layers.wowBottomFadeOuter:SetHeight(14)

    layers.wowBottomFadeInner:SetPoint("BOTTOMLEFT", CharacterStatsDisplay, "BOTTOMLEFT", 4, 4)
    layers.wowBottomFadeInner:SetPoint("BOTTOMRIGHT", CharacterStatsDisplay, "BOTTOMRIGHT", -4, 4)
    layers.wowBottomFadeInner:SetHeight(18)

    layers.wowLeftFadeOuter:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", 4, -4)
    layers.wowLeftFadeOuter:SetPoint("BOTTOMLEFT", CharacterStatsDisplay, "BOTTOMLEFT", 4, 4)
    layers.wowLeftFadeOuter:SetWidth(14)

    layers.wowLeftFadeInner:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", 4, -4)
    layers.wowLeftFadeInner:SetPoint("BOTTOMLEFT", CharacterStatsDisplay, "BOTTOMLEFT", 4, 4)
    layers.wowLeftFadeInner:SetWidth(20)

    layers.wowRightFadeOuter:SetPoint("TOPRIGHT", CharacterStatsDisplay, "TOPRIGHT", -4, -4)
    layers.wowRightFadeOuter:SetPoint("BOTTOMRIGHT", CharacterStatsDisplay, "BOTTOMRIGHT", -4, 4)
    layers.wowRightFadeOuter:SetWidth(14)

    layers.wowRightFadeInner:SetPoint("TOPRIGHT", CharacterStatsDisplay, "TOPRIGHT", -4, -4)
    layers.wowRightFadeInner:SetPoint("BOTTOMRIGHT", CharacterStatsDisplay, "BOTTOMRIGHT", -4, 4)
    layers.wowRightFadeInner:SetWidth(20)
end

local function ApplyBackdrop()
    local style = CharacterStatsDisplayDB.panelStyle or defaults.panelStyle
    local layers = CharacterStatsDisplay.styleLayers

    HideStyleLayers()

    if style == "default" then
        CharacterStatsDisplay:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
    else
        CharacterStatsDisplay:SetBackdrop(nil)
    end

    if style == "minimal" then
        layers.minimalBg:SetColorTexture(0.03, 0.03, 0.03, CharacterStatsDisplayDB.bgAlpha)
        layers.minimalBg:Show()
    end
end

local function ApplyDisplaySettings()
    ApplyBackdrop()
    if (CharacterStatsDisplayDB.panelStyle or defaults.panelStyle) == "default" then
        CharacterStatsDisplay:SetBackdropColor(0, 0, 0, CharacterStatsDisplayDB.bgAlpha)
    end
    CharacterStatsDisplay.title:SetFont(STANDARD_TEXT_FONT, GetFontSize() + 2, "")
    CharacterStatsDisplay.title:SetTextColor(1, 0.82, 0)
    CharacterStatsDisplay.title:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", LEFT_PADDING, -TOP_PADDING)
    UpdateFrameSize()
    UpdateStyleLayout()
end

local currentStats = {}

local function CreateStatTexts()
    for _, statRow in pairs(CharacterStatsDisplay.stats) do
        if statRow.label then
            statRow.label:Hide()
        end
        if statRow.value then
            statRow.value:Hide()
        end
    end

    CharacterStatsDisplay.stats = {}
    currentStats = {}

    local currentY = -(TOP_PADDING + GetTitleHeight())
    local frameWidth = GetFrameWidth()
    local valueColumnStart = GetValueColumnStart()
    local valueColumnWidth = frameWidth - valueColumnStart - RIGHT_PADDING
    local labelWidth = valueColumnStart - LEFT_PADDING - LABEL_VALUE_GAP

    for _, statInfo in ipairs(statNames) do
        if not ShouldSkipStat(statInfo) then
            local labelText = CharacterStatsDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            labelText:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", LEFT_PADDING, currentY)
            labelText:SetWidth(labelWidth)
            labelText:SetJustifyH("LEFT")
            labelText:SetFont(STANDARD_TEXT_FONT, GetFontSize(), "")
            labelText:SetText(statInfo.color .. statInfo.label .. "|r")

            local valueText = CharacterStatsDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            valueText:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", valueColumnStart, currentY)
            valueText:SetWidth(valueColumnWidth)
            valueText:SetJustifyH("LEFT")
            valueText:SetFont(STANDARD_TEXT_FONT, GetFontSize(), "")
            valueText:SetText("|cFFFFFFFF--|r")

            CharacterStatsDisplay.stats[statInfo.key] = {
                label = labelText,
                value = valueText,
                lastLabel = statInfo.label,
            }

            currentY = currentY - GetLineHeight()
        end
    end

    UpdateFrameSize()
end

local function GetPlayerItemLevel()
    local _, equippedItemLevel = GetAverageItemLevel()
    return equippedItemLevel and string.format("%.1f", equippedItemLevel) or "--"
end

local function GetPlayerPrimaryStat()
    local spec = GetSpecialization()
    if not spec then
        return "--", "主属性"
    end

    local strength = UnitStat("player", 1)
    local agility = UnitStat("player", 2)
    local intellect = UnitStat("player", 4)
    local _, class = UnitClass("player")

    if class == "WARRIOR" or class == "DEATHKNIGHT" then
        return strength, "力量"
    end

    if class == "PALADIN" then
        if spec == 1 then
            return intellect, "智力"
        end
        return strength, "力量"
    end

    if class == "HUNTER" or class == "ROGUE" or class == "DEMONHUNTER" then
        return agility, "敏捷"
    end

    if class == "MONK" then
        if spec == 2 then
            return intellect, "智力"
        end
        return agility, "敏捷"
    end

    if class == "MAGE" or class == "PRIEST" or class == "WARLOCK" or class == "EVOKER" then
        return intellect, "智力"
    end

    if class == "DRUID" then
        if spec == 2 or spec == 3 then
            return agility, "敏捷"
        end
        return intellect, "智力"
    end

    if class == "SHAMAN" then
        if spec == 2 then
            return agility, "敏捷"
        end
        return intellect, "智力"
    end

    return strength, "力量"
end

local function GetPlayerCrit()
    local crit = GetCritChance()
    return crit and string.format("%.1f%%", crit) or "--"
end

local function GetPlayerHaste()
    local haste = GetHaste()
    return haste and string.format("%.1f%%", haste) or "--"
end

local function GetPlayerMastery()
    local mastery = GetMasteryEffect()
    return mastery and string.format("%.1f%%", mastery) or "--"
end

local function GetPlayerVersatility()
    local function SafeCall(fn, ...)
        if type(fn) ~= "function" then
            return nil
        end
        local ok, result = pcall(fn, ...)
        if ok then
            return result
        end
        return nil
    end

    local function ToNumber(value)
        if type(value) == "number" then
            return value
        end
        if type(value) == "string" then
            return tonumber(value:gsub("%%", ""))
        end
        return nil
    end

    local base = ToNumber(SafeCall(GetCombatRatingBonus, CR_VERSATILITY_DAMAGE_DONE)) or 0
    local extra = 0
    local rawBonus = ToNumber(SafeCall(GetVersatilityBonus, CR_VERSATILITY_DAMAGE_DONE))

    -- On most clients this is the bonus part; on some clients it may already be total.
    if rawBonus and rawBonus > 0 then
        if rawBonus > base + 0.05 then
            return string.format("%.1f%%", rawBonus)
        end
        extra = rawBonus
    end

    -- Fallback for clients exposing total stats table.
    local stats = SafeCall(C_PaperDollInfo and C_PaperDollInfo.GetStats)
    if type(stats) == "table" then
        local tableTotal = ToNumber(stats.VERSATILITY_DAMAGE_DONE)
            or ToNumber(stats.VERSATILITY)
            or ToNumber(stats.versatilityDamageDone)
            or ToNumber(stats.versatility)
        if tableTotal and tableTotal > base + extra + 0.05 then
            return string.format("%.1f%%", tableTotal)
        end
    end

    local total = base + extra
    if total >= 0 then
        return string.format("%.1f%%", total)
    end
    return "--"
end

local function GetPlayerLeech()
    local leech = GetLifesteal()
    return leech and string.format("%.1f%%", leech) or "--"
end

local function GetPlayerParry()
    local parry = GetParryChance()
    return parry and string.format("%.1f%%", parry) or "--"
end

local function GetPlayerDodge()
    local dodge = GetDodgeChance()
    return dodge and string.format("%.1f%%", dodge) or "--"
end

local function GetPlayerBlock()
    local block = GetBlockChance()
    return block and string.format("%.1f%%", block) or "--"
end

local function GetPlayerSpeed()
    local speed = GetUnitSpeed("player")
    if speed and speed > 0 then
        return string.format("%.0f%%", speed / 7 * 100)
    end
    return "--"
end

local function UpdateStat(key, value, color, label)
    local statRow = CharacterStatsDisplay.stats[key]
    if currentStats[key] ~= value or (statRow and statRow.lastLabel ~= label) then
        currentStats[key] = value

        if statRow then
            statRow.lastLabel = label
            statRow.label:SetText(color .. label .. "|r")
            statRow.value:SetText("|cFFFFFFFF" .. value .. "|r")
        end
    end
end

local lastGreenStatsUpdate = 0
local lastPrimaryStatUpdate = 0
local lastItemLevelUpdate = 0
local lastSpeedUpdate = 0
local isInCombat = false
local combatUpdateTicker = nil

local function UpdateGreenStats()
    local now = GetTime()
    local interval = isInCombat and 0.5 or 3
    if now - lastGreenStatsUpdate < interval then
        return
    end

    lastGreenStatsUpdate = now

    UpdateStat("crit", GetPlayerCrit(), "|cFFFF0000", "暴击")
    UpdateStat("haste", GetPlayerHaste(), "|cFF00FF00", "急速")
    UpdateStat("mastery", GetPlayerMastery(), "|cFF00FFFF", "精通")
    UpdateStat("versatility", GetPlayerVersatility(), "|cFFFFA500", "全能")

    if CharacterStatsDisplayDB.showLeech then
        UpdateStat("leech", GetPlayerLeech(), "|cFF00FF00", "吸血")
    end
    if CharacterStatsDisplayDB.showParry then
        UpdateStat("parry", GetPlayerParry(), "|cFFFFFFFF", "招架")
    end
    if CharacterStatsDisplayDB.showDodge then
        UpdateStat("dodge", GetPlayerDodge(), "|cFFFFFFFF", "闪避")
    end
    if CharacterStatsDisplayDB.showBlock then
        UpdateStat("block", GetPlayerBlock(), "|cFFFFFFFF", "格挡")
    end
end

local function UpdateItemLevel()
    local now = GetTime()
    if now - lastItemLevelUpdate < 3 then
        return
    end

    lastItemLevelUpdate = now
    UpdateStat("itemLevel", GetPlayerItemLevel(), "|cFFFFFF00", "装等")
end

local function UpdatePrimaryStat()
    local now = GetTime()
    if now - lastPrimaryStatUpdate < 3 then
        return
    end

    lastPrimaryStatUpdate = now
    local statValue, statName = GetPlayerPrimaryStat()
    UpdateStat("primaryStat", statValue, "|cFFFFFFFF", statName)
end

local function UpdateSpeed()
    local now = GetTime()
    if now - lastSpeedUpdate < 0.5 then
        return
    end

    lastSpeedUpdate = now
    UpdateStat("speed", GetPlayerSpeed(), "|cFFFFFFFF", "移速")
end

local function UpdateAllStats()
    UpdateItemLevel()
    UpdatePrimaryStat()
    UpdateGreenStats()
    UpdateSpeed()
end

local function StartCombatUpdates()
    if combatUpdateTicker then
        combatUpdateTicker:Cancel()
    end

    combatUpdateTicker = C_Timer.NewTicker(0.5, function()
        UpdateGreenStats()
        UpdatePrimaryStat()
        UpdateSpeed()
    end)
end

local function StopCombatUpdates()
    if combatUpdateTicker then
        combatUpdateTicker:Cancel()
        combatUpdateTicker = nil
    end
end

CharacterStatsDisplay:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitDB()
        ApplyDisplaySettings()
        CreateStatTexts()
        UpdateAllStats()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        lastItemLevelUpdate = 0
        lastGreenStatsUpdate = 0
        lastPrimaryStatUpdate = 0
        UpdateAllStats()
    elseif event == "PLAYER_REGEN_DISABLED" then
        isInCombat = true
        lastGreenStatsUpdate = 0
        StartCombatUpdates()
    elseif event == "PLAYER_REGEN_ENABLED" then
        isInCombat = false
        StopCombatUpdates()
    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        lastPrimaryStatUpdate = 0
        UpdatePrimaryStat()
    end
end)

CharacterStatsDisplay:RegisterEvent("PLAYER_LOGIN")
CharacterStatsDisplay:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
CharacterStatsDisplay:RegisterEvent("PLAYER_REGEN_DISABLED")
CharacterStatsDisplay:RegisterEvent("PLAYER_REGEN_ENABLED")
CharacterStatsDisplay:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
CharacterStatsDisplay:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

C_Timer.NewTicker(3, function()
    if not isInCombat then
        UpdateGreenStats()
        UpdatePrimaryStat()
    end
    UpdateItemLevel()
end)

C_Timer.NewTicker(0.5, UpdateSpeed)

local SettingsFrame = nil
local checkboxes = {}
local panelStyles = { "minimal", "default" }
local panelStyleLabels = {
    minimal = "无边框",
    default = "默认边框",
}

local function RefreshDisplayLayout()
    ApplyDisplaySettings()
    CreateStatTexts()
    UpdateAllStats()
end

local function CreateSettingsFrame()
    if SettingsFrame then
        SettingsFrame:Show()
        return
    end

    SettingsFrame = CreateFrame("Frame", "CharacterStatsDisplaySettings", UIParent, "BasicFrameTemplateWithInset")
    SettingsFrame:SetSize(320, 560)
    SettingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    SettingsFrame:SetMovable(true)
    SettingsFrame:EnableMouse(true)
    SettingsFrame:RegisterForDrag("LeftButton")
    SettingsFrame:SetScript("OnDragStart", SettingsFrame.StartMoving)
    SettingsFrame:SetScript("OnDragStop", SettingsFrame.StopMovingOrSizing)
    SettingsFrame:SetFrameStrata("DIALOG")

    SettingsFrame.TitleBg:SetHeight(30)
    SettingsFrame.title = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    SettingsFrame.title:SetPoint("TOP", SettingsFrame.TitleBg, "TOP", 0, -5)
    SettingsFrame.title:SetText("角色属性显示 - 设置")

    local content = CreateFrame("Frame", nil, SettingsFrame)
    content:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 10, -35)
    content:SetPoint("BOTTOMRIGHT", SettingsFrame, "BOTTOMRIGHT", -10, 10)

    local yOffset = -10

    local moveTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    moveTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
    moveTitle:SetText("框体移动")
    yOffset = yOffset - 25

    local lockButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    lockButton:SetSize(120, 25)
    lockButton:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)

    local function UpdateLockButtonText()
        if CharacterStatsDisplayDB.locked then
            lockButton:SetText("解锁框体")
        else
            lockButton:SetText("锁定框体")
        end
    end

    lockButton:SetScript("OnClick", function()
        CharacterStatsDisplayDB.locked = not CharacterStatsDisplayDB.locked
        UpdateLockButtonText()
        if CharacterStatsDisplayDB.locked then
            print("角色属性显示：框体已锁定")
        else
            print("角色属性显示：框体已解锁，可以拖动")
        end
    end)

    UpdateLockButtonText()
    yOffset = yOffset - 40

    local appearanceTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    appearanceTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
    appearanceTitle:SetText("外观")
    yOffset = yOffset - 25

    local function CreateAdjuster(parent, label, formatter, y, onDecrease, onIncrease, getValue)
        local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        labelText:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
        labelText:SetText(label)

        local valueText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        valueText:SetPoint("LEFT", parent, "TOPLEFT", 100, y - 1)

        local minusButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        minusButton:SetSize(26, 22)
        minusButton:SetPoint("LEFT", valueText, "RIGHT", 8, 0)
        minusButton:SetText("-")

        local plusButton = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        plusButton:SetSize(26, 22)
        plusButton:SetPoint("LEFT", minusButton, "RIGHT", 6, 0)
        plusButton:SetText("+")

        local function RefreshValue()
            valueText:SetText(formatter(getValue()))
        end

        minusButton:SetScript("OnClick", function()
            onDecrease()
            RefreshValue()
        end)

        plusButton:SetScript("OnClick", function()
            onIncrease()
            RefreshValue()
        end)

        RefreshValue()
        return y - 34
    end

    local function CreateDropdown(parent, label, y, options, getValue, onSelect)
        local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        labelText:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
        labelText:SetText(label)

        local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
        button:SetSize(150, 24)
        button:SetPoint("LEFT", parent, "TOPLEFT", 100, y - 1)
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        button:SetBackdropColor(0.10, 0.10, 0.10, 0.95)
        button:SetBackdropBorderColor(0.85, 0.72, 0.18, 0.85)

        local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        buttonText:SetPoint("LEFT", button, "LEFT", 12, 0)
        buttonText:SetPoint("RIGHT", button, "RIGHT", -24, 0)
        buttonText:SetJustifyH("LEFT")

        local arrowText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        arrowText:SetPoint("RIGHT", button, "RIGHT", -10, 0)
        arrowText:SetText("v")

        local menu = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        menu:SetSize(150, (#options * 24) + 8)
        menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -4)
        menu:SetFrameStrata("TOOLTIP")
        menu:SetFrameLevel((SettingsFrame:GetFrameLevel() or 1) + 50)
        menu:SetToplevel(true)
        menu:EnableMouse(true)
        menu:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        menu:SetBackdropColor(0.02, 0.02, 0.02, 1.0)
        menu:SetBackdropBorderColor(0.85, 0.72, 0.18, 0.85)
        menu:Hide()

        local optionRows = {}

        local function RefreshDropdown()
            local current = getValue()
            if not panelStyleLabels[current] then
                current = defaults.panelStyle
                CharacterStatsDisplayDB.panelStyle = current
            end
            buttonText:SetText(panelStyleLabels[current] or current or "")

            for _, row in ipairs(optionRows) do
                if row.value == current then
                    row.text:SetTextColor(1.0, 0.84, 0.12)
                else
                    row.text:SetTextColor(1, 1, 1)
                end
            end
        end

        for index, option in ipairs(options) do
            local optionButton = CreateFrame("Button", nil, menu)
            optionButton:SetSize(130, 20)
            optionButton:SetPoint("TOPLEFT", menu, "TOPLEFT", 10, -6 - ((index - 1) * 24))
            optionButton:SetFrameStrata("TOOLTIP")
            optionButton:SetFrameLevel(menu:GetFrameLevel() + 1)

            local optionText = optionButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            optionText:SetAllPoints()
            optionText:SetJustifyH("LEFT")
            optionText:SetText(panelStyleLabels[option] or option)

            optionRows[#optionRows + 1] = { value = option, text = optionText }

            optionButton:SetScript("OnClick", function()
                menu:Hide()
                arrowText:SetText("v")
                onSelect(option)
                RefreshDropdown()
            end)

            optionButton:SetScript("OnEnter", function()
                optionText:SetTextColor(1.0, 0.84, 0.12)
            end)
            optionButton:SetScript("OnLeave", RefreshDropdown)
        end

        button:SetScript("OnClick", function()
            if menu:IsShown() then
                menu:Hide()
                arrowText:SetText("v")
            else
                menu:Show()
                arrowText:SetText("^")
            end
        end)

        SettingsFrame:HookScript("OnHide", function()
            menu:Hide()
            arrowText:SetText("v")
        end)

        RefreshDropdown()
        return y - 40
    end

    yOffset = CreateAdjuster(
        content,
        "字体大小",
        function(value) return tostring(value) end,
        yOffset,
        function()
            CharacterStatsDisplayDB.fontSize = math.max(10, CharacterStatsDisplayDB.fontSize - 1)
            RefreshDisplayLayout()
        end,
        function()
            CharacterStatsDisplayDB.fontSize = math.min(20, CharacterStatsDisplayDB.fontSize + 1)
            RefreshDisplayLayout()
        end,
        function()
            return CharacterStatsDisplayDB.fontSize
        end
    )

    yOffset = CreateAdjuster(
        content,
        "背景透明度",
        function(value) return string.format("%.1f", value) end,
        yOffset,
        function()
            CharacterStatsDisplayDB.bgAlpha = math.max(0.0, tonumber(string.format("%.1f", CharacterStatsDisplayDB.bgAlpha - 0.1)))
            ApplyDisplaySettings()
        end,
        function()
            CharacterStatsDisplayDB.bgAlpha = math.min(1.0, tonumber(string.format("%.1f", CharacterStatsDisplayDB.bgAlpha + 0.1)))
            ApplyDisplaySettings()
        end,
        function()
            return CharacterStatsDisplayDB.bgAlpha
        end
    )

    yOffset = CreateDropdown(
        content,
        "面板样式",
        yOffset,
        panelStyles,
        function()
            return CharacterStatsDisplayDB.panelStyle or defaults.panelStyle
        end,
        function(value)
            CharacterStatsDisplayDB.panelStyle = value
            RefreshDisplayLayout()
        end
    )

    yOffset = CreateAdjuster(
        content,
        "行距",
        function(value) return tostring(value) end,
        yOffset,
        function()
            CharacterStatsDisplayDB.lineSpacing = math.max(2, CharacterStatsDisplayDB.lineSpacing - 1)
            RefreshDisplayLayout()
        end,
        function()
            CharacterStatsDisplayDB.lineSpacing = math.min(12, CharacterStatsDisplayDB.lineSpacing + 1)
            RefreshDisplayLayout()
        end,
        function()
            return CharacterStatsDisplayDB.lineSpacing
        end
    )

    local statTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    statTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
    statTitle:SetText("额外属性显示")
    yOffset = yOffset - 25

    local function CreateCheckbox(parent, label, key, y)
        local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
        checkbox:SetSize(24, 24)

        local text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        text:SetText(label)

        checkbox:SetChecked(CharacterStatsDisplayDB[key])
        checkboxes[key] = checkbox

        checkbox:SetScript("OnClick", function(self)
            CharacterStatsDisplayDB[key] = self:GetChecked()
            lastItemLevelUpdate = 0
            lastPrimaryStatUpdate = 0
            lastGreenStatsUpdate = 0
            lastSpeedUpdate = 0
            CreateStatTexts()
            UpdateAllStats()
        end)

        return y - 28
    end

    yOffset = CreateCheckbox(content, "显示吸血", "showLeech", yOffset)
    yOffset = CreateCheckbox(content, "显示招架", "showParry", yOffset)
    yOffset = CreateCheckbox(content, "显示闪避", "showDodge", yOffset)
    yOffset = CreateCheckbox(content, "显示格挡", "showBlock", yOffset)

    yOffset = yOffset - 20

    local resetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetButton:SetSize(120, 25)
    resetButton:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
    resetButton:SetText("重置位置")
    resetButton:SetScript("OnClick", function()
        CharacterStatsDisplay:ClearAllPoints()
        CharacterStatsDisplay:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 20)
        CharacterStatsDisplayDB.point = "BOTTOMLEFT"
        CharacterStatsDisplayDB.relativePoint = "BOTTOMLEFT"
        CharacterStatsDisplayDB.xOfs = 20
        CharacterStatsDisplayDB.yOfs = 20
        print("角色属性显示：位置已重置")
    end)

    local closeButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 25)
    closeButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    closeButton:SetText("关闭")
    closeButton:SetScript("OnClick", function()
        SettingsFrame:Hide()
    end)

    SettingsFrame:Show()
end

SLASH_CHARACTERSTATSDISPLAY1 = "/csd"
SLASH_CHARACTERSTATSDISPLAY2 = "/characterstats"
SlashCmdList["CHARACTERSTATSDISPLAY"] = function(msg)
    local command = msg:lower()
    command = command:gsub("^%s*(.-)%s*$", "%1")

    if command == "show" then
        CharacterStatsDisplay:Show()
        print("角色属性显示已开启")
    elseif command == "hide" then
        CharacterStatsDisplay:Hide()
        print("角色属性显示已隐藏")
    elseif command == "reset" then
        CharacterStatsDisplay:ClearAllPoints()
        CharacterStatsDisplay:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 20)
        CharacterStatsDisplayDB.point = "BOTTOMLEFT"
        CharacterStatsDisplayDB.relativePoint = "BOTTOMLEFT"
        CharacterStatsDisplayDB.xOfs = 20
        CharacterStatsDisplayDB.yOfs = 20
        print("角色属性显示位置已重置")
    elseif command == "update" then
        lastItemLevelUpdate = 0
        lastGreenStatsUpdate = 0
        lastPrimaryStatUpdate = 0
        lastSpeedUpdate = 0
        UpdateAllStats()
        print("属性已手动更新")
    elseif command == "config" or command == "settings" or command == "" then
        CreateSettingsFrame()
    else
        print("角色属性显示插件命令：")
        print("/csd - 打开设置界面")
        print("/csd show - 显示属性面板")
        print("/csd hide - 隐藏属性面板")
        print("/csd reset - 重置位置到左下角")
        print("/csd update - 手动更新属性")
    end
end

InitDB()
ApplyDisplaySettings()
CreateStatTexts()

print("角色属性显示插件已加载 - 输入 /csd 打开设置")
