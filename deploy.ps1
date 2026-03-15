# WoW 插件部署脚本
# 将 CharacterStatsDisplay 插件复制到游戏目录

$sourceDir = "E:\Files\Repo\CharacterStatsDisplay"
$targetDir = "E:\Game\BLZ\World of Warcraft\_retail_\Interface\AddOns\CharacterStatsDisplay"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CharacterStatsDisplay 插件部署工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查源目录是否存在
if (-not (Test-Path $sourceDir)) {
    Write-Host "错误: 源目录不存在: $sourceDir" -ForegroundColor Red
    exit 1
}

# 检查游戏目录是否存在
$wowAddOnsDir = "E:\Game\BLZ\World of Warcraft\_retail_\Interface\AddOns"
if (-not (Test-Path $wowAddOnsDir)) {
    Write-Host "错误: WoW 插件目录不存在: $wowAddOnsDir" -ForegroundColor Red
    Write-Host "请检查游戏路径是否正确" -ForegroundColor Yellow
    exit 1
}

# 如果目标目录存在，先删除
if (Test-Path $targetDir) {
    Write-Host "正在删除旧版本插件..." -ForegroundColor Yellow
    Remove-Item -Path $targetDir -Recurse -Force
    Write-Host "旧版本已删除" -ForegroundColor Green
}

# 复制新文件
Write-Host "正在复制插件文件到游戏目录..." -ForegroundColor Yellow
Copy-Item -Path $sourceDir -Destination $targetDir -Recurse -Force

# 验证复制结果
if (Test-Path $targetDir) {
    $fileCount = (Get-ChildItem -Path $targetDir -Recurse -File).Count
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  部署成功!" -ForegroundColor Green
    Write-Host "  已复制 $fileCount 个文件" -ForegroundColor Green
    Write-Host "  目标路径: $targetDir" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host "错误: 部署失败，目标目录未创建" -ForegroundColor Red
    exit 1
}
