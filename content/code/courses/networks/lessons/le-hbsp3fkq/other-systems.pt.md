---
title: SSH a partir do Windows e do macOS
version: 1
---

O cliente desta aula é o OpenSSH, e o Windows e o macOS também o trazem:

```sh
ssh ana@192.168.10.10                              # Windows 10 and 11, PowerShell: the same OpenSSH client
ssh-keygen -t ed25519                              # Windows: keys go to C:\Users\<you>\.ssh
Get-Service ssh-agent | Set-Service -StartupType Automatic   # Windows, as administrator: the agent is off by default
Start-Service ssh-agent                            # Windows, as administrator
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh ana@192.168.10.10 "cat >> ~/.ssh/authorized_keys"   # Windows has no ssh-copy-id
ssh-add --apple-use-keychain ~/.ssh/id_ed25519      # macOS: keep the passphrase in the keychain
```

**Nenhum deles foi rodado para esta aula.** O Windows 10 e o 11 trazem o mesmo cliente OpenSSH, então
`ssh`, `ssh-keygen` e `~/.ssh/config` funcionam no PowerShell como funcionaram aqui, com os arquivos em
`C:\Users\<você>\.ssh`. O agente é um serviço do Windows que começa desativado, e não há
`ssh-copy-id`; a linha `type … | ssh` faz o serviço dele, desde que `~/.ssh` já exista no servidor.

O **PuTTY** é o outro cliente que muitos escritórios usam. Ele guarda a sua lista de sessões salvas e
tem o seu formato de chave, o `.ppk`; o PuTTYgen cria chaves e converte entre os dois formatos, e o
Pageant é o agente dele.

O macOS tem OpenSSH no Terminal, e o `ssh-add --apple-use-keychain` guarda a frase-senha no chaveiro,
e assim ela sobrevive a uma reinicialização. Seja qual for o cliente, a pergunta sobre a chave de host e
o aviso de chave trocada querem dizer o que as seções 02 e 12 disseram.
