# TLDR;

To use WSL effectively in a corporate environment with a VPN solution that actively monitors and alters Windows Route Tables to maintain corporate compliance you can:

1. Clone this repo
2. Open a powershell window as your normal user to the repo working directory and execute the following command
```
.\Install-WslVpnKit.ps1
```
3. Close that powershell window and open a powershell window as an administrator to the repo working directory and execute the following command
```
.\Install-DeterministicNetwork.ps1
```

These commands will install two scheduled tasks that are executed at startup. The deterministic network task resets the WSL virtual switch/adapter to a 192.168.39.0/24 network by default. The particular network can be specified when installing the Install-DeterministicNetwork using arguments detailed further in the instructions, if you need to customize that network range.

The WslVpnKit task executes the following WSL command at startup (with a 2 minute delay following startup) "``` wsl.exe -d wsl-vpnkit --cd /app service wsl-vpnkit start ```" so that the wsl-vpn WSL distro is up and running before any additional WSL distros are used. If don't want it running persistently, you can follow the instructions at the [wsl-vpn links](#wsl-vpn-links) below for executing it on-demand or adding it to your bash profile when launching another distro. Having it run at startup means that WSL will continue to function whenever a VPN is connected (or disconnected)*

*Remember that when connecting the VPN, proxy settings need to be updated to match the corporate proxy requirements.

# Additional Details and Links to Further Information
This repo provides a working solution that solves two WSL problems when WSL is used in a corporate environment with a VPN. The first issue is that WSL doesn't use a deterministic method to generate the network range used by WSL. This results in potential collisions with corporate network ranges.

Additionally, some VPN solutions, including Pulse Secure, can be configured to actively monitor the Windows Route table and override routes of any networks it considers to be different or external to a computer and the corporate network. This means that regardless of the range chosen

See additional information below for even more detail. Additionally, the WSL VPN Kit parts of this solution were adapted from:<a name="wsl-vpn-links"></a>
https://github.com/AmmarRahman/wsl-vpn

https://github.com/sakai135/wsl-vpnkit


# Original Description of solution before 

Normally, Hyper-V/WSL uses a collision-avoidance algorithm when assigning private
network ranges to the virtual networks that it creates for use by these services.
This is fine for many use cases, but remote and roaming users on corporate networks
may find this behavior unacceptable as the network that Windows thought was
non-conflicting at system startup may become conflicting when you later start a VPN
connection to your business network.  The result is that your WSL or Hyper-V instances
may lose outbound connectivity and bring your development work to a halt.

This script allows you to specify a deterministic network range and gatweway to use
for WSL.  The network will be re-created on each startup to ensure
continuity. _NOTE:_ WSL is the primary use case for this tool.  Hyper-V support is
_experimental_ and not yet reliable.

This repository contains the script `Install-DeterministicNetwork.ps1`, which will create
a scheduled task to register your preferred deterministic network ranges each time you
login to Windows, and the script `Register-DeterministicNetwork.ps1`, which can be run
on-demand.

- [WSL2 Network Fix for Linux Developers](#wsl2-network-fix-for-linux-developers)
  - [Credit Where It Is Due](#credit-where-it-is-due)
  - [Alternatives](#alternatives)
  - [Prerequisites](#prerequisites)
  - [Usage](#usage)
  - [Background information](#background-information)
    - [Hyper-V?  WSL?  What do I do with these?](#hyper-v--wsl--what-do-i-do-with-these)
    - [Great! So what is the problem?](#great-so-what-is-the-problem)
    - [So what can I do about that?  Get a Mac?](#so-what-can-i-do-about-that--get-a-mac)

## Credit Where It Is Due

This solution really is just a PowerShell wrapper around HNS Network handline code
that was developed by others.

It is built most directly off the work of Sami Korhonen:  
<https://github.com/skorhone/wsl2-custom-network>

Sami's code builds off of the HNS PowerShell module by "nwoodmsft" and "keithmange":  
<https://www.powershellgallery.com/packages/HNS/>

Sami cites Biswa96's (Biswaprio Nath) code sample here as the inspiration for his work:  
<https://github.com/microsoft/WSL/discussions/7395>

Good work all in sorting out Microsoft's undocumented HNS network API!

## Alternatives

A rather nice-looking and solution by [@wikiped](https://github.com/wikiped) can be found here:  
<https://github.com/wikiped/WSL-IpHandler>  
(This approach "does more", which is great if you need the additional functionality.  I
just want a simple and reliable mechanism for keeping the WSL network in a range of
my choosing.)

## Prerequisites

- You must have "Administrator" privileges on your system to run this script
- This script tested only on Windows 10 21H1 and 11 21H2 with PowerShell 5 and 7.1.

## Usage

1. Start by cloning this repository, or downloading its contents to your system.  You need the _entire_
repository contents, not just the Install-DeveloperFix.ps1 script.
2. Decide on a network range and gateway address for your new network, or use the defaults in this script.
3. Open a PowerShell prompt in the directory with the script and run the following commands:

    ```powershell
    # This script is not signed, so you need to set ExecutionPolicy to "RemoteSigned" or
    # "Unrestricted" to run it, if you have not already done so.
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted

    # (If you download the code bundle from GitHub instead of cloning the repo, you may
    # need to "unblock" the scripts):
    Get-ChildItem -Include *.ps1,*.psm1 -Recurse | Unblock-File -Confirm:$false

    # Then just run the script.  The parameters are optional and will default to:
    # WSL, 192.168.100.1, and 192.168.100.0/24, respectively.
    .\Install-DeterministicNetwork.ps1 [-NetworkType [ WSL | Hyper-V ]] [-GatewayAddress "IP_ADDRESS" ] [-NetworkAddress "NetworkAddressCIDR"]

    # (Optionally, you can revert to your original Execution Policy after the installation.)
    Set-ExecutionPolicy -ExecutionPolicy Restricted
    # Note: ExecutionPolicies are not true security boundaries.  Most "serious" PowerShell
    # users will find that leaving the execution policy set to "Restricted" is impractcal at best.
    ```

Help is available though the usual PowerShell syntax:

```powershell
# Simple Help:
.\Install-DeterministicNetwork.ps1 -?
or
Get-Help .\Install-DeterministicNetwork.ps1

# Detailed Help:
Get-Help .\Install-DeterministicNetwork.ps1 -detailed

# Full Help:
Get-Help .\Install-DeterministicNetwork.ps1 -full
```

## Background information

### Hyper-V?  WSL?  What do I do with these?

Linux developers who choose (or are forced) to use Windows will benefit greatly
from the use the the Windows Subsystem for Linux, and the Hyper-V virtualization
engine.  These are powerful tools that enable developers (and other IT pros
such as systems administrators and analysts) to run Linux operating systems, tools, and
containers quickly and efficiently, while still having access to the broad base of
Windows productivity tools.

### Great! So what is the problem?

Unfortunately, these tools often run into problems with corporate use of
private network ranges, especially when the developer using the system roams
between remote and on-site work, or needs a VPN connection.

The comes from Hyper-V selecting private network ranges for internal use based
on the networks that it can "see" when the system starts up.  If the private networks
in use change after startup, there may be a network collision.  Networking inside
the Hyper-V and WSL VMs then fail, and sometimes general networking on the host
Windows system deteriorates as well.  Microsoft does not appear to be interested in
fixing this common problem.

### So what can I do about that?  Get a Mac?

Sure, you could get a Mac, or install Ubuntu.  You also could use an alternative Linux
run environment such as "Oracle VirtualBox", or VMware Workstation.  OR... you can just
run the "Install-DeterministicNetwork.ps1" script in this repository, and your life will be good again.*

This tool will pre-create the "HNSNetwork" that WSL or Hyper-V network that Windows would create
automatically, but using deterministic network ranges provided by you so that you don't get
rando address ranges that create problems with your corporate network.

*Ongoing life goodness not guaranteed.
