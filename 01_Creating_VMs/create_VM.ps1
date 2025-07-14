# Create_OpenStack_VM.ps1
# use example: .\create_VM.ps1 -vmName VM1 -hostName VM1.localdomain -ipAddress "192.168.56.11"
param (
    [string]$vmName,
    [string]$hostname,
    [int]$memoryMB = 8192,
    [int]$cpuCount = 2,
    [int]$diskSizeGB = 50,
    [string]$ipAddress = $null
)

# Common parameters
$isoPath = "C:\Users\User\Downloads\ubuntu-22.04.5-live-server-amd64.iso"
$osType = "Ubuntu_64"
$username = "smoroz"
$password = "password"
$vmBasePath = "C:\Users\User\Documents\Cloud\VMs\"
$vmPath = Join-Path $vmBasePath $vmName
$diskPath = Join-Path $vmPath "$vmName.vdi"

# Create VM directory
if (!(Test-Path -Path $vmPath)) {
    New-Item -ItemType Directory -Path $vmPath | Out-Null
}

# Create the VM
Write-Host "Creating VM '$vmName'..."
VBoxManage createvm --name $vmName --ostype $osType --register --basefolder $vmBasePath

# --nic1 nat `                          # For internet access
# --nic2 hostonlyadapter `              # For internal communication
# --nictype2 82540EM `                  # Intel PRO/1000 MT Desktop
# --nic3 bridged `                      # Optional: for external access
# --bridgeadapter3 "Wi-Fi" `            # Change to your host network interface
# Configure system settings
VBoxManage modifyvm $vmName `
    --memory $memoryMB `
    --cpus $cpuCount `
    --nic1 nat `
    --natpf1 "ssh,tcp,,2222,,22" `
    --nic2 natnetwork `
    --nat-network2 "NatNetwork" `
    --nictype2 82540EM `
    --nic3 hostonly `
    --hostonlyadapter3 "VirtualBox Host-Only Ethernet Adapter" `
    --nictype3 82540EM `
    --audio-driver none `
    --graphicscontroller vmsvga `
    --vram 128 `
    --ioapic on `
    --firmware bios `
    --rtcuseutc on
#    --nic3 bridged `
#    --bridgeadapter3 "Intel(R) Wireless-AC 9560 160MHz" `
#    --nictype3 82540EM `

# Create and attach storage controllers
VBoxManage storagectl $vmName --name "IDE" --add ide --controller PIIX4 --bootable on
VBoxManage storagectl $vmName --name "SATA" --add sata --controller IntelAhci --portcount 2 --bootable on

# Create virtual disk
Write-Host "Creating virtual disk..."
VBoxManage createmedium disk --filename $diskPath --size ($diskSizeGB * 1024) --format VDI

# Attach virtual disk
VBoxManage storageattach $vmName `
    --storagectl "SATA" `
    --port 0 `
    --device 0 `
    --type hdd `
    --medium $diskPath

# Attach ISO
VBoxManage storageattach $vmName `
    --storagectl "IDE" `
    --port 0 `
    --device 0 `
    --type dvddrive `
    --medium $isoPath

# Set boot order
VBoxManage modifyvm $vmName --boot1 dvd --boot2 disk --boot3 none --boot4 none

# Configure unattended installation with static IP for host-only network if specified
$unattendedParams = @(
    "--iso=$isoPath",
    "--user=$username",
    "--password=$password",
    "--full-user-name=$username",
    "--install-additions",
    "--locale=en_US",
    "--country=US",
    "--time-zone=UTC",
    "--hostname=$hostname",
    "--post-install-command=`"shutdown -h now`"",
    "--image-index=1",
    "--language=en"
)

if ($ipAddress) {
    $unattendedParams += "--auxiliary-base-path=`"$vmPath`""
    $unattendedParams += "--start-vm=gui"

    # Create network config file for static IP
    $netConfigContent = @"
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: true
      optional: true
    enp0s8:
      dhcp4: false
      addresses: [$ipAddress/24]
      routes:
        - to: default
          via: 10.0.0.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
    enp0s9:
      dhcp4: false
      addresses: [192.168.56.11/24]
"@
    New-Item -Path (Join-Path $vmPath "network-config") -Value $netConfigContent -Force
} else {
    $unattendedParams += "--start-vm=gui"
}

VBoxManage unattended install $vmName @unattendedParams

Write-Host "VM '$vmName' created successfully!"
