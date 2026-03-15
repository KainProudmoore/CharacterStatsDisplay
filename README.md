# CharacterStatsDisplay 角色属性显示插件

魔兽世界插件，在游戏界面上实时显示角色属性。

## 目录结构

```
CharacterStatsDisplay/
├── CharacterStatsDisplay.toc    # 插件清单文件
├── Core.lua                     # 插件核心代码
├── docs/                        # 文档目录
│   ├── CHANGELOG.md            # 更新日志
│   ├── CONTEXT_SUMMARY.md      # 项目上下文总结
│   └── DESIGN.md               # 设计文档
├── tools/                       # 工具脚本目录
│   ├── deploy.bat              # Windows部署脚本
│   ├── deploy.ps1              # PowerShell部署脚本
│   └── deploy-simple.bat       # 简化版部署脚本
├── .trae/                       # Trae IDE配置（自动生成）
└── .vscode/                     # VS Code配置（自动生成）
```

## 快速开始

### 安装插件

**方式一：使用部署脚本**
```bash
# 运行 PowerShell 脚本
.\tools\deploy.ps1

# 或运行批处理脚本
.\tools\deploy.bat
```

**方式二：手动复制**
将以下文件复制到游戏插件目录：
```
World of Warcraft\_retail_\Interface\AddOns\CharacterStatsDisplay\
├── CharacterStatsDisplay.toc
└── Core.lua
```

### 使用插件

- 插件会自动在屏幕左下角显示角色属性
- 输入 `/csd` 打开设置界面
- 可以勾选显示额外属性（吸血、招架、闪避、格挡）
- 可以解锁/锁定框体位置

## 功能特性

- ✅ 装等显示（黄色）
- ✅ 主属性显示（自动识别力量/敏捷/智力）
- ✅ 绿字属性（暴击→急速→精通→全能，按WoW默认顺序）
- ✅ 移速显示
- ✅ 额外属性（吸血/招架/闪避/格挡，可选显示）
- ✅ 设置界面（/csd命令）
- ✅ 框体位置可拖动
- ✅ 数据自动保存
- ✅ 属性提升提示（数值变绿色）

## 版本信息

- **当前版本**: v2.1.0
- **游戏版本**: WoW 11.0+ (The War Within)
- **接口版本**: 120000

## 文档

- [更新日志](docs/CHANGELOG.md)
- [设计文档](docs/DESIGN.md)
- [项目上下文](docs/CONTEXT_SUMMARY.md)

## GitHub

https://github.com/KainProudmoore/CharacterStatsDisplay
