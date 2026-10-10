---
title: Como é uma semana desse trabalho
version: 1
---

**As vagas descrevem a semana do engenheiro de dados como construir pipelines. A maior parte dela é
mantê-los vivos.** Esta é a de Davi, na semana em que ana chega, como uma lista do que de fato
aconteceu. Cada item é um tipo de trabalho a que este curso dá nome, e a aula que o nomeia está ao lado.

| dia | o que aconteceu | que tipo de trabalho é | aula |
|---|---|---|---|
| segunda | o arquivo de domingo dos sensores não estava lá às 06:00; chegou às 09:40 e o relatório da manhã saiu atrasado | **atualidade**: dado certo, mas fora da hora | 2, 7 |
| segunda | Marta pediu as estações vazias da semana passada | **um pedido**: transformar uma pergunta em dado capaz de respondê-la | 1 |
| terça | o time do aplicativo acrescentou um campo `promo_code` às viagens; a cópia noturna o ignorou | **mudança de esquema** numa fonte | 4, 5 |
| quarta | uma viagem apareceu duas vezes na tabela de viagens depois que um job foi repetido | **idempotência**: um passo que pode rodar duas vezes sem estrago | 3, 9 |
| quarta | ana perguntou por que o histórico dos sensores é guardado em Parquet e não em CSV | **uma decisão de formato** | 6 |
| quinta | a API do provedor de pagamentos passou a recusar chamadas acima de 100 por minuto | **os limites de uma fonte**: limitação de taxa | 4, 7 |
| quinta | a conta de armazenamento subiu um terço num mês | **custo** | 2, 7 |
| sexta | Caio pediu as leituras das docas à medida que acontecem, não na manhã seguinte | **lote ou fluxo** | 8 |
| sexta | um disco do servidor que guarda os arquivos brutos encheu | **operação**: a máquina por baixo de tudo | 9 |

Dois pedidos, uma questão de projeto e seis coisas que quebraram ou quase quebraram. Essa proporção é
normal, e explica o hábito mais importante do ofício: **um pipeline é construído para ser operado,
não só para rodar.** Ele avisa quando falha, pode ser rodado de novo com segurança, e alguém que não é
o autor consegue dizer o que ele fez ontem à noite.

## A pirâmide a que ele serve

Monica Rogati desenhou as necessidades de uma empresa orientada a dados como uma pirâmide, e o desenho
durou porque explica por que tantas empresas contratam primeiro um cientista de dados e se arrependem:

1. **coletar** — o dado é registrado, para começo de conversa;
2. **mover e guardar** — ele chega a algum lugar de onde dá para lê-lo, com confiança;
3. **explorar e transformar** — ele é limpo e moldado em algo com significado;
4. **agregar e rotular** — métricas, segmentos, os dados de treino de que um modelo precisa;
5. **aprender e otimizar** — experimentos, previsões, IA.

Cada nível se apoia nos de baixo. **O trabalho do engenheiro de dados são os três de baixo**, e os dois
de cima não se constroem sobre uma base que falta. Um cientista de dados contratado por uma empresa sem
os três primeiros passa a maior parte do primeiro ano fazendo o trabalho de um engenheiro de dados, em
geral sem as ferramentas e os hábitos para isso.

## O que o ofício não é

Não é administração de banco de dados, embora tome emprestado dela. Um administrador de banco mantém um
banco rápido e seguro; um engenheiro de dados move dado entre muitos sistemas e responde pelo que
acontece no meio. E não é "a pessoa que escreve o SQL dos analistas". Escrever SQL é uma habilidade que
o ofício usa todo dia, e `sql-databases` a ensina; o ofício é o sistema em volta do SQL.
