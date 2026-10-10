---
title: Um SDK, um proxy, ou os dois
version: 2
---

As aulas 6 e 7 já puseram quatro ferramentas diante do mesmo assistente. As diferenças entre elas que
importam são menos do que as listas de funcionalidades sugerem.

| | Langfuse | LangSmith | Helicone | Phoenix |
|---|---|---|---|---|
| como os dados chegam | OpenTelemetry ou o seu SDK | o seu SDK (e OpenTelemetry) | como proxy, no fio | OpenTelemetry |
| vê as etapas entre chamadas a modelo | sim | sim | não | sim |
| vê chamadas que ninguém instrumentou | não | não | sim, se toda chamada passar por ele | não |
| pode agir sobre pedidos: cache, limite, nova tentativa | não | não | sim | não |
| onde rodou neste curso | na sua máquina, seis contêineres | não rodado; o SDK dele contra um gravador | não rodado; uma imagem, 3,5 GB para baixar | na sua máquina, um pacote Python |
| licença | código aberto | serviço proprietário | código aberto | código aberto |

**Um SDK e um proxy respondem a perguntas diferentes**, e um sistema grande muitas vezes tem os dois: um
gateway na frente dos fornecedores, mantido pela equipe de plataforma, para chaves, limites, cache e
uma contagem completa das chamadas a modelo; e rastreamento dentro de cada aplicação, para as perguntas
que um gateway não vê, as do porquê. Os dois se encontram onde a aula 1 disse que tudo se encontra: se
a aplicação passar o seu id de trace ao gateway num cabeçalho, um pedido nos logs do gateway leva ao
trace que o fez.

Para um assistente único como o da Marginalia, feito por uma equipe, o rastreamento é a metade que não
dá para pular, porque as falhas que este curso achou até agora estavam na busca, no piso e na mensagem
do cliente, e um gateway não vê nenhuma delas. O gateway é a metade a acrescentar quando houver várias
aplicações e uma conta só.

Seja qual for a escolha, a ordem de perguntas da aula 6 continua decidindo: para onde os dados podem
ir, quem vai rodar, e só então o que a ferramenta faz.
