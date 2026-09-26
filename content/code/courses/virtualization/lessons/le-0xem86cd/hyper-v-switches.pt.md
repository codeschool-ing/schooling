---
title: Os switches do Hyper-V, e o PowerShell
version: 1
---

As redes do Hyper-V são switches virtuais, de três tipos, mais um que o Windows cria sozinho:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Os tipos de switch virtual do Hyper-V. Externo: unido a uma placa de rede real, então os convidados ficam na rede do escritório. Interno: o host e os convidados, mais ninguém. Privado: só os convidados, nem o host. E o Default Switch que o Windows 10 e 11 criam: NAT para fora pelo host.\"><defs><marker id=\"hv-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Externo</text><text x=\"200\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">unido a uma placa real: convidados na rede do escritório</text><rect x=\"20\" y=\"60\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Interno</text><text x=\"200\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o host e os convidados, mais ninguém</text><rect x=\"20\" y=\"106\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Privado</text><text x=\"200\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">só os convidados, nem o host</text><rect x=\"20\" y=\"152\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Default Switch</text><text x=\"200\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">NAT para fora pelo host, criado pelo Windows</text></svg>", "caption": "O Externo é a VMnet0 do VMware, o Interno a VMnet1 e o Default Switch a VMnet8; o Privado não tem equivalente lá, e afasta os convidados até do host. Um convidado novo num desktop Windows cai no Default Switch a menos que alguém escolha outro.", "same": ["Default Switch"]}
```

Quando um convidado num laptop Windows "está sem internet", confira primeiro em que switch está a placa
dele: o Default Switch quase sempre funciona, e um switch Externo preso à placa cabeada não funciona
enquanto o laptop está no Wi-Fi, o mesmo defeito da VMnet0 da aula 5.

No PowerShell, como administrador:

```sh
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All   # switch it on; then reboot
Get-VM                                              # every VM, its state and uptime
New-VM -Name lab1 -Generation 2 -MemoryStartupBytes 2GB -NewVHDPath C:\VMs\lab1.vhdx -NewVHDSizeBytes 40GB -SwitchName "Default Switch"
Set-VMFirmware lab1 -SecureBootTemplate MicrosoftUEFICertificateAuthority   # so a Linux guest can boot
Add-VMDvdDrive lab1 -Path C:\ISO\ubuntu-24.04-live-server-amd64.iso
Start-VM lab1
Checkpoint-VM lab1 -SnapshotName clean              # Hyper-V's word for a snapshot
Get-VMSwitch                                        # the virtual switches and their types
Get-VMIntegrationService lab1                       # the guest services, Hyper-V's agent
```

**Nenhum deles foi rodado para esta aula**; o Hyper-V precisa do Windows, e o host do curso é Ubuntu.
