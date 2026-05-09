$files = @(
    @{path="main.tex"; name="main.tex"}
)

# 添加 data 目录下的所有 .tex 文件
Get-ChildItem -Path "data" -Filter "*.tex" -Recurse | ForEach-Object {
    $files += @{path=$_.FullName; name=$_.FullName.Replace((Get-Location).Path + "\", "")}
}

$totalChinese = 0
$totalEnglish = 0
$totalChars = 0

Write-Host "开始统计字数...`n"

# 处理每个文件
foreach ($file in $files) {
    try {
        $content = Get-Content -Path $file.path -Raw -Encoding UTF8
        
        # 移除注释行
        $content = $content -replace '%.*', ''
        
        # 移除LaTeX命令
        $content = $content -replace '\\[a-zA-Z]+\{[^}]*\}', ''
        $content = $content -replace '\\[a-zA-Z]+\[[^\]]*\]\{[^}]*\}', ''
        $content = $content -replace '\\[a-zA-Z]+', ''
        
        # 移除数学公式
        $content = $content -replace '\$\$[\s\S]*?\$\$', ''
        $content = $content -replace '\$[\s\S]*?\$', ''
        $content = $content -replace '\\\[[\s\S]*?\\\]', ''
        
        # 移除括号
        $content = $content -replace '[{}[\]]', ''
        
        # 计算中文字符数（汉字范围U+4E00到U+9FFF）
        $chineseChars = [regex]::Matches($content, '[\u4e00-\u9fff]')
        $chinese = $chineseChars.Count
        
        # 计算英文和数字
        $englishChars = [regex]::Matches($content, '[a-zA-Z0-9]')
        $english = $englishChars.Count
        
        $subtotal = $chinese + $english
        
        if ($subtotal -gt 0) {
            Write-Host "$($file.name)"
            Write-Host "  中文: $chinese 字，英文/数字: $english 个，小计: $subtotal"
            $totalChinese += $chinese
            $totalEnglish += $english
            $totalChars += $subtotal
        }
    } catch {
        Write-Host "处理 $($file.path) 时出错: $_"
    }
}

Write-Host ""
Write-Host "============================================================"
Write-Host "总计字数统计结果:"
Write-Host "  中文字数（含标题、摘要等）: $totalChinese"
Write-Host "  英文字母和数字: $totalEnglish"
Write-Host "  合计字数: $totalChars"
Write-Host "============================================================"
Write-Host ""
Write-Host "注："
Write-Host "- 中文按每个汉字计数"
Write-Host "- 英文字母和数字每个计数一次"
Write-Host "- 不包括LaTeX命令、公式等标记"
