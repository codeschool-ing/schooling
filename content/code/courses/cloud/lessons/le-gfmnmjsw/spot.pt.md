---
title: "Capacidade spot: barata, e tomada de volta"
version: 1
---

Um provedor compra máquinas suficientes para a hora mais cheia, então na maior parte das horas algumas
estão ociosas. **Capacidade spot é essa capacidade ociosa, vendida com desconto sob a condição de o
provedor poder tomá-la de volta quando precisar.** A AWS chama isso de Spot Instances e anuncia descontos
de até 90% sobre o preço sob demanda; o Google Cloud tem Spot VMs e o Azure tem Spot Virtual Machines. A
máquina é a mesma máquina. O que muda é a promessa: uma máquina sob demanda roda até você pará-la, e uma
máquina spot roda até você ou o provedor pará-la.

O aviso é curto. A AWS manda um aviso de interrupção dois minutos antes de retomar uma Spot Instance; o
Google Cloud dá trinta segundos às Spot VMs dele. É tempo para terminar de gravar um arquivo, não para
terminar um trabalho.

## Por que não está na tabela

A tabela tem um preço sob demanda e um preço reservado para cada máquina, e nenhum preço spot, e isso não
é uma falha do `prices.py`. A lista de preços publicada traz preços fixos até a próxima versão. **Um
preço spot se move com a oferta e a procura**, por tipo de máquina e por zona, e a AWS o publica num
histórico de preços à parte, não nos arquivos de oferta. Um número impresso nesta aula estaria errado
antes de você lê-lo, e esse é o motivo honesto de não haver nenhum.

## Para que serve

Spot combina com trabalho que pode ser interrompido e recomeçado sem perda:

- tarefas em lote divididas em muitos pedaços pequenos, como converter mil vídeos, um de cada vez;
- execuções de teste de um pipeline de build, em que uma execução que morre é simplesmente refeita;
- workers que pegam tarefas de uma fila, em que uma tarefa inacabada volta para a fila;
- máquinas extras no grupo de autoscaling da aula 4, acima de um piso de máquinas sob demanda.

O que esses casos têm em comum é que **o trabalho, e não a máquina, é o que precisa sobreviver**. Uma
tarefa que registra o próprio progresso, ou que pode ser feita duas vezes sem problema, perde no máximo
um pedaço quando a máquina dela vai embora.

## Para que não serve

Spot é o lugar errado para a única cópia de qualquer coisa. Um banco de dados numa máquina spot, a única
instância que serve um site, um trabalho que roda dez horas sem salvar o progresso: cada um perde
exatamente o que não pode ser perdido quando o aviso chega. **O desconto é pago com disponibilidade**, e
o argumento inteiro da aula 9 foi que disponibilidade se projeta, não se espera.

O padrão útil é uma mistura. O piso da seção sobre compromissos roda em máquinas reservadas ou sob
demanda e mantém o serviço de pé; o trabalho acima dele que pode esperar roda em spot e sai barato. Se
todas as máquinas spot forem retomadas de uma vez, o serviço fica mais lento, não fora do ar.
