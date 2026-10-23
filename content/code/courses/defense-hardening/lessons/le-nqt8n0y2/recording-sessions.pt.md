---
title: A porta diz quem passou
version: 1
---

**Uma porta única só é útil se guardar um registro.** Antes desta aula a pergunta "quem entrou no
`web` como root ontem à noite" não tinha boa resposta: toda máquina tinha a mesma chave, e o log
diria `ana` vindo de qualquer lugar. Agora toda conexão administrativa vem do `jump`, carrega um
certificado com uma identidade dentro, e o `web` recebeu a ordem de registrar em detalhe com
`LogLevel VERBOSE`:

```
root@web:~# journalctl -u ssh -o cat | grep -E "^(Accepted|Failed|error)" | tail -4
Accepted publickey for ana from 192.168.60.40 port 51346 ssh2: ED25519-CERT SHA256:uNd8LFH2OUEz1CO+izl+KXX0/r30W6iqUjUjMA8jRkk ID ana@jatoba (serial 0) CA ED25519 SHA256:cGACsyfksD/bNohootB5cxsSQnXiWRHRd0ZyB8Jxg/k
Failed publickey for ana from 192.168.60.40 port 51360 ssh2: ED25519 SHA256:uNd8LFH2OUEz1CO+izl+KXX0/r30W6iqUjUjMA8jRkk
error: Certificate invalid: expired
Failed publickey for ana from 192.168.60.40 port 51360 ssh2: ED25519-CERT SHA256:uNd8LFH2OUEz1CO+izl+KXX0/r30W6iqUjUjMA8jRkk ID ana@jatoba-yesterday (serial 0) CA ED25519 SHA256:cGACsyfksD/bNohootB5cxsSQnXiWRHRd0ZyB8Jxg/k
```

Leia as quatro linhas de cima para baixo. A primeira é o login bem-sucedido: vindo de
`192.168.60.40`, o bastião, com um **certificado** cuja identidade é `ana@jatoba`, assinado por uma
autoridade identificada. As outras três são a tentativa expirada: a chave simples foi oferecida
primeiro e falhou, porque `AuthorizedKeysFile none` quer dizer que nenhuma chave simples consegue
entrar; depois o certificado, recusado como `expired`, com a identidade `ana@jatoba-yesterday` ainda
anotada.

**Essa identidade é a questão.** A conta no servidor é `ana` de qualquer jeito. A identidade do
certificado diz qual certificado foi usado, e o registro da própria autoridade diz quem o pediu e
quando. Num escritório com três administradores que entram todos como `ana`, ou como `root`, é o
campo que transforma "alguém entrou" num nome.

## O que mais uma porta pode registrar

O log acima registra quem entrou e quando, não o que fez. Gravar a sessão em si, cada tecla e cada
linha de saída, é outra ferramenta, e nenhuma das abaixo foi executada para este curso:

- **tlog**, da Red Hat, grava sessões de terminal no journal e consegue reproduzi-las; é a escolha
  comum de código aberto em bastiões Linux.
- **`script`**, o comando padrão do Unix, pode ser rodado pelo `ForceCommand` num servidor para que
  toda sessão seja gravada num arquivo; é rústico e fácil de contornar por um administrador que saiba
  que ele está ali.
- **Produtos comerciais de acesso privilegiado** (CyberArk, BeyondTrust, Teleport e outros) ficam no
  lugar do bastião, emitem eles mesmos credenciais de vida curta, gravam vídeo de sessões gráficas e
  exigem aprovação para alguns destinos.

Gravar teclas captura senhas digitadas em prompts e o conteúdo de arquivos que alguém abriu, então uma
gravação é ela mesma um dado sensível: fica numa máquina que as pessoas gravadas não conseguem
alterar, pelo tempo que a política do escritório disser, e só é lida quando há motivo. **Avise os
administradores de que isso acontece**; um gravador que as pessoas conhecem muda o comportamento, o
que é metade do valor dele, e um que elas descobrem parece uma armadilha.
