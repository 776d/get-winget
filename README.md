# get-winget

Get-WinGet is a Powershell script that downloads and installs WinGet and its dependencies in the scope of the current user or the machine.

## Pre-requisites
You will need to change the execution policy so that you can actually run this script. Do this by running:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

> [!NOTE]
> You can learn more about Powershell's execution policies [here](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)

## Install for the current user
```powershell
.\Get-WinGet.ps1 -User
```

## Install for the machine
```powershell
.\Get-WinGet.ps1 -Machine
```

## Other switches
Display help:
```powershell
.\Get-WinGet.ps1 -Help
```

Display script version:
```powershell
.\Get-WinGet.ps1 -Version
```