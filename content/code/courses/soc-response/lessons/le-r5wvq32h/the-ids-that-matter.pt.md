---
title: Os ids de evento que importam, e os gêmeos no Linux
version: 1
---

O Windows tem centenas de ids de evento. Um analista lê uns quinze toda semana, e vale conhecê-los pelo
número, porque uma regra de SIEM e a mensagem de um colega os chamam assim.

| id | canal | o que diz | a linha do Linux que diz o mesmo |
|---|---|---|---|
| **4624** | Security | uma conta fez logon | `sshd: Accepted password for` no `auth.log` |
| **4625** | Security | um logon falhou | `sshd: Failed password for`, ou `Invalid user` |
| **4634** / **4647** | Security | fez logoff | `pam_unix(...): session closed for user` |
| **4648** | Security | um logon com credenciais informadas explicitamente (`runas`) | `su` ou `sudo -u` no `auth.log` |
| **4672** | Security | privilégios especiais atribuídos a um logon novo (um administrador) | linhas de `sudo` no `auth.log` |
| **4688** | Security | um processo foi criado, com a linha de comando se isso estiver habilitado | registros `execve` no `audit.log` |
| **4720** | Security | uma conta de usuário foi criada | linhas de `useradd` no `auth.log` |
| **4728**, **4732**, **4756** | Security | um membro acrescentado a um grupo global, local ou universal | linhas de `usermod -aG` no `auth.log` |
| **4740** | Security | uma conta foi bloqueada | linhas do `pam_faillock` |
| **1102** | Security | **o log de auditoria foi apagado** | um arquivo de log truncado ou apagado |
| **7045** | System | um serviço foi instalado | um arquivo de unidade novo em `/etc/systemd/system` |
| **4104** | PowerShell/Operational | um bloco de script rodou, com o texto | o histórico do shell, que é bem mais fraco |
| **1** e **3** | Sysmon/Operational | processo criado com o hash; conexão de rede | regras do `auditd`, ou um agente de EDR |

Dois campos dentro do **4624** e do **4625** fazem a maior parte do trabalho. O **tipo de logon** diz
como: `2` ao teclado, `3` pela rede (um compartilhamento de arquivos), `10` pela Área de Trabalho Remota.
E no 4625 o **código de status** diz por que falhou: `0xC000006A` é senha errada para uma conta que
existe, `0xC0000064` uma conta que não existe. Uma sequência de `0xC0000064` contra muitos nomes é alguém
adivinhando nomes; uma sequência de `0xC000006A` contra um nome é alguém adivinhando uma senha. Essa
distinção volta na aula 9.

**O 1102 merece uma linha só para ele.** Apagar o log Security é algo de que um administrador quase nunca
precisa e que um invasor muitas vezes quer, e o evento é escrito *depois* da limpeza, então sobrevive a
ela. Um 1102 que ninguém consegue explicar é um incidente até prova em contrário. O gêmeo no Linux não tem
essa cortesia: um `auth.log` truncado não diz nada sobre si mesmo, e é por isso que a aula 3 despacha os
logs para fora da máquina antes que alguém possa editá-los.
