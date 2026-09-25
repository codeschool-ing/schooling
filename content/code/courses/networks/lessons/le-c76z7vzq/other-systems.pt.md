---
title: Conexões no Windows e no macOS
version: 1
---

Todo sistema consegue listar as conexões e os programas escutando, e os estados são as mesmas palavras:

```sh
netstat -ano                                   # Windows: every connection and listener, with the process id
Get-NetTCPConnection -State Listen             # Windows PowerShell: TCP listeners
Get-NetUDPEndpoint                             # Windows PowerShell: UDP sockets
Test-NetConnection 192.0.2.80 -Port 3306       # Windows PowerShell: TcpTestSucceeded True or False
lsof -nP -iTCP -sTCP:LISTEN                    # macOS: TCP listeners and their programs
netstat -an -p tcp                             # macOS: every TCP connection and its state
```

**Nenhum deles foi rodado para esta aula.** O `netstat -ano` é o que vale lembrar no Windows: `-a` para
todas, `-n` para números em vez de nomes, `-o` para o id do processo, que a aba *Detalhes* do
Gerenciador de Tarefas transforma em nome de programa. Os estados vêm por extenso: `LISTENING`,
`ESTABLISHED`, `TIME_WAIT`.

O `Test-NetConnection` com `-Port` responde a pergunta recusada-ou-descartada da seção 07 do jeito
lento: `TcpTestSucceeded : False` nas duas vezes, mas uma porta descartada leva muito mais tempo para
dizer isso. No Mac, o `lsof -nP -iTCP -sTCP:LISTEN` é o mais próximo do `ss -tlpn`: cada socket TCP
escutando e o programa que o segura.
