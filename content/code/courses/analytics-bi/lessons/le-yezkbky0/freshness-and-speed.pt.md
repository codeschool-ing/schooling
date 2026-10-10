---
title: Atual o bastante, e rápido o bastante
version: 1
---

Duas propriedades de um painel são invisíveis no dia em que ele é construído e decidem se ele vai
merecer confiança um mês depois.

## Frescor

Todo número de uma página é tão velho quanto a última carga que o alimentou. Os dados da Lantern
terminam em 17 de junho porque foi a última extração; numa empresa real a extração roda toda noite, e
uma noite ela não roda. A aula 1 encontrou como isso fica um ano depois: um dia que falta e que
ninguém notou. No próprio dia, não parece nada, porque um painel mostra os números de ontem com a
mesma segurança dos de hoje.

Então **a página declara o próprio frescor**: "dados até" a partir dos dados, como na seção sobre
períodos parciais, no cartão de texto ou no título. Um leitor que vê "dados até 12 de junho" no dia 17
sabe que algo quebrou antes de agir sobre um número. Melhor ainda, o time que roda a carga é alertado
quando ela falha, que é assunto de `observability`; a linha no painel é para o dia em que o alerta não
disparou.

## Velocidade

Um painel que leva trinta segundos para abrir é aberto menos, e depois nunca. As causas são quase
sempre as mesmas: cada cartão roda a própria consulta sobre as tabelas cruas, toda vez que alguém abre
a página, e algumas dessas consultas varrem tudo.

Os remédios, na ordem em que vale tentá-los:

1. **Menos cartões.** A lista de perguntas do começo desta aula também é uma ferramenta de desempenho.
2. **Guardar os resultados em cache.** O Metabase pode guardar o resultado de um cartão por um tempo e
   entregá-lo ao próximo leitor; para uma página lida nas manhãs de segunda sobre o mês passado, uma
   hora de cache não muda nada que alguém veja. O aviso da aula 5 vale: um cache também esconde uma
   fonte quebrada até expirar.
3. **Pré-agregar.** Uma tabela de receita líquida por dia e região, reconstruída depois de cada carga,
   responde a todo cartão da página da Lantern a partir de algumas centenas de linhas em vez de milhares
   de pedidos. No PostgreSQL isso é uma view materializada; num warehouse, é uma tabela de resumo feita
   pelo pipeline.

**Nunca troque correção por velocidade em silêncio.** Uma tabela pré-agregada atualizada às 3 da manhã
é uma página cujos números são das 3 da manhã, e a linha "dados até" precisa dizer isso.
