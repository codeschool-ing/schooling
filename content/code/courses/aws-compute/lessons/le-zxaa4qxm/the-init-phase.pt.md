---
title: O que acontece antes de o handler rodar
version: 1
---

Um cold start costuma ser descrito como "o Lambda acordando", como se o próprio serviço demorasse a
responder. **Um cold start é o trabalho de montar um ambiente de execução novo antes que a
requisição possa ser entregue ao seu handler**, e a maior parte desse trabalho nem é do Lambda:
parte é o runtime iniciando, e parte é o seu próprio código, executado uma vez no topo do arquivo.
Ele acontece sempre que uma requisição precisa de um ambiente e nenhum está livre.
A lição 16 mostrou que isso é uma questão de concorrência: a primeira requisição do dia, uma requisição que chega
enquanto as outras estão ocupadas, uma requisição depois que o Lambda aposentou um ambiente parado.

## As fases, em ordem

A AWS documenta a vida de um ambiente em três fases, e uma requisição fria passa pelas duas
primeiras em sequência.

1. Init. O Lambda encontra um host com espaço, cria a micro-VM isolada e busca o seu código: o zip
   no armazenamento do próprio Lambda, ou as camadas de uma imagem de contêiner. Depois inicia o
   runtime, que para Python é o interpretador e o pequeno programa de bootstrap da AWS, e o runtime
   importa o seu módulo. **Tudo o que está no nível de cima do arquivo roda aqui**: as linhas de
   `import`, um cliente construído fora do handler, um arquivo de configuração lido uma vez.
2. Invoke. O runtime chama o seu handler com o evento, e o valor que o handler devolve volta para
   quem chamou. Essa é a fase que toda requisição tem.
3. Shutdown. Quando o Lambda decide aposentar um ambiente, ele para o runtime. O seu handler não é
   chamado para isso, e o que o ambiente guardava na memória se perde.

Uma requisição quente é só a segunda fase. **A diferença entre uma requisição fria e uma quente é a
primeira fase inteira**, e a parte dela que você controla é a parte que o seu módulo faz ao ser
importado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Duas linhas num eixo de tempo. Uma requisição fria passa por posicionar o ambiente e buscar o código, o que só acontece na AWS, depois por iniciar o runtime, depois por rodar o seu módulo, em destaque, e só então pelo handler. As três primeiras estão agrupadas como a fase init e o handler como invoke. Uma requisição quente é só o handler.\"><defs><marker id=\"ph-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M150 28 L704 28\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ph-ah)\"></path><text x=\"150\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tempo</text><text x=\"16\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">requisição fria</text><rect x=\"150\" y=\"60\" width=\"148\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"224\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">posicionar, buscar código</text><text x=\"224\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" font-style=\"italic\">só na AWS</text><rect x=\"300\" y=\"60\" width=\"108\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"354\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">iniciar runtime</text><rect x=\"410\" y=\"60\" width=\"178\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"499\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">rodar o seu módulo</text><text x=\"499\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">imports, clientes</text><rect x=\"590\" y=\"60\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">handler</text><path d=\"M150 110 L150 118 L588 118 L588 110\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"369\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">fase init</text><path d=\"M590 110 L590 118 L690 118 L690 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"640\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">invoke</text><text x=\"16\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">requisição quente</text><rect x=\"150\" y=\"160\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">handler</text><text x=\"266\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o mesmo ambiente, já inicializado</text><text x=\"704\" y=\"222\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" font-style=\"italic\">uma forma, não uma medição</text></svg>", "caption": "Uma requisição fria é a fase init e depois o handler; uma quente é só o handler. A parte em destaque é o seu próprio módulo rodando no import, o único pedaço da fase init que cabe a você encurtar.", "same": ["handler", "invoke"]}
```

## As fases num log

O emulador das lições 14 e 16 passa pelas mesmas fases, então o log dele as nomeia. Se você não o
tem daquelas lições, a imagem é `public.ecr.aws/lambda/python:3.12`, baixada com `docker pull`
depois que o Docker estiver instalado como o curso `docker` instala.

O menor handler possível, em `~/aws/bare/app.py`, para que nada seu rode na fase init:

```python
# bare/app.py
def handler(event, context):
    return {"ok": True}
```

Inicie, chame duas vezes e leia o log. Os comandos são os que a lição 16 usou:

```
ana@laptop:~/aws$ docker run -d --name bare -p 9000:8080 -v "$PWD/bare":/var/task:ro public.ecr.aws/lambda/python:3.12 app.handler
3776324e020191a0baf97ff4b45708b7ff49ec860f072ed1ecb2903e7d20f5cd
ana@laptop:~/aws$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}'; echo
{"ok": true}
ana@laptop:~/aws$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}'; echo
{"ok": true}
ana@laptop:~/aws$ docker logs bare
16 Oct 2026 16:34:35,291 [INFO] (rapid) exec '/var/runtime/bootstrap' (cwd=/var/task, handler=)
16 Oct 2026 16:34:37,340 [INFO] (rapid) INIT START(type: on-demand, phase: init)
16 Oct 2026 16:34:37,340 [INFO] (rapid) The extension's directory "/opt/extensions" does not exist, assuming no extensions to be loaded.
16 Oct 2026 16:34:37,340 [INFO] (rapid) Starting runtime without AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN , Expected?: false
START RequestId: 8cc8b8b1-f1ed-4621-a439-80b9d2a4791f Version: $LATEST
16 Oct 2026 16:34:37,387 [INFO] (rapid) INIT RTDONE(status: success)
16 Oct 2026 16:34:37,387 [INFO] (rapid) INIT REPORT(durationMs: 47.608000)
16 Oct 2026 16:34:37,387 [INFO] (rapid) INVOKE START(requestId: 66d75f14-983c-46a6-9202-18cd2d3a258f)
16 Oct 2026 16:34:37,388 [INFO] (rapid) INVOKE RTDONE(status: success, produced bytes: 0, duration: 1.094000ms)
END RequestId: 66d75f14-983c-46a6-9202-18cd2d3a258f
REPORT RequestId: 66d75f14-983c-46a6-9202-18cd2d3a258f	Init Duration: 0.14 ms	Duration: 48.74 ms	Billed Duration: 49 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
START RequestId: e619a9a3-8c26-43de-9dc7-e3314316d130 Version: $LATEST
16 Oct 2026 16:34:37,399 [INFO] (rapid) INVOKE START(requestId: 2a744ed9-d025-482b-a1f5-94d7b9a11d1a)
16 Oct 2026 16:34:37,400 [INFO] (rapid) INVOKE RTDONE(status: success, produced bytes: 0, duration: 0.759000ms)
END RequestId: 2a744ed9-d025-482b-a1f5-94d7b9a11d1a
REPORT RequestId: 2a744ed9-d025-482b-a1f5-94d7b9a11d1a	Duration: 1.42 ms	Billed Duration: 2 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
```

Leia o log de cima para baixo, porque a ordem é a lição:

- `exec '/var/runtime/bootstrap'` é o contêiner iniciando. Na AWS o ambiente ainda não existe nesse
  ponto; o emulador inicia o processo cedo e depois espera a primeira requisição.
- `INIT START`, `INIT RTDONE` e `INIT REPORT` são a fase init, executada quando a primeira
  requisição chegou. **O `INIT REPORT` dá a duração dela**, aqui 48 ms: o runtime
  Python iniciando e importando um módulo que não faz nada.
- `START`, `END` e `REPORT` são a fase invoke, uma vez por requisição. O primeiro `REPORT` é a
  requisição fria e o segundo é quente, e o segundo não tem `Init Duration` nenhum.

**Um campo desse log está errado, e é o que as pessoas leem.** Na AWS, a linha `REPORT` de uma
requisição fria traz `Init Duration`, e esse número é a fase init. O emulador imprime ali poucos
milissegundos no máximo, faça o módulo o que fizer, e conta o init de verdade dentro do `Duration`
da primeira requisição. A próxima seção mostra a diferença num módulo que faz trabalho de verdade.
**Neste curso, a fase init é lida no `INIT REPORT`**, que o emulador mede; na AWS, leia no
`Init Duration` do `REPORT`, que é sobre o que as consultas do CloudWatch das lições 8 a 10 de
`aws-operations` são escritas.

## O que o laptop não consegue dizer

Todo milissegundo destes logs é do seu computador, não da AWS. O emulador roda numa CPU de laptop, junto com o que mais o laptop estiver fazendo.
Ele monta o código a partir do seu disco em vez de
baixá-lo, e ignora a configuração de memória: todo `REPORT` aqui diz `Memory Size: 3008 MB`, seja
qual for a memória dada à função. **O que o emulador mede com fidelidade é a forma**: que trabalho
acontece em que fase, e quanto do cold start é o seu próprio módulo. Essas proporções valem na AWS;
os números absolutos não, e a AWS acrescenta uma parte que o laptop nunca paga, o posicionamento do
ambiente e o download do código.

Mais dois fatos da documentação da AWS, e nenhum dos dois um laptop consegue mostrar. A fase init
tem um limite de dez segundos; um módulo que demora mais é interrompido e o init dele é tentado de
novo na fase invoke, sob o timeout da própria função. E desde agosto de 2025 a fase init de uma
função sob demanda é cobrada como a duração do handler, então um import lento passou a ser um
pequeno custo em todo cold start, além de um atraso.
