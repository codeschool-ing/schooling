---
title: O que um log responde
version: 1
---

Uma imagem comum do monitoramento de segurança é uma tela que fica vermelha quando alguém invade. **Essa
tela não existe.** O que existe é um conjunto de registros, escritos por máquinas que foram configuradas
para guardá-los, e um analista que os lê depois e decide o que significam. A tela vermelha é o último
passo de uma corrente longa, e cada elo dessa corrente é um registro que alguém escolheu guardar.

Um **log** é um desses registros: uma linha, ou uma entrada estruturada, que um programa escreve quando
algo acontece. Um log útil responde a seis perguntas sobre o evento que descreve:

| pergunta | num login por SSH, por exemplo |
|---|---|
| **quando** | o carimbo de hora, com o fuso horário |
| **onde** | a máquina que escreveu a linha, pelo nome ou pelo endereço |
| **o quê** | o programa e a ação: `sshd`, um login aceito |
| **quem** | a conta: `ana` |
| **de onde** | o endereço e a porta de onde veio a conexão |
| **resultado** | aceito, recusado, falhou, desconectado |

Uma linha sem uma delas ainda tem valor, mas não se sustenta sozinha. Uma linha do firewall conhece os
endereços e a porta e não faz ideia de qual pessoa estava digitando. Uma linha do SSH conhece a pessoa e
não faz ideia de quantos bytes passaram depois. **Juntar dois registros parciais pelos campos que eles
têm em comum** é a maior parte do que o resto deste curso faz, e é por isso que os campos importam mais
do que o formato.

Logs são um de três tipos de telemetria. **Métricas** são números amostrados ao longo do tempo, como a
carga de CPU ou as requisições por segundo, e **traces** acompanham uma requisição por vários serviços.
Os dois são assunto do curso `observability`. Também ajudam a segurança, já que uma linha reta onde
antes havia um serviço movimentado é evidência. Mas as perguntas de um incidente, *quem fez o quê, de
onde e quando*, são respondidas por eventos, e eventos são escritos como logs.

Mais uma distinção encurta as conversas. Um **evento** é qualquer coisa que aconteceu: um login, uma
conexão, um arquivo aberto. Um **alerta** é um evento, ou um padrão de eventos, que uma regra decidiu que
uma pessoa deve olhar. Um **incidente** é o que um alerta vira quando alguém confirma que algo está de
fato errado. A maioria dos eventos nunca vira alerta, e a maioria dos alertas nunca vira incidente. A
aula 12 traça essa linha com cuidado.
