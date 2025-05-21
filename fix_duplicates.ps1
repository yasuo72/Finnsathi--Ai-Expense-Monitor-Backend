$filePath = "c:\Users\Rohit\apk\new_finn\finnsathi-fresh-\lib\services\enhanced_gamification_service.dart"
$content = Get-Content $filePath -Raw

# Replace _updateFinancialInsights with _refreshFinancialInsights in the Timer.periodic call
$content = $content -replace "await _updateFinancialInsights\(\);", "await _refreshFinancialInsights();"

# Find the second occurrence of _generatePersonalizedTips method and remove it
$pattern = "(?s)  // Generate personalized financial tips based on user data\r?\n  void _generatePersonalizedTips\(\) \{.*?\n  \}"
$matches = [regex]::Matches($content, $pattern)

if ($matches.Count -gt 1) {
    # Get the position of the second occurrence
    $secondMatchPos = $matches[1].Index
    $secondMatchLength = $matches[1].Length
    
    # Remove the second occurrence
    $content = $content.Substring(0, $secondMatchPos) + $content.Substring($secondMatchPos + $secondMatchLength)
}

# Save the modified content back to the file
Set-Content -Path $filePath -Value $content -NoNewline

Write-Host "File updated successfully!"
