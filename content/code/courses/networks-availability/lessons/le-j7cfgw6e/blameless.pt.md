---
title: Sem culpados, com responsáveis
version: 1
---

A regra que causou a falha da aula 21 foi escrita por alguém. A frase fácil para o registro é "um
engenheiro acrescentou uma regra que quebrou a descoberta do MTU do caminho", e ela é verdadeira, e **não
ensina nada além de esconder o próximo erro**. O próximo erro é justamente o que você mais precisa ouvir
cedo, de quem o cometeu, enquanto ainda é pequeno.

Um post-mortem sem culpados faz outra pergunta: **o que tornou o erro fácil de cometer e difícil de
ver?** Descartar "destination unreachable" na saída é um passo de endurecimento que as pessoas recomendam
de boa-fé, porque impede um roteador de contar a um scanner quais endereços e portas estão fechados. O
laboratório não diz por que a tabela `hardening` foi posta em `hq`, nem quando. Um post-mortem de
verdade descobriria fazendo perguntas como estas, e não adivinhando:

- Havia um túnel em `hq` quando a regra entrou, ou o túnel chegou depois e esbarrou nela?
- O que quem escreveu a regra sabia sobre o que um "destination unreachable" carrega?
- Que teste, rodado depois da mudança, teria mostrado o estrago, e por que ele não fazia parte da mudança?
- Por que a falha pareceu um problema de aplicação para quem a encontrou primeiro?

O registro descreve decisões com a informação disponível quando foram tomadas, e nomeia regras, mudanças
e lacunas, não pessoas. "A regra `hardening` descarta mensagens tipo 3 na saída de `hq`, inclusive
fragmentation needed" é uma frase que quem escreveu a regra consegue ler, concordar e corrigir.

**Sem culpados não quer dizer sem responsáveis.** As perguntas terminam em ações, e uma ação sem
responsável é um desejo. Cada uma precisa de quatro coisas: uma ação que alguém consiga começar hoje, um
responsável, uma data e **um teste que diga que ela está feita**. Para o caso da aula 21:

| ação | responsável | feita quando |
|---|---|---|
| Estreitar a regra `hardening` para que o fragmentation needed, ICMP tipo 3 código 4, saia de `hq` | o administrador de `hq` | `ping -M do -s 1400` a partir de `files` imprime `Frag needed` em vez de silêncio |
| Tornar o MSS clamping parte da configuração padrão de todo túnel, não só do `wg0` | o líder de rede | um SYN por qualquer túnel leva o MTU daquele túnel menos 40 |
| Pôr um download grande por cada túnel no monitoramento | o responsável pelo monitoramento | um alerta dispara quando o `big.bin` deixa de chegar inteiro |
| Procurar a mesma regra nos outros roteadores | o administrador de `hq` | a lista de roteadores verificados está anexada ao registro |

Nenhuma dessas ações foi executada no laboratório, e o primeiro "feita quando" é uma previsão a partir
do túnel da aula 1, onde o mesmo ping imprimiu `Frag needed and DF set (mtu = 1480)`. Num registro de
verdade a coluna de responsável tem o nome de uma pessoa. O laboratório tem um único usuário, `ana`,
então aqui ela tem papéis, que é a forma mais fraca: **um papel só é responsável se todo mundo concorda
sobre quem o ocupa nesta semana**.

A coluna de data ficou fora daqui porque o laboratório não tem calendário contra o qual marcar uma, e
ela não é opcional num registro de verdade. Uma
ação sem data fica pronta quando alguém se lembra dela, o que acontece depois que a falha volta.
