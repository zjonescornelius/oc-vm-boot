$vmx = 'E:\hackintosh\VM\macOS-Ventura.vmx'
$vm = 'E:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe'
$dir = 'E:\hackintosh\VM\'

Write-Output '--- stop vm ---'
& $vm stop $vmx hard 2>&1 | Out-Null
Start-Sleep -Seconds 4

Write-Output '--- restore vmx devices ---'
$lines = Get-Content $vmx
$out = @()
foreach ($l in $lines) {
    if ($l -like 'sata0:0.fileName*') { $out += 'sata0:0.fileName = "macOS-Ventura.vmdk"' }
    elseif ($l -like 'sata0:1.*') { continue }
    elseif ($l -like 'sata0:2.*') { continue }
    elseif ($l -like 'bios.bootOrder*') { continue }
    elseif ($l -like 'bios.bootDelay*') { continue }
    else { $out += $l }
}
Set-Content $vmx $out -Encoding UTF8
Get-Content $vmx | Select-String 'sata0:' | ForEach-Object { $_.Line }

Write-Output '--- delete intermediate files ---'
$del = @('oc-disk-flat.img','oc-disk.vmdk','oc-boot.iso','part00','part01','part02','part03','p0',
         'template.gz','inject.json','inject.py','fix.ps1','getiso.ps1','getiso2.ps1','boot_iso.ps1',
         'repo.tgz','shot.png','efiboot.img')
$freed = 0
foreach ($f in $del) {
    $p = $dir + $f
    if (Test-Path $p) {
        $sz = (Get-Item $p).Length
        Remove-Item $p -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path $p)) { $freed += $sz; Write-Output ('deleted ' + $f + ' ' + $sz) }
        else { Write-Output ('FAILED ' + $f) }
    }
}
Write-Output ('freed_bytes=' + $freed)

Write-Output '--- remaining in VM dir ---'
Get-ChildItem $dir -File | Sort-Object Length -Descending | Select-Object -First 8 | ForEach-Object { $_.Name + ' ' + $_.Length }

Write-Output '--- probe old iso files ---'
foreach ($f in @('E:\hackintosh\Ventura.iso','E:\hackintosh\Ventura13.iso')) {
    if (Test-Path $f) {
        $fi = Get-Item $f
        $fs = [IO.File]::OpenRead($f)
        $b0 = New-Object byte[] 16; [void]$fs.Read($b0, 0, 16)
        $fs.Position = 510; $sig = New-Object byte[] 2; [void]$fs.Read($sig, 0, 2)
        $fs.Position = 32768; $udf = New-Object byte[] 8; [void]$fs.Read($udf, 0, 8)
        $fs.Close()
        $h0 = ($b0 | ForEach-Object { $_.ToString('x2') }) -join ''
        $h1 = ($sig | ForEach-Object { $_.ToString('x2') }) -join ''
        $h2 = -join ($udf | ForEach-Object { if ($_ -ge 32 -and $_ -le 126) { [char]$_ } else { '.' } })
        Write-Output ($fi.Name + ' size=' + $fi.Length + ' head=' + $h0 + ' sig510=' + $h1 + ' @32k=' + $h2)
    } else {
        Write-Output ($f + ' NOT FOUND')
    }
}
