---
title: O que uma cópia guarda
version: 1
---

A vm2 nunca respondeu na rede. O host ainda conseguia perguntar ao agente do convidado, aula 3, que não
precisa de rede:

```
ana@host:~$ virsh domhostname vm2 --source agent
vm1

ana@host:~$ virsh domifaddr vm2 --source agent
 Name       MAC address          Protocol     Address
-------------------------------------------------------------------------------
 lo         00:00:00:00:00:00    ipv4         127.0.0.1/8
 -          -                    ipv6         ::1/128
 enp1s0     52:54:00:c9:25:bc    N/A          N/A

ana@vm1:~$ sudo cat /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  ethernets:
    enp1s0:
      match:
        macaddress: "52:54:00:bb:a6:55"
      dhcp4: true
      dhcp6: true
      set-name: "enp1s0"
```

O clone se chama **`vm1`**, e a placa dele, `52:54:00:c9:25:bc`, está **sem endereço nenhum**. O último comando mostra
por quê, lido na vm1, de cujo disco o da vm2 é cópia: a configuração de rede do Ubuntu vale para a placa
**cujo MAC é `52:54:00:bb:a6:55`**, a placa da vm1. A placa da vm2 tem outro MAC, então nada a configura, e ela nem
chega a pedir endereço.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"O que um clone completo mudou e o que copiou. O virt-clone deu à vm2 um endereço MAC novo, 52:54:00:c9:25:bc em vez de 52:54:00:bb:a6:55, e um UUID novo no libvirt. Copiou todo o resto: o hostname vm1, o machine-id, as chaves de host do SSH, e a configuração de rede, que ainda casa com o MAC antigo, 52:54:00:bb:a6:55, então a placa nova da vm2 fica sem endereço.\"><defs><marker id=\"id-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"220\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">vm1</text><text x=\"430\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">vm2, o clone completo</text><rect x=\"20\" y=\"36\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">endereço MAC</text><text x=\"220\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">52:54:00:bb:a6:55</text><text x=\"430\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">52:54:00:c9:25:bc</text><rect x=\"20\" y=\"72\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">UUID do libvirt</text><text x=\"220\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o próprio</text><text x=\"430\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um novo</text><rect x=\"20\" y=\"108\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hostname</text><text x=\"220\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">vm1</text><text x=\"430\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vm1</text><rect x=\"20\" y=\"144\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">machine-id</text><text x=\"220\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o próprio</text><text x=\"430\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o mesmo</text><rect x=\"20\" y=\"180\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chaves de host SSH</text><text x=\"220\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as próprias</text><text x=\"430\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as mesmas</text><rect x=\"20\" y=\"216\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"235\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o netplan casa com</text><text x=\"220\" y=\"235\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">52:54:00:bb:a6:55</text><text x=\"430\" y=\"235\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">52:54:00:bb:a6:55</text><rect x=\"20\" y=\"254\" width=\"12\" height=\"10\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"40\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o virt-clone mudou</text><rect x=\"240\" y=\"254\" width=\"12\" height=\"10\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"260\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copiado como estava</text></svg>", "caption": "O hypervisor muda o que é dele, o MAC e o UUID. Tudo o que o sistema do convidado escreveu sobre si mesmo vem junto sem mudança, inclusive uma configuração de rede que não serve mais para a placa.", "same": ["hostname", "machine-id"]}
```

A rede é só a parte que falha de forma barulhenta. Tudo o que o sistema escreveu sobre si mesmo no
primeiro boot veio junto também. O **hostname**. O **machine-id**, um número que o systemd e muitos
programas usam para distinguir uma instalação de outra. E as **chaves de host do SSH**, que são como um
cliente SSH sabe que está falando com a máquina em que confiou antes. Duas máquinas com um conjunto de
chaves são, para o SSH, a mesma máquina, e um software de monitoramento ou gerência que identifica
máquinas pelo machine-id vê uma onde há duas.

No Windows o mesmo problema é tratado por uma ferramenta de nome famoso, o Sysprep, seção 04, e a
Microsoft só dá suporte a uma instalação do Windows copiada depois que ela passou por ele. O conserto é
o mesmo em todo lugar:
**tirar a identidade da original antes de copiá-la**, e deixar cada cópia fazer a sua.
