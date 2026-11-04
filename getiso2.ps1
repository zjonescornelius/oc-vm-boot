$u = 'https://raw.githubusercontent.com/zjonescornelius/oc-vm-boot/main/oc-boot.iso'
$dir = 'E:\hackintosh\VM\'
$total = 61526016
$chunk = 1048576
$n = [Math]::Ceiling($total / $chunk)
$names = @()
$fail = 0
for ($i = 0; $i -lt $n; $i++) {
    $s = $i * $chunk
    $e = [Math]::Min($s + $chunk - 1, $total - 1)
    $want = $e - $s + 1
    $out = $dir + 'p' + $i
    $ok = $false
    for ($t = 0; $t -lt 6; $t++) {
        & curl.exe -sS --max-time 150 -r "$s-$e" -o $out $u 2>$null
        if ((Test-Path $out) -and ((Get-Item $out).Length -eq $want)) { $ok = $true; break }
        Start-Sleep -Milliseconds 400
    }
    if (-not $ok) { $fail++ ; Write-Output ($i.ToString() + ' FAIL') } else { Write-Output ($i.ToString() + ' ok ' + $want) }
    $names += $out
}
Write-Output ('fail=' + $fail)
if ($fail -eq 0) {
    $concat = ($names -join '+')
    cmd /c ('copy /b ' + $concat + ' ' + $dir + 'oc-boot.iso') | Out-Null
    Write-Output ('final=' + (Get-Item ($dir + 'oc-boot.iso')).Length)
}
