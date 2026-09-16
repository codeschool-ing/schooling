---
title: The half of PowerShell this machine does not have
version: 1
---

Everything so far ran on the machine these transcripts were captured on. This
section is about what did not, and why — because the reason PowerShell exists is
administering Windows, and none of that is here.

```
PS /home/ana/work/ps> Get-Service
Get-Service: The term 'Get-Service' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
PS /home/ana/work/ps> Get-CimInstance Win32_OperatingSystem
Get-CimInstance: The term 'Get-CimInstance' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
PS /home/ana/work/ps> Get-ChildItem HKLM:\Software
Get-ChildItem: Cannot find drive. A drive with the name 'HKLM' does not exist.
```

**Those are the real errors.** The cmdlets are not hidden or disabled — they do
not exist, because the modules that contain them are not built for this platform.

```
PS /home/ana/work/ps> Get-Module -ListAvailable | Select-Object Name | Sort-Object Name
Name
----
Microsoft.PowerShell.Archive
Microsoft.PowerShell.Host
Microsoft.PowerShell.Management
Microsoft.PowerShell.PSResourceGet
Microsoft.PowerShell.Security
Microsoft.PowerShell.Utility
PackageManagement
PowerShellGet
PSReadLine
ThreadJob
```

Ten modules, 293 commands. A Windows Server has those plus dozens more, and the
count runs into the thousands once the server roles are installed.

**This is the honest scope of the lesson.** What follows is described, not
demonstrated, and you should treat it as a map rather than as a transcript.

## Services

```sh
Get-Service                                   # all of them
Get-Service -Name 'W3SVC' | Select Status
Get-Service | Where-Object Status -eq 'Stopped'
Restart-Service -Name 'Spooler'
Set-Service -Name 'Spooler' -StartupType Disabled
```

The shape is the same as everything you have seen: objects with a `Status`, a
`StartMode` and a `DisplayName`, filtered with `Where-Object`. This is
lesson 5 section 09's `systemctl` with the parsing removed — `systemctl is-active` gives
you a word to compare, `Get-Service` gives you a property.

## CIM and WMI — the machine as objects

```sh
Get-CimInstance Win32_OperatingSystem | Select Caption, LastBootUpTime
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select DeviceID, FreeSpace
Get-CimInstance Win32_Process | Where-Object Name -eq 'notepad.exe'
Get-CimInstance -ClassName Win32_BIOS -ComputerName web01
```

CIM is a catalogue of everything Windows knows about itself — hardware, disks,
network cards, installed software, the BIOS — exposed as classes with properties.

**There is no single Linux equivalent** because the information is spread across
`/proc`, `/sys`, `dmidecode`, `lsblk` and `ip`, each with its own output format.
Lesson 11 uses several of them. CIM's advantage is uniformity; its cost is that
the class names are unguessable and `Get-CimClass -ClassName Win32_*` is how you
find them.

`Get-WmiObject` is the older cmdlet for the same data. It is removed in
PowerShell 7 and you will still find it in every script written before 2019.

## The registry

The provider section showed the drive not existing. On Windows:

```sh
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' | Select ProductName
Set-ItemProperty -Path 'HKCU:\Software\MyApp' -Name Level -Value debug
New-ItemProperty -Path 'HKCU:\Software\MyApp' -Name Retries -Value 3 -PropertyType DWord
```

The registry is where Windows keeps what Linux keeps in `/etc`, and the
difference that matters operationally is that it is a **typed** tree — `DWord`,
`String`, `MultiString` — rather than a directory of text files. You cannot `sed`
it, and you do not need to.

## Remoting

```sh
Invoke-Command -ComputerName web01,web02 -ScriptBlock { Get-Service W3SVC }
$s = New-PSSession -ComputerName web01; Invoke-Command -Session $s { … }
Enter-PSSession -ComputerName web01
```

This is the one worth understanding even from a distance, because it is genuinely
different from `ssh`.

**`ssh host 'command'` sends text and receives text.** Lesson 5 section 06 showed exactly
that, and anything you want to do with the result you parse.

**`Invoke-Command` sends a script block and receives objects.** They are
serialised on the far end, sent over the wire, and rehydrated on yours — so
`Invoke-Command -ComputerName web01,web02 { Get-Service }` gives you one
collection of service objects from two machines, with a `PSComputerName` property
saying which is which, and you can `Group-Object` it.

The catch is that they arrive **deserialised**: properties are there, methods are
not. An object that came back from a remote machine is a snapshot, not a handle.

PowerShell 7 can also do this over ssh rather than WinRM, which is how a Linux
box drives a Windows one.

## Active Directory

```sh
Get-ADUser -Filter "Department -eq 'Support'" -Properties LastLogonDate
Get-ADComputer -Filter * | Where-Object OperatingSystem -like '*Server*'
Add-ADGroupMember -Identity 'App Admins' -Members alice
```

Every user, group and machine in a Windows domain, as objects. **This is why
PowerShell is not optional in a Windows shop** — there is no other supported way
to change ten thousand accounts, and the GUI does one at a time.

Note `-Filter`: it is handed to the directory server, which is the filtering-left
argument from section 05 at the scale where it stops being an optimisation and
becomes the difference between a query and a timeout.

## Two versions, and which one you will meet

| | |
|---|---|
| **Windows PowerShell 5.1** | ships in Windows. Built on .NET Framework. Frozen |
| **PowerShell 7** | the current one. Cross-platform, installed separately. `pwsh` |

The executables are even named differently — `powershell.exe` against
`pwsh.exe` — and both can be installed at once.

**Assume 5.1 on a server you did not set up.** Most of this lesson is identical
on it; the differences that will catch you are `.Count` on a single object
(section 09), `ConvertTo-Json -Depth`, ternary and null-coalescing operators
that 5.1 does not have, and `Get-WmiObject` still being present there and gone
here.
