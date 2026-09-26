---
title: On a customer's computer
version: 1
---

Two things stop the processor's help from reaching a hypervisor on an ordinary PC, and both are
common.

**It is switched off in the firmware.** Many PCs ship with VT-x or AMD-V disabled. It is switched on in
the UEFI setup, under a name that varies by maker: *Intel Virtualization Technology*, *VT-x*, *SVM
Mode*, *AMD-V*. A hypervisor on such a computer either refuses to start a guest or, like the lab here,
falls back to imitating the processor and runs painfully slowly.

**Something else already has it.** On Windows, Hyper-V, WSL 2, Windows Sandbox and the security
feature called memory integrity all switch on Microsoft's hypervisor, and then Windows is a guest, as
section 02 said. VirtualBox and VMware Workstation can still run on top of it, through a Windows
component called the *Windows Hypervisor Platform*, but they no longer own the processor's features,
and some things become slower or stop working. When a customer's VirtualBox broke the day they
installed WSL, this is why.

What to run to find out:

```sh
systeminfo                       # Windows: under "Hyper-V Requirements", or a line saying a hypervisor was detected
Get-ComputerInfo -Property HyperV*   # Windows PowerShell: the same answers, one per line
sysctl -a | grep -i vmx          # macOS on an Intel processor: VMX in the list means VT-x is there
egrep -c "vmx|svm" /proc/cpuinfo # Linux: more than 0 means the processor offers it
kvm-ok                           # Ubuntu, from the cpu-checker package: whether KVM can be used
```

**None of these were run for this lesson**, and none of them is on the course's host. On Windows,
`systeminfo` lists *Virtualization Enabled In Firmware*, or says a hypervisor has been detected, which
is the Hyper-V case. The *Performance* tab of Task Manager shows *Virtualization: Enabled* on the CPU
page. A Mac with an Apple processor runs guests built for ARM at full speed, and a Windows or Linux
guest built for Intel only by imitation, as slowly as the lab here.
