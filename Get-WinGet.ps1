param(
    [switch]$Help,
    [switch]$User,
    [switch]$Machine,
    [switch]$Version
)

$ProgressPreference = "SilentlyContinue"

$scriptName = "$($MyInvocation.MyCommand.Name)"
$scriptVersion = "1.2.0"

$wingetVer = "1.9.25200"
$wingetLicenseHash = "7fdfd40ea2dc40deab85b69983e1d873"
$wingetDepsURI = "https://github.com/microsoft/winget-cli/releases/download/v${wingetVer}/DesktopAppInstaller_Dependencies.zip"
$wingetURI = "https://github.com/microsoft/winget-cli/releases/download/v${wingetVer}/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$wingetLicenseURI = "https://github.com/microsoft/winget-cli/releases/download/v${wingetVer}/${wingetLicenseHash}_License1.xml"
$wingetDepsFileName = "DesktopAppInstaller_Dependencies.zip"
$wingetDepsExtractedDir = "DesktopAppInstaller_Dependencies"
$wingetFileName = "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$wingetLicenseFileName = "License1.xml"

$downloadDir = "${env:TEMP}\get-winget"
$currentUser = $env:USERNAME

function Show-Help {
    Write-Host "${scriptName}: Install WinGet and its dependencies for User scope or Machine scope"
    Write-Host "  -User        Install for User"
    Write-Host "  -Machine     Install for Machine"
    Write-Host "  -Help        Print this help"
    Write-Host "  -Version     Print script version ($scriptVersion)"
}

function Show-Version {
    Write-Host "${scriptName}: Version $scriptVersion"
}

function Get-Files {
    if ((Test-Path -Path $downloadDir) -eq $false) {
        New-Item -Path "${env:TEMP}" -Name "get-winget" -ItemType "directory" | Out-Null
    }

    $retryCounter = 0

    $downloadedFiles = @(
        "$downloadDir\$wingetDepsFileName",
        "$downloadDir\$wingetFileName",
        "$downloadDir\$wingetLicenseFileName"
    )

    while ($true) {
        Write-Host "Downloading WinGet Dependencies"
        Invoke-WebRequest -Uri $wingetDepsURI -OutFile $downloadDir\$wingetDepsFileName

        Write-Host "Downloading WinGet"
        Invoke-WebRequest -Uri $wingetURI -OutFile $downloadDir\$wingetFileName
        Invoke-WebRequest -Uri $wingetLicenseURI -OutFile $downloadDir\$wingetLicenseFileName

        if ((Test-Path -Path $downloadedFiles) -contains $false) {
            $retryCounter++
            if ($retryCounter -eq 3) {
                Write-Host "Download attempts exceeded 3 retries, exiting."
                Exit 1
            }
            Write-Host "There was a problem downloading one or more files, retrying..."
        } else {
            Break
        }
    }
}

function Remove-Files {
    Remove-Item -Force -Recurse -Path $downloadDir
}

function Install-CurrentUser {
    Get-Files

    Expand-Archive -Path $downloadDir\$wingetDepsFileName -DestinationPath $downloadDir\$wingetDepsExtractedDir

    $pkg = (Resolve-Path "$downloadDir\$wingetDepsExtractedDir\x64\Microsoft.VCLibs*.appx").Path
    Write-Host "Installing WinGet Dependencies for the current user ($currentUser)"
    Start-Job -Name AddVCLibsUserJob -ScriptBlock {
        Add-AppxPackage $using:pkg
    } | Out-Null
    Wait-Job -Name AddVCLibsUserJob | Out-Null

    $pkg = (Resolve-Path "$downloadDir\$wingetDepsExtractedDir\x64\Microsoft.UI.Xaml*.appx").Path
    Start-Job -Name AddXamlUserJob -ScriptBlock {
        Add-AppxPackage $using:pkg
    } | Out-Null
    Wait-Job -Name AddXamlUserJob | Out-Null

    $pkg = "$downloadDir\$wingetFileName"
    Write-Host "Installing WinGet for the current user ($currentUser)"
    Start-Job -Name AddWinGetUserJob -ScriptBlock {
        Add-AppxPackage $using:pkg
    } | Out-Null
    Wait-Job -Name AddWinGetUserJob | Out-Null
}

function Install-Machine {
    Get-Files

    Expand-Archive -Path $downloadDir\$wingetDepsFileName -DestinationPath $downloadDir\$wingetDepsExtractedDir

    $pkg = (Resolve-Path "$downloadDir\$wingetDepsExtractedDir\x64\Microsoft.VCLibs*.appx").Path
    Write-Host "Installing WinGet Dependencies for the machine"
    Start-Job -Name AddVCLibsMachineJob -ScriptBlock {
        Add-AppxProvisionedPackage -Online -PackagePath $using:pkg -SkipLicense
    } | Out-Null
    Wait-Job -Name AddVCLibsMachineJob | Out-Null

    $pkg = (Resolve-Path "$downloadDir\$wingetDepsExtractedDir\x64\Microsoft.UI.Xaml*.appx").Path
    Start-Job -Name AddXamlMachineJob -ScriptBlock {
        Add-AppxProvisionedPackage -Online -PackagePath $using:pkg -SkipLicense
    } | Out-Null
    Wait-Job -Name AddXamlMachineJob | Out-Null

    $pkg = "$downloadDir\$wingetFileName"
    $lic = "$downloadDir\$wingetLicenseFileName"
    Write-Host "Installing WinGet for the machine"
    Start-Job -Name AddWinGetMachineJob -ScriptBlock {
        Add-AppxProvisionedPackage -Online -PackagePath $using:pkg -License $using:lic
    } | Out-Null
    Wait-Job -Name AddWinGetMachineJob | Out-Null
}

function Test-WinGet {
    Start-Sleep 3
    winget *>$null
    if ($? -eq $false) {
        Write-Host "WinGet did not install properly. Please check logs in Event Viewer:"
        Write-Host "  Event Viewer > Applications and Services > Microsoft > Windows >"
        Write-Host "    AppXDeployment-Server > Microsoft-Windows-AppXDeploymentServer/Operational"
        Exit 1
    } else {
        Write-Host "WinGet successfully installed. Please update WinGet with:"
        Write-Host "  winget source update"
        Write-Host "  winget update --all"
    }
}

if ($User -and $Machine) {
    Write-Host "You cannot choose both -User and -Machine`r`n"
    Show-Help
    Exit 1
} elseif ($Help) {
    Show-Help
    Exit
} elseif ($Version) {
    Show-Version
    Exit
} elseif ($User) {
    Install-CurrentUser
} elseif ($Machine) {
    Install-Machine
} else {
    Show-Help
    Exit 1
}

Remove-Files
Test-WinGet
$ProgressPreference = "Continue"
Exit