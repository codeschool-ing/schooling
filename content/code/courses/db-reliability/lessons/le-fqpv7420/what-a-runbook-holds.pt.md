---
title: O que um runbook contém
version: 1
---

O topo da página responde às perguntas que alguém tem no primeiro minuto: por onde começar, de quem é
o sistema, e quando foi a última vez que se comprovou que a página estava certa. Depois vem **onde
ficam as coisas**, com endereços reais, porque "o banco de dados" não é algo que uma pessoa consiga
digitar. Depois, uma entrada por **cenário**, cada uma no mesmo formato:

| parte | o que diz | de onde vem |
|---|---|---|
| **Esperado** | como essa falha se parece quando o sistema dá conta: os números | o ensaio da lição 23 |
| **Verificar** | como ver se ele deu conta | o `status.sh`, abaixo |
| **Se não** | o próximo passo, e a qual outro cenário ele leva | |
| **Depois** | o que fazer depois que ele deu conta, e o que ainda não fazer | as decisões da lição 22 |
| **Pronto quando** | o estado que encerra o incidente, como algo que se pode ver | lição 22 |
| **Avisar** | quem fica sabendo, e quando | as mensagens da lição 22 |

Cada comando é escrito inteiro, copiado de uma execução que funcionou, e não parafraseado: "reinicie o
nó" é uma frase que alguém precisa traduzir às três da manhã, e `patroni ~/patroni/pg2.yml` não é.
Cada número é um número medido, com o lugar onde foi medido, para que alguém que lê "cerca de 30
segundos" saiba se 50 é um problema.

Os cenários são os que este curso provocou de propósito: um líder morto (lições 15 e 16), um nó que
não volta ao cluster (o rewind da lição 15 e a configuração dele), o etcd perdido (lição 16), um líder
congelado (lição 17), um standby atrasado ou desconectado (lição 13), um slot enchendo o disco (lição
11), linhas apagadas por engano (lições 6 e 20) e uma restauração a partir do arquivo (lições 5 a 7).
Mais adiante nesta lição, o primeiro deles está escrito por inteiro.
