---
title: O que um EDR de verdade acrescenta
version: 1
---

**Cada fraqueza do EDR desta aula é um ponto em que um produto fez uma escolha diferente.** Isso faz
do pequeno um bom jeito de ler a folha de especificações de um produto: cada recurso nela responde a
uma das frestas que você já viu por conta própria. Nenhum dos produtos abaixo foi executado para
este curso; o que eles fazem está descrito a partir da documentação dos fabricantes.

## Avisado, não olhando

O sensor olhava o `/proc` e deixou passar vinte processos de vinte. O sensor de um produto é
**chamado pelo kernel** no momento em que algo acontece, então nada é curto demais para ser visto, e
os pais ainda estão vivos quando o registro é feito.

- No Linux, o jeito moderno é o **eBPF**: pequenos programas que o kernel roda em pontos escolhidos,
  como o momento em que um programa é executado ou uma conexão é aberta, verificados pelo kernel
  antes de poderem ser carregados. Falco, Tetragon e a maioria dos sensores comerciais para Linux
  funcionam assim. O jeito mais antigo é a trilha de auditoria que o `auditctl` não alcançou de
  dentro de um contêiner.
- No Windows, o mesmo papel é feito por **callbacks do kernel**, que um driver registra para ser
  avisado de cada processo, thread e imagem carregada, e pelo **Event Tracing for Windows** (ETW), o
  fluxo de eventos que o sistema e os seus componentes escrevem. O Sysmon, ferramenta gratuita da
  Microsoft, grava boa parte disso no log de eventos e é o primeiro passo comum antes de um produto
  completo.

## Difícil de desligar

O `sensor.py` é um processo como outro qualquer: o root o para com um comando, e qualquer um que vire
root também. Produtos se defendem, o que se chama **proteção contra adulteração**. O agente roda sob
a proteção do próprio sistema, recusa ser parado ou desinstalado sem um código do console, e o
silêncio dele já é um alerta: uma máquina que para de informar é tratada como uma máquina que
precisa de uma olhada.

## Em outro lugar

A telemetria aqui fica no próprio `web`, em `/var/log/sensor.jsonl`, onde qualquer um que controle a
máquina pode editá-la. Um produto manda cada registro para fora da máquina assim que é feito, para um
console que o guarda por semanas ou meses e põe os registros de todas as máquinas lado a lado. É isso
que responde às perguntas que uma máquina só não responde: este hash, esta cadeia de pais ou este
endereço apareceram em algum outro lugar da empresa.

## Resposta como um botão

O isolamento aqui foi um arquivo que você escreveu e carregou à mão. Um produto faz a mesma coisa a
partir do console, a qualquer hora, e pode fazer **automaticamente** quando uma regra tem certeza
suficiente. Também consegue recolher os arquivos e a memória de que quem responde precisa, e matar um
processo em todas as máquinas de uma vez.

## Os nomes que você vai encontrar

| produto | o que é |
|---|---|
| Microsoft Defender for Endpoint | o EDR comercial da Microsoft, embutido no Windows e disponível para Linux e macOS |
| CrowdStrike Falcon, SentinelOne | EDRs comerciais com sensor e console próprios, em todos os sistemas principais |
| Wazuh | código aberto: um agente, regras e um console, com integridade de arquivos e análise de logs também |
| osquery | código aberto: o estado da máquina como tabelas SQL, consultadas por uma pessoa ou num agendamento |
| Elastic Defend | o agente de endpoint da pilha Elastic, enviando para o Elasticsearch |

## O que nenhum deles tira

**As regras continuam tendo de ser escritas por alguém que sabe o que a máquina faz.** Um produto
traz milhares, e cada uma dispara com algo legítimo em algum lugar: o script de um administrador
parece uma intrusão para uma regra que nunca conheceu esse administrador. Os primeiros meses de
qualquer EDR são gastos em **ajuste fino**: decidir, alerta por alerta, quais descrevem o normal
desta empresa e podem ser silenciados para estas máquinas, e quais estavam certos. Um produto que
ninguém ajusta produz tantos alertas que ninguém os lê, o que é o mesmo que não ter nenhum.
