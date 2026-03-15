# 角色属性显示插件 - 修改日志

## 版本 1.0.3 - 战斗状态感知更新（绿字属性高频支持）

### 优化目标
解决战斗中buff频繁改变绿字属性时的实时显示需求

### 核心问题
- **非战斗状态**：绿字属性稳定，低频更新即可
- **战斗状态**：触发类buff、饰品效果、技能增益等会频繁改变绿字属性，需要高频更新才能准确反映

### 优化方案：战斗状态感知系统

#### 1. 动态频率调整
根据战斗状态自动切换更新频率：

| 状态 | 绿字属性更新周期 | 原因 |
|------|------------------|------|
| **战斗中** | **0.5秒** | buff频繁触发，需要实时反映属性变化 |
| **非战斗** | 3秒 | 属性稳定，低频更新节省资源 |

#### 2. 战斗事件监听
```lua
-- 进入战斗
PLAYER_REGEN_DISABLED → 启动高频更新(0.5秒)

-- 脱离战斗  
PLAYER_REGEN_ENABLED → 恢复低频更新(3秒)
```

#### 3. 智能定时器管理
```lua
local function StartCombatUpdates()
    combatUpdateTicker = C_Timer.NewTicker(0.5, function()
        UpdateGreenStats()  -- 绿字属性
        UpdateSpeed()       -- 移速
    end)
end

local function StopCombatUpdates()
    if combatUpdateTicker then
        combatUpdateTicker:Cancel()
    end
end
```

#### 4. 分层更新架构
```lua
-- 移速：始终0.5秒（与战斗无关）
C_Timer.NewTicker(0.5, UpdateSpeed)

-- 绿字属性：根据战斗状态动态调整
-- 战斗中：0.5秒，非战斗：3秒

-- 装等：始终3秒（变化频率极低）
```

### 性能优化策略

1. **脏检查机制**：属性值未变化时不重绘UI
2. **按需启动**：只在战斗中启动高频定时器
3. **及时释放**：脱离战斗后立即停止高频定时器
4. **节流控制**：每次更新间隔强制限制，防止过度调用

### 更新策略对比

| 场景 | 版本1.0.2 | 版本1.0.3 |
|------|-----------|-----------|
| 非战斗绿字更新 | 3秒 | 3秒 |
| **战斗绿字更新** | **3秒** | **0.5秒** ✓ |
| 移速更新 | 0.5秒 | 0.5秒 |
| 战斗中CPU占用 | 低 | 中等（仅战斗中） |
| 非战斗CPU占用 | 低 | 极低 |

### 技术亮点

1. **状态感知**：自动识别战斗/非战斗状态
2. **动态调度**：根据场景自动调整更新策略
3. **资源优化**：高频更新仅在需要时启用
4. **无缝切换**：战斗开始/结束瞬间切换频率

---

## 版本 1.0.2 - 性能优化（高频更新支持）

### 优化目标
在保持游戏流畅的前提下，实现1秒以内的高频属性更新

### 优化方案

#### 1. 属性分级更新策略
不同属性的变化频率不同，采用差异化的更新周期：

| 属性类型 | 更新周期 | 原因 |
|----------|----------|------|
| 移速 | 0.5秒 | 移动时实时变化，需要高频更新 |
| 装等/急速/暴击/精通/全能 | 3秒 | 变化频率低，低频更新即可 |

#### 2. 脏检查机制（Dirty Check）
引入属性缓存系统，只在属性值真正变化时才更新UI：
```lua
local currentStats = {
    itemLevel = "",
    haste = "",
    crit = "",
    mastery = "",
    versatility = "",
    speed = ""
}

local function UpdateStat(key, value, index)
    if currentStats[key] ~= value then  -- 脏检查
        currentStats[key] = value
        CharacterStatsDisplay.stats[key]:SetText(...)
    end
end
```

**优势**：
- 避免无意义的UI重绘
- 减少CPU和GPU负载
- 即使检查频率高，实际更新次数很少

#### 3. 双定时器架构
分离不同频率的更新任务：
```lua
-- 高频：移速更新（0.5秒）
C_Timer.NewTicker(0.5, UpdateSpeed)

-- 低频：其他属性更新（3秒）
C_Timer.NewTicker(3, UpdateSlowStats)
```

### 性能对比

| 指标 | 版本1.0.0 | 版本1.0.1 | 版本1.0.2 |
|------|-----------|-----------|-----------|
| 更新周期 | 1秒（全部） | 3秒（全部） | 0.5秒（移速）+ 3秒（其他） |
| 实际UI更新次数 | 每秒6次 | 每3秒最多6次 | 视变化情况而定 |
| 卡顿情况 | 严重卡顿 | 无卡顿 | 无卡顿 |
| 移速响应性 | 实时 | 延迟3秒 | 延迟0.5秒 |

### 技术亮点

1. **智能节流**：高频检查 + 低频实际更新
2. **按需渲染**：只有数据变化才重绘UI
3. **资源隔离**：移速单独更新，不影响其他属性

---

## 版本 1.0.1 - Bug修复

### 修复的问题

#### 1. 属性显示问题 [已修复]
**问题描述**：除装等外，其他属性（急速、暴击、精通、全能、移速）都显示为"--"

**根本原因**：函数名与魔兽世界API函数名冲突
- 原代码中定义了 `GetHaste()` 函数，但函数内部调用 `GetHaste()` 时，Lua会优先使用局部变量而非全局API
- 同样的冲突存在于 `GetCrit()` 等函数

**修复方案**：将所有获取属性的函数重命名，添加"Player"前缀
- `GetHaste()` → `GetPlayerHaste()`
- `GetCrit()` → `GetPlayerCrit()`
- `GetMastery()` → `GetPlayerMastery()`
- `GetVersatility()` → `GetPlayerVersatility()`
- `GetSpeed()` → `GetPlayerSpeed()`
- `GetItemLevel()` → `GetPlayerItemLevel()`

#### 2. 游戏卡顿问题 [已修复]
**问题描述**：安装插件后游戏画面一秒一卡

**根本原因**：
1. 使用了 `C_Timer.NewTicker(1, UpdateStats)` 每秒更新一次，频率过高
2. 注册了 `UNIT_STATS` 和 `UNIT_AURA` 事件，这两个事件触发极其频繁（每秒可能触发数十次）
3. 每次事件触发都会调用 `UpdateStats()`，造成大量不必要的计算

**修复方案**：
1. **降低定时器频率**：将 `C_Timer.NewTicker(1, UpdateStats)` 改为 `C_Timer.NewTicker(3, UpdateStats)`，每3秒更新一次
2. **移除高频事件**：取消注册 `UNIT_STATS` 和 `UNIT_AURA` 事件
3. **添加节流机制**：在 `UpdateStats()` 函数中添加2秒冷却时间，防止短时间内重复更新
4. **保留必要事件**：只保留 `PLAYER_LOGIN`（登录时初始化）和 `PLAYER_EQUIPMENT_CHANGED`（装备更换时更新）

### 新增功能
- 添加 `/csd update` 命令，允许玩家手动刷新属性显示

### 文件变更
- `Core.lua` - 修复属性获取函数名冲突，优化更新机制
