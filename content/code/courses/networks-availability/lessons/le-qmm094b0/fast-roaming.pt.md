---
title: 802.11k, v e r, um roaming rápido
version: 1
---

Um roaming tem três custos, pagos em sequência enquanto o cliente está entre pontos de acesso.

1. Achar um candidato. Sem ajuda o cliente faz varredura, saindo do seu canal para escutar cada um dos
   outros, um de cada vez. Em 5 GHz podem ser mais de vinte canais.
2. Entrar nele. Quadros de autenticação e reassociação com o AP novo.
3. Chaves. O four-way handshake da aula 8 de novo. Numa rede 802.1X, sem nada melhor, também toda a
   troca EAP com o servidor RADIUS, túnel TLS incluído.

Com passphrase, o terceiro passo são duas idas e voltas pelo ar. Com 802.1X são muitas, algumas até um
servidor RADIUS que pode estar em outro prédio, e **uma reautenticação 802.1X completa pode levar
centenas de milissegundos**. Uma página web nem percebe. Uma chamada de voz percebe: um alvo muito citado
para voz é um roaming abaixo de 50 ms, uma regra prática dos guias de projeto de voz dos fabricantes, não
um número de norma nenhuma.

Três emendas ao 802.11 atacam os três custos, uma cada:

| emenda | o que acrescenta | que custo ela corta |
|---|---|---|
| 802.11k (2008) | **relatórios de vizinhos**: o AP diz ao cliente quais APs estão perto e em quais canais | achar um candidato: varrer três canais em vez de vinte |
| 802.11v (2011) | **gerência de transição de BSS**: o AP sugere um AP melhor, ou avisa que vai derrubar o cliente | a decisão, que vem mais cedo e mais bem informada |
| 802.11r (2008) | **transição rápida de BSS**, FT: chaves preparadas de antemão para todo AP de um domínio de mobilidade | as chaves: nenhuma troca EAP nova, e o handshake embutido na entrada |

As três fazem parte da norma 802.11 atual, e as três são **ofertas**. Um cliente que não implementa o
802.11v ignora a sugestão; um que implementa ainda pode recusá-la. O cliente decide, de novo.

## Como o 802.11r economiza as chaves

Na primeira entrada, o cliente faz a autenticação completa uma vez, e do resultado dela deriva-se uma
hierarquia de chaves para todo o **domínio de mobilidade**, o conjunto de APs que o compartilham. Quando o
cliente se move, o AP novo já tem, ou busca nos vizinhos ou na controladora, a chave de que precisa para
aquele cliente. A troca de chaves viaja dentro dos quadros de autenticação e reassociação que o cliente
ia mandar de qualquer jeito, então **o roaming custa a entrada e mais nada**.

Dois mecanismos mais antigos fazem parte do mesmo trabalho. O **cache de PMK**, na norma desde o
802.11i, pula a troca EAP quando um cliente volta a um AP que já usou. O **opportunistic key caching**,
que não está na norma mas é amplamente implementado, deixa os APs de uma controladora compartilharem a
PMK, para que a primeira visita a um AP novo também a pule. Nenhum dos dois economiza o four-way handshake.

## A armadilha de compatibilidade

O 802.11r muda o que o AP anuncia, e **alguns clientes antigos falham ao entrar numa rede que o anuncia**,
em vez de ignorar o que não entendem. Os fabricantes respondem com um modo misto que oferece FT aos
clientes que pedem e a entrada comum aos demais. Diga o datasheet o que disser, o teste que conta são os
aparelhos reais no SSID real: os leitores de código de barras, os telefones, o notebook com o driver mais
antigo.
