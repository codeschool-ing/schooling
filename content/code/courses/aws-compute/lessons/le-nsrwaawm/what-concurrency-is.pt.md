---
title: Concorrência é requisições em andamento, não requisições por segundo
version: 1
---

O número que se costuma citar sobre tráfego é requisições por segundo, e é natural supor que os
limites do Lambda estão escritos nele. Não estão. **A concorrência do Lambda é o número de
requisições sendo atendidas no mesmo instante**, e cada uma ocupa um ambiente de execução enquanto
roda. Uma função que recebe cem requisições por segundo pode precisar de dez ambientes ou de
duzentos, e qual dos dois depende de algo que o número do tráfego não menciona: quanto tempo cada
requisição leva.

## Um ambiente, uma requisição

Um ambiente de execução é a pequena máquina isolada que o Lambda inicia para a sua função: o
runtime, o seu código carregado nele e a memória que você configurou. A lição 14 rodou um no seu
próprio computador. **Um ambiente atende uma requisição por vez**, e isso é a primeira surpresa de
quem vem de um servidor web, onde um processo atende centenas de conexões com threads ou com um
event loop. Quando chega uma requisição e todos os ambientes da função estão ocupados, o Lambda
não a põe numa fila atrás deles; ele inicia outro ambiente. A concorrência é a contagem desses
ambientes ocupados agora.

Isso deixa a conta curta. Ela se chama lei de Little, e vale para qualquer sistema em regime
estável, onde o trabalho chega, é atendido e sai:

> requisições em andamento = requisições por segundo × segundos por requisição

Cem requisições por segundo que levam 0,1 s cada mantêm 100 × 0,1 = 10 ambientes ocupados. As
mesmas cem requisições a 2 s cada mantêm 200 ocupados. **Nada no tráfego mudou entre esses dois
números**: a função ficou mais lenta, talvez porque o banco de dados que ela chama passou a levar
dois segundos para responder, e a concorrência dela subiu vinte vezes. É por isso que uma
dependência lenta é o jeito mais comum de uma função Lambda chegar ao limite num dia comum.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Uma linha do tempo de 0 a 2 segundos com três faixas, uma por ambiente de execução. Oito requisições chegam com 0,2 segundo de intervalo e cada uma dura 0,6 segundo; a requisição 1 vai para o ambiente 1, a 2 para o ambiente 2, a 3 para o ambiente 3, e a 4 reaproveita o ambiente 1. Uma marca vertical em 1,1 segundo passa pelas requisições 4, 5 e 6, desenhadas em destaque: três rodando ao mesmo tempo.\"><defs><marker id=\"cc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"16\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma requisição a cada 0,2 s, cada uma durando 0,6 s</text><text x=\"16\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ambiente 1</text><path d=\"M130 112 L690 112\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"16\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ambiente 2</text><path d=\"M130 160 L690 160\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"16\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ambiente 3</text><path d=\"M130 208 L690 208\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"130\" y=\"70\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"211\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">1</text><rect x=\"186\" y=\"118\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"267\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">2</text><rect x=\"242\" y=\"166\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"323\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">3</text><rect x=\"298\" y=\"70\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"379\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">4</text><rect x=\"354\" y=\"118\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"435\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">5</text><rect x=\"410\" y=\"166\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"491\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">6</text><rect x=\"466\" y=\"70\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"547\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">7</text><rect x=\"522\" y=\"118\" width=\"162\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"603\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">8</text><path d=\"M130 222 L704 222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cc-ah)\"></path><path d=\"M130 218 L130 226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"130\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0 s</text><path d=\"M270 218 L270 226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"270\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0,5 s</text><path d=\"M410 218 L410 226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"410\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 s</text><path d=\"M550 218 L550 226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"550\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1,5 s</text><path d=\"M690 218 L690 226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 s</text><path d=\"M438 54 L438 68\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M438 108 L438 116\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M438 156 L438 164\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M438 204 L438 220\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"438\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">em qualquer instante: 3 rodando</text></svg>", "caption": "A lei de Little como contagem. Cinco requisições por segundo a 0,6 s cada dão 5 × 0,6 = 3 requisições em andamento, e três ambientes bastam porque cada um fica livre de novo a tempo da próxima requisição que precisa dele. Uma função mais lenta, com o mesmo tráfego, precisaria de mais faixas.", "same": ["0 s", "1 s", "2 s"]}
```

A figura é a lei desenhada como contagem. As requisições chegam a cada 0,2 s e cada uma dura 0,6 s,
o que dá 5 × 0,6 = 3, e uma linha vertical traçada em qualquer instante cruza três requisições. Os
ambientes são reaproveitados: o que terminou a requisição 1 pega a requisição 4. O Lambda nunca
precisou de um quarto, porque nenhuma das faixas recebeu duas requisições ao mesmo tempo.

## Vendo isso no seu computador

O Runtime Interface Emulator que a lição 14 usou é um único ambiente de execução, e isso faz dele
um bom instrumento para a regra acima. Se você ainda o tem, pule para o handler. Se não tem, dois
passos o trazem de volta: o Docker instalado como o curso `docker` instala, e a imagem base do
Lambda para Python publicada pela AWS, que traz o emulador dentro.

```sh
docker pull public.ecr.aws/lambda/python:3.12
```

O `docker image ls` mostra a imagem, com 725 MB depois de descompactada:

```
ana@laptop:~/aws$ docker image ls public.ecr.aws/lambda/python
IMAGE                               ID             DISK USAGE   CONTENT SIZE   EXTRA
public.ecr.aws/lambda/python:3.12   1965397387ba        725MB          183MB        
```

O handler dorme por dois segundos, o que faz o papel de uma chamada lenta ao banco de dados. Crie
um diretório `~/aws/slow` e salve isto nele como `app.py`:

```python
# slow/app.py
import time


def handler(event, context):
    time.sleep(2)
    return {"slept": 2}
```

Depois inicie o emulador com esse diretório como código da função e chame-o duas vezes, uma
chamada depois da outra. O `-w` faz o `curl` imprimir quanto tempo cada chamada levou:

```
ana@laptop:~/aws$ cd slow
ana@laptop:~/aws/slow$ docker run -d --name slow -p 9000:8080 -v "$PWD":/var/task:ro public.ecr.aws/lambda/python:3.12 app.handler
1412a565fbe9e2044deb5102dc855a77ce8c0e3cd04fb6623530f7fe03b803c1
ana@laptop:~/aws/slow$ curl -s -w ' %{time_total} s\n' -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}'
{"slept": 2} 2.133237 s
ana@laptop:~/aws/slow$ curl -s -w ' %{time_total} s\n' -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}'
{"slept": 2} 2.044136 s
```

Cada chamada levou dois segundos e um pouco, como deveria. Agora as duas chamadas ao mesmo tempo.
O `&` manda cada `curl` para o segundo plano, para que as duas saiam juntas.
O `wait` segura o
prompt até elas terminarem:

```
ana@laptop:~/aws/slow$ for n in 1 2; do curl -s -o /dev/null -w "call $n: HTTP %{http_code} after %{time_total} s\n" -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}' & done; wait
call 1: HTTP 000 after 0.010700 s
call 2: HTTP 000 after 0.019307 s
ana@laptop:~/aws/slow$ docker logs slow 2>&1 | grep -E "REPORT|Reserve|panic"
16 Oct 2026 16:25:50,035 [INFO] (rapid) INIT REPORT(durationMs: 75.911000)
REPORT RequestId: e59da5f6-3bba-4147-b4e5-9f4d1b67836f	Init Duration: 0.14 ms	Duration: 2122.07 ms	Billed Duration: 2123 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 5d29e751-c474-4305-8bc9-d07d23a9faa7	Duration: 2032.36 ms	Billed Duration: 2033 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
16 Oct 2026 16:25:54,162 [INFO] (rapid) ReserveFailed: AlreadyReserved
panic: runtime error: invalid memory address or nil pointer dereference
```

**As duas chamadas falharam em menos de dois centésimos de segundo.** `HTTP 000` é o
`curl` dizendo que nenhuma resposta voltou. As duas linhas `REPORT` do log são as chamadas
anteriores, feitas uma depois da outra, com dois segundos cada; a linha que começa com
`INIT REPORT` é assunto da lição 17. Depois o log diz o que deu errado, com as palavras dele:
`ReserveFailed: AlreadyReserved`. Uma das requisições simultâneas reservou o único ambiente que
havia, a outra pediu esse ambiente enquanto ele estava ocupado, e o emulador não tem um segundo
ambiente para iniciar. O que acontece em seguida é um defeito do emulador, e não um comportamento
do Lambda: ele para com um `panic` do Go, derruba a primeira requisição junto, e a próxima chamada
não encontraria ninguém escutando.

Na AWS as mesmas duas chamadas dão certo, e cada uma leva dois segundos, porque o Lambda atende a
segunda requisição com um segundo ambiente. A concorrência nesse momento é 2. O emulador não
consegue mostrar essa parte, porque é um ambiente só por construção, e o moto também não, porque
não roda código nenhum. O que os dois deixam é a forma da regra: **uma requisição por ambiente, e
a contagem de ambientes é o número em que todo limite do Lambda é escrito.** O resto desta lição
são esses limites.

Remova o que sobrou do contêiner antes de seguir, para liberar a porta:

```sh
docker rm -f slow
```
