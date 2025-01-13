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

## One liner
Copy and paste this into powershell if you don't want to bother with downloading and running the script manually.

Install for the current user:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; Invoke-WebRequest -Uri https://raw.githubusercontent.com/776d/get-winget/main/Get-WinGet.ps1 -OutFile ${env:TEMP}\Get-WinGet.ps1; try { & "${env:TEMP}\Get-WinGet.ps1" -User } catch { "Get-WinGet failed." } finally { Get-ChildItem -Path $env:TEMP -Include @("Get-WinGet.ps1","get-winget") -Recurse | Remove-Item -Force }
```

Install for the machine:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; Invoke-WebRequest -Uri https://raw.githubusercontent.com/776d/get-winget/main/Get-WinGet.ps1 -OutFile ${env:TEMP}\Get-WinGet.ps1; try { & "${env:TEMP}\Get-WinGet.ps1" -Machine } catch { "Get-WinGet failed." } finally { Get-ChildItem -Path $env:TEMP -Include @("Get-WinGet.ps1","get-winget") -Recurse | Remove-Item -Force }
```