---
title: As configurações de cada pessoa
version: 1
---

O `/etc` é da máquina. As configurações de cada pessoa moram **na pasta pessoal dela**, em arquivos cujo
nome começa com ponto, e é por isso que o `ls -a` da aula 8 importava:

```
ana@server:~$ ls -A ~
.bash_logout
.bashrc
.cache
.local
.profile
.sudo_as_admin_successful
downloads
office
upgrade.log
work
ana@server:~$ grep -c . ~/.bashrc
96
ana@server:~$ grep -n 'HISTSIZE' ~/.bashrc
18:# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
19:HISTSIZE=1000
PS /home/ana> $PROFILE
/home/ana/.config/powershell/Microsoft.PowerShell_profile.ps1
```

- O **`.bashrc`** é lido por todo bash novo, e guarda os ajustes do shell da ana: 96 linhas não vazias
  aqui, entre elas `HISTSIZE=1000`, quantos comandos o `history` da aula 8 lembra.
- O **`.profile`** é lido uma vez no login.
- O **`.config`** e o **`.local`** guardam os ajustes e dados de programas mais novos, uma pasta por
  programa. A pasta `.config` ainda não existe nesta pasta pessoal; o primeiro programa que precisar dela
  a cria.
- O **`$PROFILE`** é o `.bashrc` do próprio PowerShell: o caminho que ele leria, embaixo de
  `~/.config/powershell`, embora nenhum arquivo assim tenha sido escrito.

Um ajuste do usuário se sobrepõe ao da máquina só para aquela pessoa, e é isso que o torna seguro: um
`.bashrc` quebrado quebra uma conta, e o `/etc` fica intacto. **Para restaurar um programa para uma
pessoa, mova a pasta de ponto dele para o lado**, nunca a apague de cara; é a regra de copiar antes da
aula 12 de novo.
