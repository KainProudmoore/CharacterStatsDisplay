---
name: "wow-addon-deploy"
description: "部署 WoW 插件到游戏目录。当用户说'部署插件'、'同步到游戏'、'发布插件'、'deploy addon'或类似命令时调用此技能。"
---

# WoW 插件部署技能

## 触发条件
当用户发出以下任一指令时调用此技能：
- "部署插件"
- "同步到游戏"
- "发布插件"
- "deploy addon"
- "deploy"
- "同步插件"
- "更新游戏插件"

## 执行步骤

1. **确认当前工作目录** - 确保在 `E:\Files\Repo\CharacterStatsDisplay`

2. **执行部署脚本** - 运行项目根目录下的 `deploy.bat` 批处理文件：
   ```
   .\deploy.bat
   ```
   
   或者使用 PowerShell 绕过执行策略：
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File .\deploy.ps1
   ```

3. **报告结果** - 向用户显示部署成功或失败的信息

## 部署详情

- **源目录**: `E:\Files\Repo\CharacterStatsDisplay`
- **目标目录**: `E:\Game\BLZ\World of Warcraft\_retail_\Interface\AddOns\CharacterStatsDisplay`
- **操作**: 完全替换目标目录下的插件文件

## 注意事项

- 部署前会自动删除旧版本插件
- 脚本会验证游戏目录是否存在
- 部署完成后会显示复制的文件数量
