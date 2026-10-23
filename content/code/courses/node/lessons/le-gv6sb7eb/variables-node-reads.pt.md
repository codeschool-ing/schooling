---
title: Variáveis que o próprio Node lê
version: 1
---

**Algumas variáveis de ambiente são lidas pelo Node, não pelo seu código**, e mudam o comportamento do
runtime sem que uma linha do programa mude. A aula 2 usou uma, a `UV_THREADPOOL_SIZE`. Estas são as
outras que um servidor encontra:

| variável | o que faz |
|---|---|
| `NODE_OPTIONS` | opções de linha de comando para todo `node` iniciado com ela, como um limite de memória |
| `TZ` | o fuso horário que o `Date` usa para mostrar horas locais |
| `NODE_EXTRA_CA_CERTS` | um arquivo de certificados extras em que confiar, para uma rede de empresa que inspeciona TLS |
| `UV_THREADPOOL_SIZE` | o tamanho do pool da libuv, aula 2 |

Duas delas, rodando:

```
ana@dev:~/server/links$ node -p 'new Date("2026-10-01T12:00:00Z").toString()'
Thu Oct 01 2026 09:00:00 GMT-0300 (Brasilia Standard Time)
ana@dev:~/server/links$ TZ=Asia/Tokyo node -p 'new Date("2026-10-01T12:00:00Z").toString()'
Thu Oct 01 2026 21:00:00 GMT+0900 (Japan Standard Time)
ana@dev:~/server/links$ node -p 'new Date("2026-10-01T12:00:00Z").toISOString()'
2026-10-01T12:00:00.000Z
ana@dev:~/server/links$ NODE_OPTIONS=--max-old-space-size=40 node -e 'const a = []; for (;;) a.push(new Array(1e6).fill(0))' 2>&1 | grep -E 'FATAL|heap limit'
FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory
```

**O `TZ` mudou o que o `toString` imprimiu, e não o momento em si**: o mesmo instante, em São Paulo e
em Tóquio. É por isso que toda data que o serviço links guarda é `toISOString()`, que é sempre UTC e
sempre o mesmo texto qualquer que seja o fuso do servidor; uma hora local serve para mostrar a uma
pessoa, nunca para guardar.

**O `NODE_OPTIONS` chegou a um programa que nunca o menciona**: o `--max-old-space-size=40` limitou o
heap do V8 a 40 megabytes, e uma alocação além disso caiu com o erro de falta de memória que um
servidor pequeno demais encontra. É como uma plataforma dá um limite ao Node, e como um limite definido
há muito tempo e esquecido derruba um serviço que cresceu.

O `NODE_EXTRA_CA_CERTS` é a resposta honesta aos erros de certificado da aula 1 numa rede de empresa:
o certificado da rede num arquivo, indicado aqui, e o Node confia nele junto com os de sempre. **Ele
não foi rodado para este curso**, que não tem uma rede assim; a alternativa a que as pessoas recorrem,
`NODE_TLS_REJECT_UNAUTHORIZED=0`, desliga a verificação de toda conexão que o processo faz e nunca deve
ser definida.
