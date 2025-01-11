param(
    [switch]$Help,
    [switch]$User,
    [switch]$Machine,
    [switch]$Version
)

$scriptName = "$($MyInvocation.MyCommand.Name)"
$scriptVersion = "1.0.0"

$vclibsURI = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
$vclibsFileName = "Microsoft.VCLibs.appx"

$xamlVer = "2.8.6"
$xamlVerMajMin = ($xamlVer[0..2]) -join "" # Maj.Min
$xamlURI = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v${xamlVer}/Microsoft.UI.Xaml.${xamlVerMajMin}.x64.appx"
$xamlFileName = "Microsoft.UI.Xaml.appx"

$wingetVer = "1.8.1911"
$wingetURI = "https://github.com/microsoft/winget-cli/releases/download/v${wingetVer}/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$wingetLicenseURI = "https://github.com/microsoft/winget-cli/releases/download/v${wingetVer}/76fba573f02545629706ab99170237bc_License1.xml"
# cannot use newest version because i cannot find the updated
# version of vclibs. just update winget after it is installed
#$wingetVer = "1.9.25200"
#$wingetURI = "https://github.com/microsoft/winget-cli/releases/download/v${wingetVer}/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
#$wingetLicenseURI = "https://github.com/microsoft/winget-cli/releases/download/v${wingetVer}/7fdfd40ea2dc40deab85b69983e1d873_License1.xml"
$wingetFileName = "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$wingetLicenseFileName = "License1.xml"

$downloadDir = $env:TEMP

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
    # we need to do this because winget takes forever to download otherwise
    $ProgressPreference = "SilentlyContinue"

    $retryCounter = 0

    $downloadedFiles = @(
        "$downloadDir\$vclibsFileName",
        "$downloadDir\$xamlFileName",
        "$downloadDir\$wingetFileName",
        "$downloadDir\$wingetLicenseFileName"
    )

    while ($true) {
        Write-Host "Downloading Microsoft VCLibs"
        Invoke-WebRequest -Uri $vclibsURI -OutFile $downloadDir\$vclibsFileName

        Write-Host "Downloading Microsoft UI Xaml"
        Invoke-WebRequest -Uri $xamlURI -OutFile $downloadDir\$xamlFileName

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

    # restore progress bar
    $ProgressPreference = "Continue"
}

function Remove-Files {
    Remove-Item -Path `
        $downloadDir\$vclibsFileName,
        $downloadDir\$xamlFileName,
        $downloadDir\$wingetFileName,
        $downloadDir\$wingetLicenseFileName
}

function Install-CurrentUser {
    Get-Files

    $pkg = "$downloadDir\$vclibsFileName"
    Write-Host "Installing Microsoft VCLibs for the current user (${env:UserName})"
    Start-Job -Name AddVCLibsUserJob -ScriptBlock {
        Add-AppxPackage $using:pkg
    } | Out-Null
    Wait-Job -Name AddVCLibsUserJob | Out-Null

    $pkg = "$downloadDir\$xamlFileName"
    Write-Host "Installing Microsoft UI Xaml for the current user (${env:UserName})"
    Start-Job -Name AddXamlUserJob -ScriptBlock {
        Add-AppxPackage $using:pkg
    } | Out-Null
    Wait-Job -Name AddXamlUserJob | Out-Null

    $pkg = "$downloadDir\$wingetFileName"
    Write-Host "Installing WinGet for the current user (${env:UserName})"
    Start-Job -Name AddWinGetUserJob -ScriptBlock {
        Add-AppxPackage $using:pkg
    } | Out-Null
    Wait-Job -Name AddWinGetUserJob | Out-Null
}

function Install-Machine {
    Get-Files

    $pkg = "$downloadDir\$vclibsFileName"
    Write-Host "Installing Microsoft VCLibs for the machine"
    Start-Job -Name AddVCLibsMachineJob -ScriptBlock {
        Add-AppxProvisionedPackage -Online -PackagePath $using:pkg -SkipLicense
    } | Out-Null
    Wait-Job -Name AddVCLibsMachineJob | Out-Null

    $pkg = "$downloadDir\$xamlFileName"
    Write-Host "Installing Microsoft UI Xaml for the machine"
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
        Write-Host '  winget source update'
        Write-Host '  winget update --all'
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
Exit