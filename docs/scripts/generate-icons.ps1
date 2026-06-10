# 生成 PWA 图标（1x1 PNG 占位，可替换为设计稿）
$dir = Join-Path $PSScriptRoot "..\icons"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
$bytes = [Convert]::FromBase64String($b64)
foreach ($size in @(192, 512)) {
  [IO.File]::WriteAllBytes((Join-Path $dir "icon-$size.png"), $bytes)
}
Write-Host "Icons written to $dir (replace with real 192/512 PNGs for production)"
