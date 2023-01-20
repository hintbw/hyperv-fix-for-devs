<#
.SYNOPSIS
    Installation Script for the WSL2 VPN Kit Fix for Developers

.DESCRIPTION
    Linux developers who choose (or are forced) to use Windows will benefit greatly
    from the use the the Windows Subsystem for Linux, and the Hyper-V virtualization
    engine.  Unfortunately, these tools often run into problems with corporate use of
    private network ranges, especially when the developer using the system roams
    between remote and on-site work, or needs a VPN connection.

    The problem is that WSL and Hyper-V select private network ranges for internal use
    based on the networks that it can "see" when the system starts up.  If the private
    networks in use change after startup, there may be a network collision.  Networking
    inside the Hyper-V and WSL VMs then fail, and sometimes general networking on the
    host Windows system deteriorates as well.  Microsoft does not appear to be
    interested in fixing this common problem.

    This particular part of the solution allows us to use VPNKit so that aggressive VPN
    solutions that intercept routes to any network adapters (like the WSL virtual switch)
    can now be communicated with effectively.

.EXAMPLE
    PS> .\Install-WslVpnKit.ps1

.LINK
    https://github.com/jgregmac/hyperv-fix-for-devs
#>
[CmdletBinding()]


# Establish current path and logging:
$CurrentPath = Split-Path  $script:MyInvocation.MyCommand.Path -Parent
Import-Module (Join-Path -Path $CurrentPath -ChildPath "\scripts\OutConsoleAndLog.psm1") -ea Stop
$global:GlobalLog = (Join-Path -Path $CurrentPath -ChildPath "Install-WslVpnKit.log")
if (Test-Path $GlobalLog) { Remove-Item -Path $GlobalLog -Force -Confirm:$false }

Out-ConsoleAndLog "Starting installation of the WSL VPN Kit fix." 
Out-ConsoleAndLog "These messages will be logged to: $GlobalLog" 

# The installer will create the tasks to run under the account of the user running this
# installer script.  You could force installation for a specific user by changing these
# variables, but the target user /has to/ have a working WSL instance to launch at login.
# This scenario has not been tested, so it will remain a "constant" in the script for now.
# Both the user name (in DomainName\UserName) and SID are required:
$UserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$UserSID = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
Out-ConsoleAndLog "Generated Tasks will be run as $UserName with SID: $UserSID"

#region Create Scheduled Tasks
    $TaskSource = Join-Path -Path $CurrentPath -ChildPath tasks
    $TaskStage = Join-Path -Path $env:TEMP -ChildPath "$NetworkType-tasks"
    Out-ConsoleAndLog "Staging task definitions to: $TaskStage"
    if (-not (Test-Path $TaskStage)) {
        Out-ConsoleAndLog "Creating staging directory: '$TaskStage'..."
        New-Item -ItemType Directory -Path $TaskStage -Force -ea Stop | Out-Null
    }
    # Read the content of our scheduled task templates from the source,
    # Update the templates with local user data, and write to the $env:temp directory.
    Out-ConsoleAndLog "Updating the staged task definitions:"
    Get-ChildItem -Path $TaskSource | ForEach-Object {
        #Write-Host ("Working on source file: " + $_.FullName);
        $Leaf = $_.Name;
        Get-Content $_.FullName |
            ForEach-Object { $_ -replace "USER_ID", $UserName } |
            ForEach-Object { $_ -replace "USER_SID", $UserSID } |
            Set-Content -Path (Join-Path -Path $TaskStage -ChildPath $Leaf) -Force -Confirm:$false -ea Stop;
    }
    # Register the login actions task
    Out-ConsoleAndLog "Registering the WSL VPN Kit startup/login task..."
    $SourceFile = Join-Path -Path $TaskStage -ChildPath wsl-vpnkit-start.xml -Resolve
    Register-ScheduledTask -Xml (Get-Content $SourceFile | Out-String) `
        -TaskName "WSL - Start WSL VPN Kit on Startup - after delay" -Force -ea Stop | Out-Null
    # Remove-Item -Recurse -Path $TaskStage -Force
#endregion

Out-ConsoleAndLog "All done. WSL VPN Kit Startup Script has been installed."