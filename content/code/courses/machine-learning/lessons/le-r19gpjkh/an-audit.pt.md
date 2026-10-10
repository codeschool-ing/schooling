---
title: Uma auditoria de vazamento, coluna por coluna
version: 1
---

Já que nenhuma nota prova uma coluna inocente, a defesa é um hábito: **antes de uma coluna entrar
num modelo, alguém diz de onde ela vem.** A Ana mantém uma tabela ao lado do enquadramento da aula
1, com uma linha por coluna, e uma coluna com célula vazia não entra.

| coluna | escrita por | quando | na data do retrato? |
|---|---|---|---|
| `skips_90d` | o sistema de pedidos, contada a partir do histórico | no retrato | sim |
| `rating_90d` | o sistema de avaliações, média do histórico | no retrato | sim |
| `days_since_login` | o registro de logins do aplicativo | no retrato | sim |
| `days_since_last_order` | calculada pela exportação | 1º de janeiro de 2026, para toda linha | **não** |
| `cancel_reason` | o formulário de cancelamento | quando o assinante cancela | **não** |
| `price_month` | o sistema de cobrança | no retrato | sim |

A última coluna da tabela é a que importa, e ela só pode ser preenchida perguntando a quem cuida dos
sistemas, ou lendo o código que monta o arquivo. **Nenhuma das duas coisas dá para fazer só com os
dados**, e por isso vazamento é uma pergunta sobre uma empresa antes de ser uma pergunta sobre um
modelo.

## Cinco perguntas para cada coluna

1. **Quem a escreve, e em resposta a quê?** Uma coluna escrita por uma pessoa reagindo ao resultado
   carrega o resultado.
2. **Quando ela é escrita, e isso é antes do momento da previsão?** Se é escrita depois, não pode ser
   entrada.
3. **Se é um resumo, de que janela, terminando quando?** "Últimos 90 dias" não quer dizer nada até
   você saber que os 90 dias terminam no retrato e não na exportação.
4. **Ela pode mudar depois de escrita?** Um campo atualizado no lugar, como a situação ou o segmento
   de um cliente, guarda o valor de hoje em toda linha histórica.
5. **Ela vai estar lá, com o mesmo significado, quando o modelo rodar?** Uma coluna calculada num
   lote noturno não vai existir para um modelo que avalia em tempo real, no caixa.

A quarta pergunta é a que mais acha vazamentos na prática, e é a mais difícil de ver, porque um campo
atualizado no lugar parece exatamente um campo histórico. A pista é um campo igual em toda linha de
um cliente, mesmo ao longo de anos em que esse cliente certamente mudou.

## E o procedimento em volta

**Divida primeiro.** **Ajuste toda etapa que aprende dentro do pipeline.** **Preencha a tabela antes
de modelar.** **Trate qualquer nota acima do que o problema permite como defeito até prova em
contrário.** E **teste uma vez em dados mais novos que tudo isso**. Nada disso demora, e juntas essas
coisas são a diferença entre um modelo cujo número quer dizer algo e um que será retirado em silêncio
seis meses depois de ter sido elogiado.
