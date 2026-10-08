---
title: Escolher os números
version: 2
---

Um limite apertado demais para execuções que teriam dado certo; um frouxo demais deixa uma execução em laço gastar dinheiro e tempo antes de algo pegá-la. Nenhum dos dois erros aparece até você medir, então os números devem vir de execuções, não de intuição.

**Meça a distribuição, não a média.** Rode o agente sobre um conjunto de tarefas realistas (a aula 18 monta um) e registre passos, tokens e segundos de cada execução bem-sucedida. As execuções do dublê nesta aula levaram quatro passos, toda execução do `llama3.2:3b` neste curso levou um ou dois, e na seção 04 uma das respostas dele levou dois minutos. Os números de um modelo maior se espalham de outro jeito, e se espalham. O limite fica acima das execuções bem-sucedidas mais lentas, o percentil 99 por exemplo, com uma margem, para disparar em execuções que deram errado e quase nunca nas que só são longas.

**Ajuste cada orçamento pela própria falha.** O limite de passos pega laços, então fica logo acima do caminho legítimo mais longo. O orçamento de tokens pega contexto descontrolado, então decorre da maior observação que uma ferramenta pode devolver vezes o número de passos em que ela viaja. O orçamento de tempo vem de fora do agente: quanto o cliente vai esperar, ou quanto a fila aguenta.

**Tarefas diferentes, limites diferentes.** Uma pergunta sobre pedido e uma tarefa de pesquisa são cargas diferentes. Um limite global ajustado para a pesquisa deixa a pergunta de pedido em laço por muito tempo antes de parar; um ajustado para a pergunta de pedido para toda pesquisa. Um limite por tipo de tarefa, escolhido pelo roteador que decidiu que a tarefa era de um agente (aula 2), serve às duas.

**Acompanhe com que frequência cada limite dispara.** Um limite que nunca dispara pode estar frouxo demais, ou o agente pode estar saudável. Um que dispara em uma execução de cada cem está fazendo o seu trabalho. Um que dispara em uma de cada cinco está dizendo que o limite está errado ou que o agente está, e os resultados parados, com seus planos e rastros, dizem qual.

## Os números desta máquina são desta máquina

Os tempos desta aula vêm de um modelo pequeno em quatro processadores sem placa de vídeo, e as contagens de passos do dublê foram escritas de antemão, então nenhum deles é recomendação para uma implantação real. O que vale levar é o método: limites são medições com margem, impostos pelo hospedeiro, informados quando disparam.
