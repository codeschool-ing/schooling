---
title: Lendo o `systemctl status`
version: 1
---

**Um aviso antes da figura.** Toda transcrição deste curso foi rodada na máquina em que ele foi
gravado. Esta não pôde ser: o processo um aqui é um supervisor de contêiner e não o systemd, então
não existe um `systemctl status` para capturar. O que vem a seguir é um **desenho**, rotulado como
tal, e os campos estão onde um bloco de status de verdade os põe. A seção 08 explica por que aquela
máquina é montada assim.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 364\" role=\"img\" aria-label=\"Um desenho de um bloco do systemctl status para o nginx, com seis chamadas numeradas: o ponto de estado, a linha Loaded, a linha Active, a linha Main PID, a árvore CGroup e as linhas do journal no rodapé.\"><rect x=\"20\" y=\"16\" width=\"680\" height=\"202\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"34.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"52\" y=\"34.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">● nginx.service - A high performance web server</text><text x=\"36\" y=\"49.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"52\" y=\"49.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">     Loaded: loaded (/lib/systemd/system/nginx.service; enabled)</text><text x=\"36\" y=\"65.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"52\" y=\"65.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">     Active: active (running) since Mon 2026-09-14 09:12:03 UTC; 2h 41min ago</text><text x=\"36\" y=\"80.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"52\" y=\"80.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">   Main PID: 1284 (nginx)</text><text x=\"52\" y=\"96.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">      Tasks: 3 (limit: 4657)</text><text x=\"52\" y=\"111.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">     Memory: 8.4M</text><text x=\"36\" y=\"127.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">5</text><text x=\"52\" y=\"127.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">     CGroup: /system.slice/nginx.service</text><text x=\"52\" y=\"142.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">             ├─1284 nginx: master process /usr/sbin/nginx</text><text x=\"52\" y=\"158.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">             └─1285 nginx: worker process</text><text x=\"36\" y=\"189.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">6</text><text x=\"52\" y=\"189.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Sep 14 09:12:03 vm systemd[1]: Starting nginx.service...</text><text x=\"52\" y=\"204.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Sep 14 09:12:03 vm systemd[1]: Started nginx.service.</text><text x=\"40\" y=\"250.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"58\" y=\"250.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o ponto: verde rodando, vermelho falhou, vazado parado</text><text x=\"40\" y=\"265.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"58\" y=\"265.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Loaded: qual arquivo de unit, e se ele inicia no boot</text><text x=\"40\" y=\"280.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"58\" y=\"280.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Active: o estado agora, e há quanto tempo</text><text x=\"40\" y=\"295.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"58\" y=\"295.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Main PID: o número do processo, para a aula 6</text><text x=\"40\" y=\"310.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">5</text><text x=\"58\" y=\"310.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">CGroup: cada processo que este serviço possui</text><text x=\"40\" y=\"325.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">6</text><text x=\"58\" y=\"325.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e as últimas linhas do journal dele, de graça</text><text x=\"40\" y=\"346.5\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">desenhado, não capturado: esta máquina não roda systemd como PID 1</text></svg>", "caption": "A forma do `systemctl status`. Este bloco é um desenho e não uma transcrição, porque a máquina em que este curso foi gravado roda um supervisor de contêiner como processo um; numa máquina que dá boot normalmente os campos ficam onde este desenho os põe."}
```

## A primeira linha: está de pé, num olhar

```
● nginx.service - A high performance web server
```

O ponto é o resumo, e ele é colorido:

| | |
|---|---|
| `●` verde | rodando |
| `●` vermelho | **falhou** — tentou e não conseguiu |
| `○` vazado | parado, e ninguém está reclamando |

Depois o nome da unit e a `Description=` dela, da seção 11. **Um serviço de que você nunca ouviu
falar se apresenta naquela linha**, o que vale mais do que parece quando você está lendo um
`systemctl --failed` numa máquina que outra pessoa montou.

## `Loaded:` responde *ele está configurado*

```
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled)
```

Três fatos numa linha:

| | |
|---|---|
| `loaded` | o systemd leu um arquivo de unit para ele. `not-found` quer dizer que não existe esse serviço |
| o caminho | **qual** arquivo, o que importa quando há dois — seção 11 |
| `enabled` | ele vai iniciar no próximo boot. O link simbólico da seção 09, relatado de volta |

**`loaded … disabled` num serviço que está rodando agora é uma coisa normal e alarmante de ver.**
Quer dizer que alguém iniciou na mão e ele vai sumir depois de um reboot.

## `Active:` responde *está de pé, e desde quando*

```
     Active: active (running) since Mon 2026-09-14 09:12:03 UTC; 2h 41min ago
```

| | |
|---|---|
| `active (running)` | está de pé, e tem processo |
| `active (exited)` | rodou, terminou, e era esse o objetivo — uma tarefa única de preparação |
| `inactive (dead)` | parado |
| `failed` | parou **e o systemd acha que isso estava errado** |
| `activating` / `deactivating` | no meio do caminho, agora |

**`active (exited)` confunde todo mundo uma vez.** Uma unit que monta algo, ou define um sysctl, ou
carrega regras de firewall não tem nada rodando quando dá certo, e isso é sucesso.

E a hora é a parte que as pessoas pulam. **"Desde 2 minutos atrás" num serviço em que você não
encostou é a resposta inteira** — algo o reiniciou, e o journal da seção 12 vai dizer o quê.

## `Main PID:` e `CGroup:` ligam isto à aula 6

```
   Main PID: 1284 (nginx)
     CGroup: /system.slice/nginx.service
             ├─1284 nginx: master process /usr/sbin/nginx
             └─1285 nginx: worker process
```

O PID é um número que você entrega a tudo na próxima aula — `ps`, `kill`, `/proc/1284`.

A árvore de CGroup é a terceira ideia da seção 08, tornada visível. **Aqueles são todos os processos
que este serviço possui**, incluindo os que ele bifurcou, e o systemd sabe deles porque o kernel
mantém a lista. É isso que torna o `systemctl stop` confiável onde matar o conteúdo de um arquivo de
PID não era.

`Tasks`, `Memory` e `CPU` vêm da mesma contabilidade, e são de graça — sem agente de monitoramento
envolvido.

## As linhas de baixo são o journal

```
Sep 14 09:12:03 vm systemd[1]: Starting nginx.service...
Sep 14 09:12:03 vm systemd[1]: Started nginx.service.
```

O `status` imprime as últimas dez linhas do log do serviço sem ser pedido. **Numa falha, o motivo
costuma estar bem ali**, e as pessoas vão direto ao `journalctl` sem ler o que já estava na tela.

`systemctl status -n 50` mostra mais; `-l` impede que ele corte linhas longas.

## Como ler uma falha, em ordem

Quando o ponto está vermelho, quatro linhas respondem, e elas estão nesta ordem na tela:

1. **`Loaded:`** — está `not-found`? Então o arquivo de unit está faltando ou com nome errado, e o
   resto não importa.
2. **`Active: failed (Result: …)`** — a palavra do `Result` diz *como* falhou: `exit-code`,
   `timeout`, `signal`, `core-dump`.
3. **`Process: … status=…`** — o código de saída que o programa devolveu. A seção 14 da aula 6 lê
   esses.
4. **As linhas do journal** — o que o próprio programa disse antes de parar. Essa é a que costuma
   conter a resposta: uma porta em uso, um arquivo ausente, uma permissão negada.

**Leia as quatro antes de mudar qualquer coisa**, e nessa ordem. Reiniciar um serviço que falhou sem
lê-las é como uma tarde desaparece.

## E uma coisa que o `status` não te conta

Ele mostra as linhas de log do próprio serviço, não as da máquina. Um serviço que falhou porque
*outra coisa* falhou — a rede, uma montagem, um banco de dados de que ele depende — vai te mostrar a
confusão dele em vez da causa.

O `journalctl -b` da seção 12 mostra o boot em ordem, e é ali que uma cascata fica legível.
