---
title: Escolhendo, e quando o ETL ainda é o certo
version: 1
---

**Carregue primeiro, a menos que você tenha um motivo para não carregar.** Esse é o padrão que este
curso adota, e o argumento são as três últimas seções: linhas cruas respondem à pergunta de amanhã,
reproduzem o relatório de ontem, e deixam uma transformação ruim ser consertada e rodada de novo sem
perguntar à origem outra vez.

Os motivos para não carregar são reais, e vale conhecê-los pelo nome:

| motivo | como aparece | por que aponta para o ETL |
|---|---|---|
| **o dado não pode chegar** | e-mails de clientes, números de cartão, dados de saúde | uma coluna que nunca foi carregada é uma coluna que você nunca precisa proteger, exportar ou apagar |
| **a transformação não é SQL** | ler uma nota fiscal em PDF, chamar uma API de geocodificação, redimensionar uma capa | o warehouse não faz isso, então acontece fora de qualquer jeito |
| **o destino é fraco** | um banco operacional, uma planilha, um servidor pequeno | carregar linhas cruas nele custa o que o warehouse teria absorvido |
| **o volume é absurdo** | um sensor mandando uma leitura por milissegundo | agregue no caminho, ou a camada crua custa mais que as respostas |

## A primeira linha é a que se leva a sério

Os clientes da Ponto Final deram o e-mail para receber recibos, não para um warehouse. Uma camada
crua que copia `customers` inteira agora guarda cinco mil endereços de e-mail num segundo lugar, e a
lei brasileira — a LGPD — dá a cada uma dessas pessoas o direito de pedir que sejam apagados, de
**todos** os lugares onde são guardados. Um pipeline que descarta o `email` na entrada, ou o troca
por um hash, remove o problema antes de ele existir. **Isso é ETL, e para essa coluna é a decisão
certa** mesmo num warehouse que carrega todo o resto cru.

Então na prática a maioria dos pipelines é as duas coisas: **extrair, uma transformação leve que
remove o que não pode chegar, carregar, e depois a transformação de verdade dentro do warehouse.**
As letras são menos úteis que a pergunta por trás delas — onde cada pedaço do trabalho deve ficar, e
quanto custa pô-lo lá?

A lição 3 começa essa pergunta do início, com os quatro tipos de origem de onde um pipeline extrai e
o que cada um faz com a extração.
