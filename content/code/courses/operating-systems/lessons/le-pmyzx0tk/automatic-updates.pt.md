---
title: Atualizações de segurança automáticas
version: 1
---

Um Ubuntu Server padrão instala o **unattended-upgrades** e o liga. O servidor mínimo da aula 3 o deixou
de fora, então ele é instalado aqui, com a ferramenta da aula 11:

```
ana@server:~$ sudo apt install -y unattended-upgrades > uu.log 2>&1; grep "^Setting up" uu.log
Setting up python-apt-common (2.7.7ubuntu5.3) ...
Setting up python3-distro-info (1.7build1) ...
Setting up iso-codes (4.16.0-1) ...
Setting up python3-apt (2.7.7ubuntu5.3) ...
Setting up unattended-upgrades (2.9.1+nmu4ubuntu1) ...
ana@server:~$ cat /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
ana@server:~$ grep -A2 '^Unattended-Upgrade::Allowed-Origins' /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}";
        "${distro_id}:${distro_codename}-security";
ana@server:~$ systemctl list-timers apt-daily-upgrade.timer --no-pager
NEXT                        LEFT LAST                        PASSED UNIT                    ACTIVATES
Sat 2026-09-26 03:29:33 -03  15h Fri 2026-09-25 10:11:25 -03      - apt-daily-upgrade.timer apt-daily-upgrade.service

1 timers listed.
Pass --all to see loaded but inactive timers, too.
```

- Cinco pacotes foram configurados: a ferramenta e quatro de que ela precisa.
- O **`20auto-upgrades`** são dois interruptores: atualizar as listas de pacotes todo dia (`"1"`), e
  aplicar as atualizações todo dia.
- O **`50unattended-upgrades`** decide **quais** atualizações: por padrão a versão e a suite
  **`-security`** dela. As atualizações comuns do `-updates` não estão na lista, então esperam uma
  pessoa.
- O **`apt-daily-upgrade.timer`**, um timer da aula 14, é o que o roda: num horário sorteado a cada manhã,
  para milhares de servidores não pedirem ao arquivo todos ao mesmo tempo.

## Windows e macOS

O **Windows Update** baixa e instala sozinho as atualizações de segurança e de qualidade na Home e na
Pro. O que um escritório controla é **quando**: o *horário ativo*, durante o qual ele não reinicia, e a
**pausa**, de até cinco semanas. Na Pro, a Política de Grupo pode adiar atualizações de recursos por
meses, que é o ponto da aula 5 sobre a Home e a Pro de novo.

```sh
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5   # the latest updates
wusa /uninstall /kb:<number>                   # remove one update, by the number Get-HotFix showed
```

**Não foi rodado para esta aula.** Cada atualização do Windows tem um número **KB**, o artigo da Base de
Conhecimento que a descreve, e o `Get-HotFix` as lista.

No Mac, *Ajustes do Sistema > Geral > Atualização de Software > Atualizações automáticas* tem
interruptores separados para baixar, instalar atualizações do macOS e instalar **Respostas de Segurança
e arquivos do sistema**, as pequenas correções urgentes. Esse último deve ficar sempre ligado.
