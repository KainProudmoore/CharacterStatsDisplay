local addonName, addon = ...

-- 默认配置
local defaults = {
    point = "BOTTOMLEFT",
    relativePoint = "BOTTOMLEFT",
    xOfs = 20,
    yOfs = 20,
    locked = false,
    showLeech = false,
    showParry = false,
    showDodge = false,
    showBlock = false,
}

-- 初始化数据库
local function InitDB()
    if not CharacterStatsDisplayDB then
        CharacterStatsDisplayDB = {}
    end
    for k, v in pairs(defaults) do
        if CharacterStatsDisplayDB[k] == nil then
            CharacterStatsDisplayDB[k] = v
        end
    end
end

-- 创建主框体
local CharacterStatsDisplay = CreateFrame("Frame", "CharacterStatsDisplayFrame", UIParent, "BackdropTemplate")
addon.frame = CharacterStatsDisplay
CharacterStatsDisplay:SetFrameStrata("HIGH")

-- 框体尺寸设置 - 调整后的值
local FRAME_WIDTH = 130
local LEFT_PADDING = 12
local RIGHT_PADDING = 4
local TOP_PADDING = 10
local BOTTOM_PADDING = 8
local FONT_HEIGHT = 14
local LINE_SPACING = 7  -- 字体高度的一半
local LINE_HEIGHT = FONT_HEIGHT + LINE_SPACING
local TITLE_HEIGHT = 20

-- 获取当前需要显示的属性数量
local function GetVisibleStatCount()
    local count = 7 -- 装等 + 主属性 + 4个绿字 + 移速
    if CharacterStatsDisplayDB.showLeech then count = count + 1 end
    if CharacterStatsDisplayDB.showParry then count = count + 1 end
    if CharacterStatsDisplayDB.showDodge then count = count + 1 end
    if CharacterStatsDisplayDB.showBlock then count = count + 1 end
    return count
end

-- 更新框体大小
local function UpdateFrameSize()
    local statCount = GetVisibleStatCount()
    local height = TITLE_HEIGHT + (statCount * LINE_HEIGHT) + TOP_PADDING + BOTTOM_PADDING
    CharacterStatsDisplay:SetSize(FRAME_WIDTH, height)
end

-- 初始化框体位置和大小
InitDB()
UpdateFrameSize()
CharacterStatsDisplay:SetPoint(CharacterStatsDisplayDB.point, UIParent, CharacterStatsDisplayDB.relativePoint, CharacterStatsDisplayDB.xOfs, CharacterStatsDisplayDB.yOfs)

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

-- 拖动相关
CharacterStatsDisplay:SetScript("OnDragStart", function(self)
    if not CharacterStatsDisplayDB.locked then
        self:StartMoving()
    end
end)

CharacterStatsDisplay:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- 保存位置
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    CharacterStatsDisplayDB.point = point
    CharacterStatsDisplayDB.relativePoint = relativePoint
    CharacterStatsDisplayDB.xOfs = xOfs
    CharacterStatsDisplayDB.yOfs = yOfs
end)

-- 标题 - 使用更大的字体
CharacterStatsDisplay.title = CharacterStatsDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
CharacterStatsDisplay.title:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", LEFT_PADDING, -TOP_PADDING)
CharacterStatsDisplay.title:SetText("角色属性")

CharacterStatsDisplay.stats = {}

-- 属性定义 - 按魔兽世界默认顺序：暴击、急速、精通、全能
-- 颜色：暴击(红)、急速(绿)、精通(冰蓝)、全能(橙黄)
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

-- 检查是否应该跳过这个属性
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

-- 当前属性值缓存
local currentStats = {}

-- 创建属性文本
local function CreateStatTexts()
    -- 清除旧的
    for _, statText in pairs(CharacterStatsDisplay.stats) do
        statText:Hide()
    end
    CharacterStatsDisplay.stats = {}
    
    -- 清除缓存，因为文本对象被重新创建了
    currentStats = {}
    
    local currentY = -(TOP_PADDING + TITLE_HEIGHT)
    
    for _, statInfo in ipairs(statNames) do
        -- 跳过可选属性如果未启用
        if not ShouldSkipStat(statInfo) then
            local statText = CharacterStatsDisplay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            statText:SetPoint("TOPLEFT", CharacterStatsDisplay, "TOPLEFT", LEFT_PADDING, currentY)
            statText:SetJustifyH("LEFT")
            statText:SetText(statInfo.color .. statInfo.label .. ": |r--")
            CharacterStatsDisplay.stats[statInfo.key] = statText
            
            currentY = currentY - LINE_HEIGHT
        end
    end
    
    UpdateFrameSize()
end

CreateStatTexts()

-- 获取玩家装等
local function GetPlayerItemLevel()
    local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()
    return avgItemLevelEquipped and string.format("%.1f", avgItemLevelEquipped) or "--"
end

-- 获取玩家主属性
local function GetPlayerPrimaryStat()
    local spec = GetSpecialization()
    if not spec then return "--", "主属性" end
    
    local statValue = 0
    local statName = ""
    
    -- 获取主属性类型
    local primaryStat = UnitStat("player", 1) -- 力量
    local agility = UnitStat("player", 2)     -- 敏捷
    local intellect = UnitStat("player", 4)   -- 智力
    
    -- 根据职业判断主属性
    local _, class = UnitClass("player")
    
    if class == "WARRIOR" or class == "PALADIN" or class == "DEATHKNIGHT" then
        statValue = primaryStat
        statName = "力量"
    elseif class == "HUNTER" or class == "ROGUE" or class == "DEMONHUNTER" or class == "MONK" then
        statValue = agility
        statName = "敏捷"
    elseif class == "MAGE" or class == "PRIEST" or class == "WARLOCK" then
        statValue = intellect
        statName = "智力"
    elseif class == "DRUID" or class == "SHAMAN" then
        if spec == 1 then
            statValue = intellect
            statName = "智力"
        elseif spec == 3 then
            statValue = agility
            statName = "敏捷"
        else
            statValue = intellect
            statName = "智力"
        end
    elseif class == "EVOKER" then
        statValue = intellect
        statName = "智力"
    else
        statValue = primaryStat
        statName = "力量"
    end
    
    return statValue, statName
end

-- 获取玩家暴击
local function GetPlayerCrit()
    local crit = GetCritChance()
    return crit and string.format("%.1f%%", crit) or "--"
end

-- 获取玩家急速
local function GetPlayerHaste()
    local haste = GetHaste()
    return haste and string.format("%.1f%%", haste) or "--"
end

-- 获取玩家精通
local function GetPlayerMastery()
    local mastery = GetMasteryEffect()
    return mastery and string.format("%.1f%%", mastery) or "--"
end

-- 获取玩家全能
local function GetPlayerVersatility()
    local versatility = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
    return versatility and string.format("%.1f%%", versatility) or "--"
end

-- 获取玩家吸血
local function GetPlayerLeech()
    local leech = GetLifesteal()
    return leech and string.format("%.1f%%", leech) or "--"
end

-- 获取玩家招架
local function GetPlayerParry()
    local parry = GetParryChance()
    return parry and string.format("%.1f%%", parry) or "--"
end

-- 获取玩家闪避
local function GetPlayerDodge()
    local dodge = GetDodgeChance()
    return dodge and string.format("%.1f%%", dodge) or "--"
end

-- 获取玩家格挡
local function GetPlayerBlock()
    local block = GetBlockChance()
    return block and string.format("%.1f%%", block) or "--"
end

-- 获取玩家移速
local function GetPlayerSpeed()
    local speed = GetUnitSpeed("player")
    if speed and speed > 0 then
        speed = speed / 7 * 100
        return string.format("%.0f%%", speed)
    end
    return "--"
end

-- 更新单个属性
local function UpdateStat(key, value, color, label)
    if currentStats[key] ~= value then
        currentStats[key] = value
        if CharacterStatsDisplay.stats[key] then
            CharacterStatsDisplay.stats[key]:SetText(color .. label .. ": |r" .. value)
        end
    end
end

-- 更新计时器
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
    
    -- 按顺序更新：暴击、急速、精通、全能
    UpdateStat("crit", GetPlayerCrit(), "|cFFFF0000", "暴击")
    UpdateStat("haste", GetPlayerHaste(), "|cFF00FF00", "急速")
    UpdateStat("mastery", GetPlayerMastery(), "|cFF00FFFF", "精通")
    UpdateStat("versatility", GetPlayerVersatility(), "|cFFFFA500", "全能")
    
    -- 可选属性
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

-- 战斗状态处理
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

-- 事件处理
CharacterStatsDisplay:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- 重新初始化数据库（确保SavedVariables已加载）
        InitDB()
        -- 重新创建属性文本（根据已保存的设置）
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

-- 定时更新
C_Timer.NewTicker(3, function()
    if not isInCombat then
        UpdateGreenStats()
        UpdatePrimaryStat()
    end
    UpdateItemLevel()
end)

C_Timer.NewTicker(0.5, UpdateSpeed)

-- ==================== 设置界面 ====================
local SettingsFrame = nil
local checkboxes = {} -- 存储复选框引用

local function CreateSettingsFrame()
    -- 如果窗口已存在，先销毁旧的
    if SettingsFrame then
        SettingsFrame:Hide()
        SettingsFrame:SetParent(nil)
        SettingsFrame = nil
        checkboxes = {}
    end
    
    -- 创建设置窗口
    SettingsFrame = CreateFrame("Frame", "CharacterStatsDisplaySettings", UIParent, "BasicFrameTemplateWithInset")
    SettingsFrame:SetSize(300, 350)
    SettingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    SettingsFrame:SetMovable(true)
    SettingsFrame:EnableMouse(true)
    SettingsFrame:RegisterForDrag("LeftButton")
    SettingsFrame:SetScript("OnDragStart", SettingsFrame.StartMoving)
    SettingsFrame:SetScript("OnDragStop", SettingsFrame.StopMovingOrSizing)
    SettingsFrame:SetFrameStrata("DIALOG")
    
    SettingsFrame.TitleBg:SetHeight(30)
    SettingsFrame.title = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    SettingsFrame.title:SetPoint("TOP", SettingsFrame.TitleBg, "TOP", 0, -8)
    SettingsFrame.title:SetText("角色属性显示 - 设置")
    
    local content = CreateFrame("Frame", nil, SettingsFrame)
    content:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 10, -35)
    content:SetPoint("BOTTOMRIGHT", SettingsFrame, "BOTTOMRIGHT", -10, 10)
    
    local yOffset = -10
    
    -- 标题：框体移动
    local moveTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    moveTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
    moveTitle:SetText("框体移动")
    yOffset = yOffset - 25
    
    -- 锁定/解锁按钮
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
    
    -- 标题：额外属性
    local statTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    statTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
    statTitle:SetText("额外属性显示")
    yOffset = yOffset - 25
    
    -- 创建复选框函数
    local function CreateCheckbox(parent, label, key, y)
        local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
        checkbox:SetSize(24, 24)
        
        local text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        text:SetText(label)
        
        -- 从数据库读取状态
        local isChecked = CharacterStatsDisplayDB[key]
        checkbox:SetChecked(isChecked)
        
        -- 存储引用以便后续更新
        checkboxes[key] = checkbox
        
        checkbox:SetScript("OnClick", function(self)
            local checked = self:GetChecked()
            CharacterStatsDisplayDB[key] = checked
            -- 重置所有更新时间戳，强制刷新
            lastItemLevelUpdate = 0
            lastPrimaryStatUpdate = 0
            lastGreenStatsUpdate = 0
            lastSpeedUpdate = 0
            CreateStatTexts()
            UpdateAllStats()
        end)
        
        return y - 28
    end
    
    -- 吸血
    yOffset = CreateCheckbox(content, "显示吸血", "showLeech", yOffset)
    -- 招架
    yOffset = CreateCheckbox(content, "显示招架", "showParry", yOffset)
    -- 闪避
    yOffset = CreateCheckbox(content, "显示闪避", "showDodge", yOffset)
    -- 格挡
    yOffset = CreateCheckbox(content, "显示格挡", "showBlock", yOffset)
    
    yOffset = yOffset - 20
    
    -- 重置位置按钮
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
    
    -- 关闭按钮
    local closeButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 25)
    closeButton:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    closeButton:SetText("关闭")
    closeButton:SetScript("OnClick", function()
        SettingsFrame:Hide()
    end)
    
    SettingsFrame:Show()
end

-- 聊天命令
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
        print("角色属性显示插件命令:")
        print("/csd - 打开设置界面")
        print("/csd show - 显示属性面板")
        print("/csd hide - 隐藏属性面板")
        print("/csd reset - 重置位置到左下角")
        print("/csd update - 手动更新属性")
    end
end

print("角色属性显示插件已加载 - 输入 /csd 打开设置")
