---
title: Chave-valor, o formato mais simples
version: 1
---

Um **armazenamento chave-valor** guarda valores sob chaves, e a única pergunta que ele responde
rápido é "qual é o valor sob esta chave?". Ler, gravar, apagar, e pouco mais. O valor é opaco para
o armazenamento: um texto, um número, um bloco de JSON que ele não olha por dentro.

Isso é um limite severo e é também a fonte de tudo em que a família é boa:

- **Toda operação é uma busca.** Um hash da chave acha o valor, na memória nos armazenamentos mais
  rápidos, então uma operação custa microssegundos e o armazenamento responde dezenas de milhares
  por segundo num processador.
- **Particionar é trivial.** O hash da chave decide o servidor, como na aula 2, e nenhuma operação
  precisa de dois servidores, porque nenhuma operação envolve duas chaves.
- **Expirar é natural.** Uma chave pode levar um tempo de vida, depois do qual ela some sozinha.

O que ele não consegue é qualquer coisa que não seja sobre uma chave. "Todo lugar reservado do show
1" não é uma pergunta que um armazenamento chave-valor responde, a menos que o programa também tenha
guardado uma lista sob outra chave, o que é desnormalização de novo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma chave passa por uma função de hash, que dá um número, e o número escolhe um de quatro baldes ou servidores. Toda operação nomeia uma chave, então toda operação vai para exatamente um balde.\"><rect x=\"20\" y=\"80\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">hold:show:1:seat:42</text><path d=\"M190 100 L250 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M250 100 L243.7 103.0 L243.7 97.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"250\" y=\"80\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"305\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hash(key)</text><path d=\"M360 100 L420 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M420 100 L413.7 103.0 L413.7 97.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"390\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">% 4</text><rect x=\"430\" y=\"20\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"505\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">balde 0</text><rect x=\"430\" y=\"62\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"505\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">balde 1</text><rect x=\"430\" y=\"104\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"505\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">balde 2</text><rect x=\"430\" y=\"146\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"505\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">balde 3</text><path d=\"M420 100 L430 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M430 118 L424.3 114.0 L429.6 111.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"650\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">&quot;ana&quot;</text><path d=\"M580 117 L625 117\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "Uma chave, um hash, um lugar. Nenhuma operação precisa de dois."}
```

## Onde serve

- **Caches**: o resultado de uma consulta cara, guardado sob uma chave feita a partir da consulta,
  por alguns segundos ou minutos. As aulas 8 e 10 de `servers-cache` construíram exatamente isso com
  o Redis.
- **Sessões**: o login e o carrinho do usuário, sob o id da sessão, o que deixa as cópias da aula 1
  continuarem sem estado.
- **Travas e reservas curtas**: "o lugar 42 está reservado para a Ana por dez minutos".
- **Contadores e limites de taxa**: um número por chave, aumentado atomicamente. A aula 9 limita os
  pedidos de cada comprador assim.

Redis, Memcached e Valkey são os membros da família que ficam na memória. O DynamoDB, na aula 5,
começou como armazenamento chave-valor e cresceu em direção a documentos, um caminho comum: um
armazenamento chave-valor puro quase sempre é uma parte de um sistema e não ele inteiro.
