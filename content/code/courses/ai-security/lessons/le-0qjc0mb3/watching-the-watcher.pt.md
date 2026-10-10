---
title: Vigiar o próprio monitoramento
version: 1
---

As regras ajustadas pegaram três incidentes em dois dias de dados. A falha que elas não conseguem pegar
é **o dia em que os dados param de chegar**. Se o job que grava as contagens por hora morrer, o
`monitor.py` lê um arquivo velho, não acha nada de estranho nele e não diz nada, o que parece
exatamente um dia quieto e saudável.

## Silêncio é um sinal

Então o monitoramento tem uma regra sobre si mesmo: **uma hora sem contagens é um alerta**, com a mesma
severidade da pior coisa que ele teria deixado passar. Um batimento, uma linha gravada toda hora
aconteça o que acontecer, torna a ausência visível. O mesmo vale para cada controle: uma verificação de
canário que parou de rodar relata zero canários para sempre, e uma contagem zerada depois de uma
implantação merece uma olhada para confirmar que a verificação continua no caminho.

## Um alerta diz o que fazer

Um alerta às três da manhã é lido por alguém meio acordado. **Todo alerta leva um link para o seu
runbook**: o que o alerta significa, para onde olhar primeiro, e o que pode ser feito com segurança
antes de mais alguém acordar. Para as respostas recusadas desta aula, a primeira olhada é o `prompts.py
status` e a última implantação, e a ação segura é o rollback da aula 20. Para o canário, é a chamada que
o alerta nomeia, rastreada com o `trace.py`. A aula 24 escreve esses runbooks.

## A lista de alertas é revisada como código

Regras envelhecem como o registro de ameaças da aula 13. Uma regra que não dispara há um ano pode estar
vigiando algo que já não existe, ou estar quebrada; uma regra que dispara toda semana e é sempre
descartada está treinando a equipe a descartá-la. Mais ou menos todo mês, alguém lê a lista com o
histórico do que disparou:

| pergunta | se a resposta for não |
|---|---|
| todo alerta que acordou alguém no mês passado precisava de uma pessoa naquela hora? | rebaixe-o para chamado, ou corrija o formato |
| todo incidente foi anunciado por uma regra? | escreva a regra que o teria anunciado |
| toda regra tem runbook e dono? | escreva, ou apague a regra |

O `alerts.json` mora no repositório com o resto da configuração do assistente, então mudar um limite é
um pull request que alguém revisa, com o motivo na descrição, e não um campo editado num painel no fim
de uma noite longa.
