---
title: Uma zona é um conjunto de máquinas com a mesma confiança
version: 1
---

A imagem comum de segurança de rede é um castelo: uma muralha forte do lado de fora, e tudo o que
está dentro recebe confiança porque está dentro. **Essa imagem é o problema que esta aula resolve.**
Numa rede plana, uma máquina comprometida em qualquer lugar alcança todas as outras, e a muralha só
importou até a primeira coisa passar por ela.

Uma **zona de confiança** (*trust zone*) é um grupo de máquinas que enfrentam os mesmos riscos e
merecem a mesma confiança, de modo que uma regra possa falar por todas elas. Os segmentos do
laboratório são as suas zonas:

| zona | contém | confiança dos outros | exposta à internet |
|---|---|---|---|
| internet | todo o resto do mundo | nenhuma | ela é a internet |
| DMZ | o proxy da loja, o DNS público | muito pouca | sim, de propósito |
| LAN da equipe | os computadores das pessoas | um pouco | não, mas as pessoas leem e-mail e navegam |
| servidores | a aplicação e o banco de dados | a maior | não |
| gestão | a máquina de onde os administradores trabalham | o bastante para administrar as outras | não |

**Segmentação** é pôr um firewall entre as zonas, de modo que toda conversa de uma para outra tenha
de ser permitida por uma regra. No seu laboratório esta aula começa com `sudo bash nslab.sh reset`.
Antes de qualquer regra ser carregada, o `fw` roteia tudo, e um
desconhecido na internet alcança o que quer que responda:

```
ana@remote:~$ probe db:5432 app:22 app:8080 laptop:22 www:443
db:5432                open
app:22                 open
app:8080               open
laptop:22              refused
www:443                open
```

O banco de dados, a aplicação, o SSH no servidor de aplicação: tudo `open`. `laptop:22` diz
`refused`, o que ainda é uma resposta: uma máquina respondeu que nada escuta ali. O `probe`, o
pequeno comando que o `nslab.sh` instala na aula 1, imprime uma de três palavras, e a diferença entre elas
importa a aula inteira:

| o probe diz | o que aconteceu |
|---|---|
| `open` | a conexão foi aceita |
| `refused` | uma máquina respondeu que nada escuta naquela porta |
| `blocked` | nada voltou em um segundo: algo descartou o pacote |

Zonas são uma decisão sobre **pessoas e dados**, não sobre cabos. A LAN da equipe merece menos
confiança que o segmento de servidores não porque as máquinas dela sejam piores, mas porque pessoas
as usam: abrem anexos e visitam sites, e é assim que chegam os problemas da aula 9.
