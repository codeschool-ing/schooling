---
title: Tentar de novo sem piorar as coisas
version: 1
---

**Uma requisição que falhou muitas vezes vale ser enviada de novo, e uma nova tentativa escrita sem
cuidado transforma uma falha em dois tipos de estrago.** O primeiro é no servidor: mil celulares
tentando de novo ao mesmo tempo, a toda velocidade, mantêm no chão um servidor que já está com
dificuldade. O segundo é nos dados: uma requisição que mudou alguma coisa, enviada duas vezes, pode
mudá-la duas vezes. Uma nova tentativa segura responde a três perguntas antes de mandar qualquer
coisa de novo.

## Quantas vezes, e com que intervalo

O `fetchWeek` só tenta de novo quando o servidor responde com status 500 ou maior, o que quer dizer
que *o servidor* falhou e pode não falhar na próxima. Um 404 ou um 403 vai falhar do mesmo jeito
por mais vezes que se pergunte, então é lançado na hora. O número de novas tentativas é um parâmetro
com um padrão pequeno, e a espera entre as tentativas **dobra** a cada vez: 500 milissegundos,
depois um segundo, depois dois. Isso é o *backoff exponencial*, e ele dá a um servidor que está
reiniciando tempo para voltar, em vez de uma fila de requisições esperando por ele.

O `/flaky` já foi chamado três vezes, pelo `curl`, então as próximas duas chamadas falham e a
seguinte responde. Pergunte com duas novas tentativas, e depois mais uma vez sem nenhuma:

```
ana@dev:~/planner$ node fetchweek.ts /flaky --retries 2
asking http://127.0.0.1:8014/flaky
attempt 1: HTTP 503, waiting 500 ms
attempt 2: HTTP 503, waiting 1000 ms
{ monday: '2026-10-19', planned: 180, done: 120 }
after 1.6 s
ana@dev:~/planner$ node fetchweek.ts /flaky
asking http://127.0.0.1:8014/flaky
Error: HTTP 503 after 1 attempt(s)
after 0.1 s
```

Com duas novas tentativas, o cliente esperou 500 ms depois do primeiro 503 e 1000 ms depois do
segundo, e a terceira tentativa recebeu resposta: 1,6 segundo ao todo, 1,5 deles esperando. A chamada
seguinte foi a primeira de um novo par de falhas, e sem novas tentativas aquele primeiro 503 foi o
fim. **O limite importa tanto quanto a espera**: se duas novas tentativas não bastassem, o cliente
teria lançado o erro depois da terceira tentativa em vez de tentar para sempre.

**Um cliente de verdade acrescenta acaso a cada espera, o chamado *jitter***, para que celulares que
falharam no mesmo instante não voltem todos no mesmo instante também. Ele fica de fora aqui para que
a sua saída bata com a transcrição. O curso `mobile-offline` mede os dois na aula 9.

## Quais requisições podem ser repetidas

**Pedir a semana pode ser repetido quantas vezes você quiser: ler duas vezes não muda nada.** Uma
requisição que muda alguma coisa é diferente, e a armadilha é um timeout. Quando uma requisição
estoura o prazo, o cliente só sabe que nenhuma resposta chegou. Ele não sabe se o servidor nunca
recebeu a requisição, ou se recebeu, fez o trabalho e perdeu a resposta no caminho de volta:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l14-lost-answer\" aria-label=\"Uma sequência entre o celular e o servidor. O celular envia: adicionar uma sessão de 30 minutos. O servidor adiciona e responde, mas a resposta se perde na volta. O prazo do celular passa, ele só sabe que nenhuma resposta chegou, e envia a mesma requisição de novo. O servidor adiciona uma segunda sessão. A semana agora diz 210 minutos planejados em vez de 180.\"><defs><marker id=\"l14-lost-answer-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"14\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o celular</text><rect x=\"530\" y=\"14\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o servidor</text><path d=\"M115 44 L115 290\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M605 44 L605 290\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M115 70 L605 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-lost-answer-ah-phosphor)\"></path><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">adicionar sessão de 30 minutos</text><rect x=\"612\" y=\"98\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"662.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">adiciona: 180 → 210</text><path d=\"M605 136 L380 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"372\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--amber)\">✕</text><text x=\"470\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a resposta se perde no caminho</text><rect x=\"8\" y=\"168\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"58.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">o prazo passa:</text><text x=\"58.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">não veio resposta</text><path d=\"M115 214 L605 234\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-lost-answer-ah-phosphor)\"></path><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">adicionar sessão de 30 minutos, de novo</text><rect x=\"612\" y=\"240\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"662.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">adiciona outra:</text><text x=\"662.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">210 → 240</text></svg>", "caption": "Um timeout diz ao celular que nenhuma resposta chegou, não que nada aconteceu. Uma requisição que muda alguma coisa pode ser feita duas vezes."}
```

Para "marcar a sessão `s3` como concluída" isso é inofensivo, porque fazer duas vezes a deixa
concluída, exatamente como o `markDone` faz na aula 1. Para "adicionar uma sessão de 30 minutos na
quinta" é uma segunda sessão, e a semana da aluna agora diz 210 minutos planejados em vez de 180.
Nada falhou, e a tela está errada.

A tabela é a regra que este curso deixa com você; as ferramentas para segui-la vêm depois.

| requisição | enviada duas vezes | tentar de novo depois de um timeout? |
|---|---|---|
| ler a semana | a mesma resposta duas vezes | sim |
| marcar uma sessão como concluída | concluída, uma vez | sim: dá no mesmo |
| adicionar uma sessão | duas sessões | só com uma chave que deixe o servidor reconhecer a repetição |
| pagar uma assinatura | duas cobranças | só com essa chave, e nada mais serve |

**A chave das duas últimas linhas se chama chave de idempotência**: o app inventa um id único para a
operação uma vez, manda esse id em toda tentativa, e o servidor se recusa a executar o mesmo id duas
vezes. O curso `mobile-offline` constrói o resto em volta dela: a aula 8 guarda essas operações numa
fila no aparelho, a *outbox*, para que sobrevivam ao app ser morto; a aula 9 é o backoff; e a aula
10 é a própria chave, com o pagamento que foi feito duas vezes.

## Quando tentar de novo

A terceira pergunta é quando, e a rede dá uma resposta melhor que o relógio. **Uma requisição que
falhou porque não havia rede é mais bem repetida quando o sistema avisa que a rede voltou**, que é o
callback da primeira etapa desta aula. Uma requisição que falhou com 503 é repetida depois de um
backoff. E uma requisição que o usuário está esperando ganha algumas tentativas rápidas, e depois
uma tela que diz o que aconteceu e oferece um botão: a próxima etapa é essa tela.
