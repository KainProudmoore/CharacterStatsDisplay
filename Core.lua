local addonName, addon = ...

local CharacterStatsDisplay = CreateFrame("Frame", "CharacterStatsDisplayFrame", UIParent, "BackdropTemplate")
addon.frame = CharacterStatsDisplay

CharacterStatsDisplay:SetSize(200, 150)
CharacterStatsDisplay:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 20)
CharacterStatsDisplay:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
CharacterStatsDisplay:SetBackdropColor(0, 0, 0, 0.8)
CharacterStatsDisplay:SetMovable(true)
CharacterStatsDisplay:EnableMouse(true)
CharacterStatsDisplay:RegisterForDrag("LeftButton")
CharacterStatsDisplay:SetScript("OnDragStart", CharacterStatsDisplay.StartMoving)
CharacterStatsDisplay:SetScript("OnDragStop", CharacterStatsDisplay.StopMovingOrSizing)

CharacterStatsDisplay.title = CharacterStatsDisplay:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
CharacterStatsDisplay.title:SetPoint("TOP", CharacterStatsDisplay, "TOP", 0, -8)
CharacterStatsDisplay.title:SetText("角色属性")

CharacterStatsDisplay.stats = {}

local statNames = {
    { key = "itemLevel", label = "装等", color = "|cFFFFFF00" },
    { key = "haste", label = "急速", color = "|cFF00FF00" },
    { key = "crit", label = "暴击", color = "|cFFFF0000" },
    { key = "mastery", label = "精通", color = "|cFF00FFFF" },
    { key = "versatility", label = "全能", color = "|cFFFFA500" },
    { key = "speed", label = "移速", color = "|cFFFFFFFF" }
}

for i, statInfo in ipairs(statNames) do
    local statText = CharacterStatsDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statText:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", 15, -30 - (i - 1) * 18)
    statText:SetText(statInfo.color .. statInfo.label .. ": |r--")
    CharacterStatsDisplay.stats[statInfo.key] = statText
end

local currentStats = {
    itemLevel = "",
    haste = "",
    crit = "",
    mastery = "",
    versatility = "",
    speed = ""
}

local isInCombat = false
local combatUpdateTicker = nil

local function GetPlayerItemLevel()
    local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()
    return avgItemLevelEquipped and string.format("%.1f", avgItemLevelEquipped) or "--"
end

local function GetPlayerHaste()
    local haste = GetHaste()
    return haste and string.format("%.1f%%", haste) or "--"
end

local function GetPlayerCrit()
    local crit = GetCritChance()
    return crit and string.format("%.1f%%", crit) or "--"
end

local function GetPlayerMastery()
    local mastery = GetMasteryEffect()
    return mastery and string.format("%.1f%%", mastery) or "--"
end

local function GetPlayerVersatility()
    local versatility = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
    return versatility and string.format("%.1f%%", versatility) or "--"
end

local function GetPlayerSpeed()
    local speed = GetUnitSpeed("player")
    if speed and speed > 0 then
        speed = speed / 7 * 100
        return string.format("%.0f%%", speed)
    end
    return "--"
end

local function UpdateStat(key, value, index)
    if currentStats[key] ~= value then
        currentStats[key] = value
        CharacterStatsDisplay.stats[key]:SetText(statNames[index].color .. statNames[index].label .. ": |r" .. value)
    end
end

local lastGreenStatsUpdate = 0
local function UpdateGreenStats()
    local now = GetTime()
    local interval = isInCombat and 0.5 or 3
    if now - lastGreenStatsUpdate < interval then
        return
    end
    lastGreenStatsUpdate = now
    
    UpdateStat("haste", GetPlayerHaste(), 2)
    UpdateStat("crit", GetPlayerCrit(), 3)
    UpdateStat("mastery", GetPlayerMastery(), 4)
    UpdateStat("versatility", GetPlayerVersatility(), 5)
end

local lastItemLevelUpdate = 0
local function UpdateItemLevel()
    local now = GetTime()
    if now - lastItemLevelUpdate < 3 then
        return
    end
    lastItemLevelUpdate = now
    
    UpdateStat("itemLevel", GetPlayerItemLevel(), 1)
end

local lastSpeedUpdate = 0
local function UpdateSpeed()
    local now = GetTime()
    if now - lastSpeedUpdate < 0.5 then
        return
    end
    lastSpeedUpdate = now
    
    UpdateStat("speed", GetPlayerSpeed(), 6)
end

local function UpdateAllStats()
    UpdateItemLevel()
    UpdateGreenStats()
    UpdateSpeed()
end

local function StartCombatUpdates()
    if combatUpdateTicker then
        combatUpdateTicker:Cancel()
    end
    combatUpdateTicker = C_Timer.NewTicker(0.5, function()
        UpdateGreenStats()
        UpdateSpeed()
    end)
end

local function StopCombatUpdates()
    if combatUpdateTicker then
        combatUpdateTicker:Cancel()
        combatUpdateTicker = nil
    end
end

CharacterStatsDisplay:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        UpdateAllStats()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        lastItemLevelUpdate = 0
        lastGreenStatsUpdate = 0
        UpdateAllStats()
    elseif event == "PLAYER_REGEN_DISABLED" then
        isInCombat = true
        lastGreenStatsUpdate = 0
        StartCombatUpdates()
    elseif event == "PLAYER_REGEN_ENABLED" then
        isInCombat = false
        StopCombatUpdates()
    end
end)

CharacterStatsDisplay:RegisterEvent("PLAYER_LOGIN")
CharacterStatsDisplay:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
CharacterStatsDisplay:RegisterEvent("PLAYER_REGEN_DISABLED")
CharacterStatsDisplay:RegisterEvent("PLAYER_REGEN_ENABLED")

C_Timer.NewTicker(3, function()
    if not isInCombat then
        UpdateGreenStats()
    end
    UpdateItemLevel()
end)

C_Timer.NewTicker(0.5, UpdateSpeed)

SLASH_CHARACTERSTATSDISPLAY1 = "/csd"
SlashCmdList["CHARACTERSTATSDISPLAY"] = function(msg)
    local command = msg:lower()
    if command == "show" then
        CharacterStatsDisplay:Show()
        print("角色属性显示已开启")
    elseif command == "hide" then
        CharacterStatsDisplay:Hide()
        print("角色属性显示已隐藏")
    elseif command == "reset" then
        CharacterStatsDisplay:ClearAllPoints()
        CharacterStatsDisplay:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 20, 20)
        print("角色属性显示位置已重置")
    elseif command == "update" then
        lastItemLevelUpdate = 0
        lastGreenStatsUpdate = 0
        lastSpeedUpdate = 0
        UpdateAllStats()
        print("属性已手动更新")
    else
        print("角色属性显示插件命令:")
        print("/csd show - 显示属性面板")
        print("/csd hide - 隐藏属性面板")
        print("/csd reset - 重置位置到左下角")
        print("/csd update - 手动更新属性")
    end
end

print("角色属性显示插件已加载 - 输入 /csd 查看命令")
