$vmx = 'E:\hackintosh\VM\macOS-Ventura.vmx'
$vm = 'E:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe'
& $vm stop $vmx hard 2>&1 | Out-Null
Start-Sleep -Seconds 3
$c = Get-Content $vmx
if (-not ($c | Select-String 'sata0:2.present')) {
    $c += 'sata0:2.present = "TRUE"'
    $c += 'sata0:2.deviceType = "cdrom-image"'
    $c += 'sata0:2.fileName = "oc-boot.iso"'
    $c += 'sata0:2.startConnected = "TRUE"'
}
Set-Content $vmx $c -Encoding UTF8
Write-Output '--- devices ---'
Get-Content $vmx | Select-String 'sata0:'
Write-Output '--- starting ---'
& $vm start $vmx gui
Write-Output ('exit=' + $LASTEXITCODE)
Start-Sleep -Seconds 35
Write-Output '--- log tail ---'
Get-Content 'E:\hackintosh\VM\vmware.log' -Tail 5
