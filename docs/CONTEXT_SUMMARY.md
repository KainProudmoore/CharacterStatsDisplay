# CharacterStatsDisplay 插件开发上下文总结

> 生成时间: 2026-03-15
> 用途: 新对话窗口快速理解项目背景

---

## 一、项目背景

### 1.1 项目概述
- **项目名称**: CharacterStatsDisplay（角色属性显示）
- **类型**: 魔兽世界（WoW）插件
- **功能**: 在游戏界面上实时显示角色属性（装等、主属性、绿字、移速等）
- **开发状态**: v2.0.1 已推送到 develop 分支

### 1.2 仓库信息
- **GitHub**: https://github.com/KainProudmoore/CharacterStatsDisplay
- **本地路径**: `E:\Files\Repo\CharacterStatsDisplay`
- **游戏路径**: `E:\Game\BLZ\World of Warcraft\_retail_\Interface\AddOns\CharacterStatsDisplay`
- **当前分支**: develop
- **主分支**: main

---

## 二、已实现功能（v2.0.1）

### 2.1 核心功能
| 功能 | 状态 | 说明 |
|------|------|------|
| 装等显示 | ✅ | 黄色，显示小数 |
| 主属性显示 | ✅ | 自动识别职业（力量/敏捷/智力） |
| 绿字属性 | ✅ | 暴击→急速→精通→全能（WoW默认顺序） |
| 移速显示 | ✅ | 实时更新 |
| 额外属性 | ✅ | 吸血/招架/闪避/格挡（可选，默认隐藏） |
| 设置界面 | ✅ | /csd 命令打开 |
| 框体移动 | ✅ | 解锁/锁定功能 |
| 数据持久化 | ✅ | 位置和设置自动保存 |

### 2.2 UI 调整（v2.0.1）
- 框体宽度: 130px（紧凑）
- 左边距: 12px
- 右边距: 4px
- 行间距: 7px（字体高度的一半）
- 标题字体: GameFontNormalLarge

### 2.3 未实现/移除功能
- ❌ 属性数值颜色变化（增加绿色/减少红色）- 因稳定性问题移除

---

## 三、代码结构

### 3.1 文件清单
```
CharacterStatsDisplay/
├── CharacterStatsDisplay.toc    # 插件清单文件
├── Core.lua                     # 插件核心代码
├── README.md                    # 项目说明文档
├── docs/                        # 文档目录
│   ├── CHANGELOG.md            # 更新日志
│   ├── CONTEXT_SUMMARY.md      # 项目上下文总结
│   └── DESIGN.md               # 设计文档
├── tools/                       # 工具脚本目录
│   ├── deploy.bat              # Windows部署脚本
│   ├── deploy.ps1              # PowerShell部署脚本
│   └── deploy-simple.bat       # 简化版部署脚本
├── .trae/                       # Trae IDE配置（自动生成，不提交）
└── .vscode/                     # VS Code配置（自动生成，不提交）
```

### 3.2 核心代码结构（Core.lua）
```lua
-- 1. 配置和初始化
- defaults（默认配置）
- InitDB()（数据库初始化）

-- 2. UI创建
- CharacterStatsDisplay（主框体）
- CreateStatTexts()（创建属性文本）
- UpdateFrameSize()（更新框体大小）

-- 3. 数据获取
- GetPlayerItemLevel()（装等）
- GetPlayerPrimaryStat()（主属性）
- GetPlayerCrit/Haste/Mastery/Versatility()（绿字）
- GetPlayerSpeed()（移速）

-- 4. 更新逻辑
- UpdateStat()（更新单个属性）
- UpdateAllStats()（更新所有属性）
- 定时器（战斗/非战斗不同频率）

-- 5. 事件处理
- PLAYER_LOGIN（登录初始化）
- PLAYER_EQUIPMENT_CHANGED（装备更换）
- PLAYER_REGEN_DISABLED/ENABLED（战斗状态）

-- 6. 设置界面
- CreateSettingsFrame()（创建设置窗口）
- 复选框（吸血/招架/闪避/格挡）
- 锁定/解锁按钮

-- 7. 聊天命令
- /csd（打开设置）
- /csd show/hide/reset/update
```

---

## 四、重要技术细节

### 4.1 数据库（SavedVariables）
```lua
CharacterStatsDisplayDB = {
    point = "BOTTOMLEFT",      -- 锚点
    relativePoint = "BOTTOMLEFT",
    xOfs = 20, yOfs = 20,      -- 位置偏移
    locked = false,            -- 是否锁定
    showLeech = false,         -- 显示吸血
    showParry = false,         -- 显示招架
    showDodge = false,         -- 显示闪避
    showBlock = false,         -- 显示格挡
}
```

### 4.2 属性颜色定义
```lua
装等:     |cFFFFFF00（黄色）
主属性:   |cFFFFFFFF（白色）
暴击:     |cFFFF0000（红色）
急速:     |cFF00FF00（绿色）
精通:     |cFF00FFFF（青色）
全能:     |cFFFFA500（橙色）
吸血:     |cFF00FF00（绿色）
招架/闪避/格挡: |cFFFFFFFF（白色）
移速:     |cFFFFFFFF（白色）
```

### 4.3 更新频率
| 状态 | 绿字属性 | 主属性 | 装等 | 移速 |
|------|---------|--------|------|------|
| 非战斗 | 3秒 | 3秒 | 3秒 | 0.5秒 |
| 战斗中 | 0.5秒 | 0.5秒 | 3秒 | 0.5秒 |

---

## 五、已知问题和注意事项

### 5.1 已修复问题
- ✅ 属性显示 "--" 问题（缓存清理）
- ✅ 勾选额外属性后数据不更新问题
- ✅ 设置界面复选框状态不保存问题
- ✅ 框体高度计算问题

### 5.2 当前限制
- 颜色变化功能已移除（增加绿色/减少红色）
- 需要重新登录才能完全重置某些状态

### 5.3 开发注意事项
- `CreateStatTexts()` 会重新创建所有文本对象
- `currentStats` 缓存需要在重建时清空
- 数据库在 `PLAYER_LOGIN` 时才完全加载

---

## 六、Git 工作流

### 6.1 分支策略
- **main**: 稳定版本（v1.0.0）
- **develop**: 开发版本（v2.0.1，当前）

### 6.2 提交历史
```
3d9e9b9 - Update v2.0.1: UI adjustments and bug fixes
0f3b4a2 - Release v2.0.0: Major update with new features
d429767 - Initial commit
```

### 6.3 合并方式
通过 GitHub Pull Request 将 develop 合并到 main：
1. 访问 https://github.com/KainProudmoore/CharacterStatsDisplay
2. Pull requests → New pull request
3. base: main ← compare: develop
4. Create pull request → Merge pull request

---

## 七、部署说明

### 7.1 手动部署
将以下文件复制到游戏目录：
```
E:\Game\BLZ\World of Warcraft\_retail_\Interface\AddOns\CharacterStatsDisplay\
├── CharacterStatsDisplay.toc
└── Core.lua
```

### 7.2 自动部署
运行项目根目录的部署脚本：
- `deploy.bat`（Windows）
- `deploy.ps1`（PowerShell）

---

## 八、后续开发建议

### 8.1 待实现功能（优先级）
1. **属性变化颜色提示**（高优先级）
   - 增加时绿色闪烁
   - 减少时红色闪烁
   - 需要稳定的实现方案

2. **更多自定义选项**（中优先级）
   - 字体大小调整
   - 背景透明度
   - 边框样式

3. **性能优化**（低优先级）
   - 减少更新频率
   - 优化事件监听

### 8.2 代码改进方向
- 将颜色变化功能做成可选模块
- 添加更多错误处理
- 优化框体尺寸计算

---

## 九、关键代码片段

### 9.1 创建属性文本
```lua
local function CreateStatTexts()
    -- 清除旧的
    for _, statText in pairs(CharacterStatsDisplay.stats) do
        statText:Hide()
    end
    CharacterStatsDisplay.stats = {}
    
    -- 清除缓存
    currentStats = {}
    
    local currentY = -(TOP_PADDING + TITLE_HEIGHT)
    
    for _, statInfo in ipairs(statNames) do
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
```

### 9.2 更新属性
```lua
local function UpdateStat(key, value, color, label)
    if currentStats[key] ~= value then
        currentStats[key] = value
        if CharacterStatsDisplay.stats[key] then
            CharacterStatsDisplay.stats[key]:SetText(color .. label .. ": |r" .. value)
        end
    end
end
```

---

## 十、联系信息

- **开发者**: KainProudmoore
- **仓库**: https://github.com/KainProudmoore/CharacterStatsDisplay
- **游戏版本**: WoW 11.0+ (The War Within)
- **接口版本**: 120000

---

**文档结束**

如有疑问，请查看 DESIGN.md 和 CHANGELOG.md 获取更详细信息。
