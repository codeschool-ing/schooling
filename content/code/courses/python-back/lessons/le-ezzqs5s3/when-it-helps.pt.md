---
title: Quando o async ajuda de verdade
version: 1
---

As medidas desta aula se resumem numa tabela curta:

| a rota passa o tempo | `def` | `async def` | o que fazer |
|---|---|---|---|
| esperando a rede, poucas de cada vez | bem | bem | qualquer um |
| esperando a rede, muitas ao mesmo tempo | limitada pela pool de threads | **escala** | `async def`, com bibliotecas async |
| esperando por uma biblioteca sem versão async | **bem** | bloqueia tudo | `def`, ou `asyncio.to_thread` |
| calculando | uma por vez | uma por vez | mais processos, ou um worker em segundo plano |

Três perguntas decidem isso numa aplicação de verdade, nesta ordem.

**Ela espera muito pela rede, ao mesmo tempo?** Um servidor de chat, um gateway na frente de outros
serviços, uma API que chama três parceiros por requisição: sim, e `async def` com bibliotecas async se
paga. Um site que lê um banco próximo a cada página: raramente o bastante para importar, e o aviso da
aula 1 vale: o tempo vai para a consulta.

**Toda biblioteca no caminho tem versão async?** Uma chamada síncrona dentro de um `async def` desfaz o
resto, como os 10,2 segundos mostraram. Para um banco, isso quer dizer um driver async, e a aula 10 fica
síncrona de propósito: o modo async do SQLAlchemy existe, e é um segundo conjunto de regras para
aprender depois do primeiro.

**A equipe está pronta para manter as duas coisas separadas?** Código async não é mais difícil de
escrever. É mais difícil de revisar, porque o erro parece exatamente com código correto.

A escolha do FastAPI é você decidir por rota, que é a granularidade certa: `def` por padrão,
`async def` onde está a espera, e todo await aguardando de verdade.
