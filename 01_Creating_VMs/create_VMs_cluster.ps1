# Create_OpenStack_Cluster.ps1

# First, configure the VirtualBox networking environment

# Define cluster nodes
$nodes = @(
    @{
        Name = "OS-controller"
        Hostname = "controller.localdomain"
        MemoryMB = 4096
        CPUCount = 1
        DiskSizeGB = 30
        IPAddress = "10.0.0.11"
    },
    @{
        Name = "OS-compute1"
        Hostname = "compute1.localdomain"
        MemoryMB = 8192
        CPUCount = 2
        DiskSizeGB = 40
        IPAddress = "10.0.0.31"
    },
    @{
        Name = "OS-storage1"
        Hostname = "storage1.localdomain"
        MemoryMB = 4096
        CPUCount = 1
        DiskSizeGB = 50
        IPAddress = "10.0.0.41"
    }
)

# Create each VM
foreach ($node in $nodes) {
    Write-Host "Creating $($node.Name) node..."
    & ".\Create_VM.ps1" `
        -vmName $node.Name `
        -hostname $node.Hostname `
        -memoryMB $node.MemoryMB `
        -cpuCount $node.CPUCount `
        -diskSizeGB $node.DiskSizeGB `
        -ipAddress $node.IPAddress

    Write-Host "$($node.Name) node created successfully!"
    Write-Host "Static IP configured: $($node.IPAddress)"
}

Write-Host "OpenStack cluster creation complete!"
