---
title: Uma métrica, a agregação e as dimensões
version: 1
---

**Uma métrica é uma série de números ao longo do tempo, e o gráfico dela sempre mostra uma agregação, nunca os
valores crus.** O `HttpResponseTime` do App Service é registrado por minuto como contagem, soma, mínimo e máximo das
requisições daquele minuto. Peça a média de uma hora e o Azure Monitor a calcula a partir deles; peça o máximo e você
recebe a requisição mais lenta do minuto mais lento. A mesma métrica, lida de dois jeitos, conta duas histórias, e o
título do gráfico é onde se diz qual.

A armadilha é a média. Um tempo médio de resposta de 180 ms num minuto vale igualmente para um minuto em que toda
requisição levou 180 ms e para um em que a maioria levou 60 ms e algumas levaram quatro segundos. Os clientes do
segundo minuto não foram atendidos em 180 ms; alguns desistiram. Métricas de plataforma em geral oferecem média,
mínimo, máximo, soma e contagem, e não percentis. Esse é o motivo mais forte para a loja medir latência também nos
logs de requisição, onde a lição 10 calcula o percentil 95 diretamente.

**Uma dimensão divide uma métrica.** O `Http5xx` de um plano do App Service pode ser dividido por instância; as
`Transactions` de uma conta de armazenamento, por nome de API e por tipo de resposta. Dividir transforma uma linha em
várias, e é assim que você descobre que os erros vêm todos de uma instância. Nem toda métrica tem dimensões, e a
documentação de cada uma lista quais tem.

O que este laboratório não mostra é uma métrica em si: métricas vêm de recursos em execução, e não há nenhum aqui.
Então o resto das lições de monitoramento trabalha a partir de **logs** carregados no emulador do Kusto, que é onde as
perguntas que importam durante um incidente são respondidas de qualquer jeito. Quando uma métrica é a ferramenta
certa, para um alerta barato de CPU, por exemplo, a lição diz isso e a ensina pela documentação.
