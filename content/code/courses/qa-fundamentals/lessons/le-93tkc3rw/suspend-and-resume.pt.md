---
title: Parando no meio, e começando de novo
version: 1
---

**Às vezes um ciclo precisa parar antes de terminar, e as condições para parar e para recomeçar também valem ser
escritas.** Chamam-se **critérios de suspensão** e **de retomada**, e existem para a manhã em que continuar seria
desperdiçar o tempo de todo mundo.

## Quando suspender

No Cine Aurora um ciclo é suspenso quando acontece uma destas:

- **um defeito bloqueante impede grande parte do teste planejado.** Se não dá para fazer pedidos, a regra de preço, os
  cupons, os reembolsos e o relatório também não dão para testar pela bilheteria; testar em volta do buraco produz
  meios resultados que vão todos precisar ser repetidos;
- **o build sob teste muda debaixo do teste.** Um build novo instalado no meio do ciclo, sem aviso, torna duvidoso todo
  resultado anterior a ele.

O que a suspensão *não* é: quem testa parar porque o trabalho é difícil ou os defeitos são muitos. Muitos defeitos é o
ciclo funcionando.

## O que acontece durante uma suspensão

Suspender é uma mensagem, não um silêncio. Na quinta de manhã antes da entrega de sexta, o botão de reembolso se
mostrou capaz de derrubar o programa da bilheteria sempre que um reembolso era confirmado, levando o pedido aberto
junto. A mensagem da Lia ao time tinha três linhas:

> **Teste suspenso às 9:40.** Confirmar um reembolso fecha o programa da bilheteria e o pedido se perde
> (defeito 31, passos anexados). Preços, pedidos e cupons estão testados; reembolsos, o relatório e o mapa de assentos
> não. **Retoma quando** um build que corrija o defeito 31 passar no teste de fumaça.

A primeira linha diz o que aconteceu e quando. A segunda diz o que está feito e o que está esperando, para ninguém
precisar perguntar. A terceira é o critério de retomada, específico o bastante para todo mundo saber o que *pronto*
quer dizer.

## Quando retomar

Os critérios de retomada em geral são os critérios de entrada de novo, mais a correção: um build novo com o defeito
bloqueante corrigido, passando no teste de fumaça, instalado na máquina de teste. A Lia também roda de novo as
verificações de tudo o que a correção tocou, o que para a queda do reembolso quis dizer pedidos também, porque a queda
vinha perdendo pedidos.

O build corrigido do Rafael chegou às 11:30, passou no teste de fumaça, e o ciclo retomou às 11:50. Duas horas e dez
minutos se perderam, e agora são uma linha no resumo, porque os critérios de saída diziam que toda área recebe suas
horas planejadas *ou a falta fica escrita*. A falta saiu das duas áreas de menor prioridade: o mapa de assentos foi de
duas horas para vinte minutos, o relatório de uma hora para trinta minutos.

## Para que escrever tudo isso

Critérios de entrada, saída, suspensão e retomada podem soar como burocracia para um time de cinco. Merecem o lugar por
um motivo: tiram as decisões do momento de pressão e as põem num momento calmo antes dele. Na quarta, ninguém defende
começar num build quebrado. Na sexta às cinco, todo mundo defende. Critérios escritos na segunda são o time de segunda
protegendo o time de sexta de si mesmo.
