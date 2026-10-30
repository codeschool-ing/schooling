---
title: Trinta segundos de aviso, pelo Scheduled Events
version: 1
---

É natural esperar que um despejo chegue como chega um desligamento: o sistema operacional é avisado,
os serviços param em ordem, e os programas recebem um sinal e um instante para terminar. **Nada na
documentação promete à máquina um sinal próprio. Um programa na máquina tem de perguntar, a cada
segundo, e se perguntar a tempo fica sabendo de um despejo no máximo trinta segundos antes de ele
acontecer.** O serviço a que ele pergunta é o Scheduled Events, parte do Instance Metadata Service, e
o que o programa faz com a resposta decide se o despejo perde meio minuto de trabalho ou meia noite.

Nada nesta seção foi executado. Um laptop não tem serviço de metadados, e este curso não imita um. O
que segue é a documentação da Microsoft, lida em 2026-10-30, e o único programa daqui foi compilado e
nunca rodou contra o Azure.

## Onde o aviso aparece

O Instance Metadata Service responde em `169.254.169.254`, um endereço que não é roteável e só é
alcançável de dentro da máquina; a documentação diz que a conversa nunca sai do host. É o mesmo
serviço de onde uma identidade gerenciada tira seus tokens. O Scheduled Events é um caminho dele, e
esta é a requisição, de um terminal na máquina:

```sh
curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/scheduledevents?api-version=2020-07-01"
```

Três detalhes dessa linha são obrigatórios. O cabeçalho `Metadata:true` tem de ser enviado,
senão o serviço responde *Bad Request*. A `api-version` tem de ser dada, e `2020-07-01` é a
atual. E nenhum proxy: a documentação diz que o serviço não é feito para ser alcançado por um.
As configurações de proxy padrão de um cliente têm de ser contornadas mesmo onde ninguém sabe de
proxy algum, e é isso que `--noproxy "*"` faz.

A documentação acrescenta um quarto detalhe, que muda o jeito de rodar o ouvinte. **O Scheduled
Events é ligado para uma máquina pela primeira requisição dela**, essa primeira resposta pode levar
até dois minutos, e os eventos começam a chegar em até cinco; uma máquina que não pergunta nada por
24 horas é desligada de novo. Então um ouvinte iniciado quando se desconfia de um problema já chegou
tarde. Ele começa no boot, junto com a máquina, e continua perguntando.

## Como é um despejo

A resposta é um documento com um número, `DocumentIncarnation`, que sobe toda vez que a lista de
eventos muda, e a própria lista. Uma lista vazia quer dizer que nada está planejado. Cinco tipos de
evento podem aparecer, e cada um tem um aviso mínimo:

| `EventType` | o que quer dizer | aviso mínimo |
| --- | --- | --- |
| `Freeze` | a máquina pausa por alguns segundos | 15 minutos |
| `Reboot` | a máquina reinicia | 15 minutos |
| `Redeploy` | a máquina muda para outro host | 10 minutos |
| `Preempt` | a máquina Spot está sendo despejada | 30 segundos |
| `Terminate` | uma instância de scale set está sendo apagada | de 5 a 15 minutos, configurados no conjunto |

`Preempt` é o despejo Spot, e os 30 segundos dele vêm com uma ressalva em dois lugares. A página do
Scheduled Events diz que o evento "is made available on a best effort basis"; a página do Spot diz
que o aviso é entregue em regime de melhor esforço "up to 30 seconds prior to the eviction". **Lidas
juntas, isso dá trinta segundos no máximo, e possivelmente nenhum.** O aviso mais longo que um scale
set pode dar antes de apagar uma instância também não ajuda: a documentação de scale sets diz que as
notificações de término não podem ser ativadas em instâncias Spot.

Aqui está um Preempt. Este é **o exemplo da documentação**, citado da página da Microsoft sobre
implantar máquinas Spot com a CLI do Azure, onde ele é a resposta depois de um despejo simulado,
pedida com a versão mais antiga `2019-08-01`. Ele não foi produzido neste curso:

```json
{"DocumentIncarnation":1,"Events":[{"EventId":"A123BC45-1234-5678-AB90-ABCDEF123456","EventStatus":"Scheduled","EventType":"Preempt","ResourceType":"VirtualMachine","Resources":["myspotvm"],"NotBefore":"Tue, 16 Mar 2021 00:58:46 GMT","Description":"","EventSource":"Platform"}]}
```

`EventStatus` é `Scheduled`, que quer dizer planejado e ainda não começado. `NotBefore` é a hora antes
da qual ele não começa, então é o fim da janela. `Resources` nomeia as máquinas que o evento afeta, e
vale conferir. A documentação diz que os eventos de todas as máquinas de um availability set ou de um
placement group de scale set são entregues a todas as máquinas dele, então um ouvinte que reagisse a
todo Preempt que visse poderia drenar uma máquina que não estava sendo despejada. Não há status
`Completed`. Um evento que já aconteceu simplesmente some da lista, e a `2020-07-01` acrescenta um
campo `DurationInSeconds` que este exemplo mais antigo não tem.

## Dizendo que está pronta

Quando a máquina termina de se preparar, ela pode dizer isso com um `POST` no mesmo endereço,
nomeando o evento:

```sh
curl -s -H Metadata:true --noproxy "*" -X POST -d '{"StartRequests": [{"EventId": "A123BC45-1234-5678-AB90-ABCDEF123456"}]}' "http://169.254.169.254/metadata/scheduledevents?api-version=2020-07-01"
```

Também não executado. **Confirmar deixa o evento seguir antes; não confirmar não o impede.** No
`NotBefore` o evento começa, diga a máquina o que disser. O serviço responde 200 a qualquer id de
evento válido, mesmo um que outra máquina já confirmou, e 400 a uma requisição malformada. A
documentação avisa que uma confirmação libera o evento para todas as máquinas do `Resources` dele,
não só para a que a enviou, então num grupo ela sugere que uma máquina, uma líder, faça as
confirmações. Para uma máquina Spot sozinha, a lista é só ela mesma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Uma linha do tempo de um despejo Spot como a Microsoft o documenta. Um evento Preempt aparece na lista do Scheduled Events, e no máximo 30 segundos depois, em regime de melhor esforço, chega a hora NotBefore dele, a partir da qual a máquina é despejada. O ouvinte, que pergunta a cada segundo, vê o evento em menos de um segundo e drena: para de aceitar trabalho, grava um checkpoint e manda o relatório parar com SIGTERM. Depois confirma com um POST de StartRequests, e a partir daí o Azure pode seguir antes; senão, o despejo espera o NotBefore.\"><defs><marker id=\"se-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30 150 L700 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#se-ah)\"></path><path d=\"M70 140 L70 160\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M130 140 L130 160\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M440 140 L440 160\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M610 140 L610 160\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70 72 L70 62 L610 62 L610 72\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"340\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">no máximo 30 segundos, em regime de melhor esforço</text><text x=\"62\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">o Preempt aparece</text><text x=\"62\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na lista de eventos</text><text x=\"610\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">NotBefore</text><text x=\"610\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">despejada daqui em diante</text><text x=\"122\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">o ouvinte o vê</text><text x=\"122\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ele pergunta a cada segundo</text><text x=\"432\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">confirmado</text><text x=\"432\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">POST StartRequests</text><rect x=\"122\" y=\"212\" width=\"298\" height=\"48\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"271\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">parar de aceitar trabalho, gravar um checkpoint</text><text x=\"271\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e mandar o relatório parar</text><rect x=\"432\" y=\"212\" width=\"258\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"561\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o Azure pode seguir antes</text><text x=\"561\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">senão, espera o NotBefore</text><text x=\"704\" y=\"16\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">fora de escala</text></svg>", "caption": "Os trinta segundos de um Preempt, como a documentação os descreve. Fora de escala, e não observados neste curso. Confirmar pode encurtar a janela; não confirmar nunca a alonga."}
```

## Um ouvinte, inteiro

Aqui está um ouvinte para a máquina do relatório, em Python com nada além da biblioteca padrão. Ele lê
a lista de eventos a cada segundo e, num Preempt para esta máquina, manda o relatório parar e depois
confirma. Copie com o botão do bloco e salve como `spot-watch.py`:

```schooling-example
{"language": "python", "file": "spot-watch.py", "parts": [{"code": "# spot-watch.py: watch Scheduled Events, and drain the worker on a Preempt\nimport json\nimport os\nimport signal\nimport time\nimport urllib.request\n\nMD = 'http://169.254.169.254/metadata'\nEVENTS = MD + '/scheduledevents?api-version=2020-07-01'\nNAME = MD + '/instance/compute/name?api-version=2025-04-07&format=text'\nPIDFILE = os.environ.get('PIDFILE', '/run/worker.pid')\nDIRECT = urllib.request.build_opener(urllib.request.ProxyHandler({}))\nHANDLED = set()\n\n\n", "note": "Os dois endereços que o ouvinte consulta: a lista de eventos, na versão atual, e o nome da própria máquina, que é como um evento a nomeia. `PIDFILE` é onde o relatório grava o id do seu processo. `DIRECT` é um opener sem proxy nenhum, como o serviço de metadados exige, seja qual for o proxy que o ambiente da máquina indica. `HANDLED` lembra os eventos já tratados."}, {"code": "def ask(url, body=None):\n    request = urllib.request.Request(url, data=body, headers={'Metadata': 'true'})\n    with DIRECT.open(request, timeout=5) as answer:\n        return answer.read().decode()\n\n\n", "note": "Toda requisição leva `Metadata: true`, senão o serviço a recusa. Um corpo transforma a requisição num `POST`, que é como um evento é confirmado. Cinco segundos é o máximo que ela espera, para que uma requisição travada não gaste o aviso inteiro."}, {"code": "def log(**fields):\n    print(json.dumps(fields), flush=True)\n\n\n", "note": "Uma linha JSON para cada coisa que acontece, o hábito que o log da própria loja já tem."}, {"code": "def handle(event, me):\n    mine = me.lower() in [r.lower() for r in event['Resources']]\n    if event['EventType'] != 'Preempt' or not mine or event['EventId'] in HANDLED:\n        return\n    HANDLED.add(event['EventId'])\n    log(msg='preempt', not_before=event['NotBefore'])\n    with open(PIDFILE) as f:\n        os.kill(int(f.read()), signal.SIGTERM)\n    body = json.dumps({'StartRequests': [{'EventId': event['EventId']}]})\n    ask(EVENTS, body.encode())\n    log(msg='acknowledged', event=event['EventId'])\n\n\n", "note": "Só importa um Preempt que nomeie esta máquina, comparado sem diferença entre maiúsculas e minúsculas, e só uma vez. Depois, drenar: `SIGTERM` diz ao relatório que grave um checkpoint e saia. Depois, confirmar, para que o despejo possa seguir antes. Se algo aqui falhar, o despejo acontece mesmo assim no `NotBefore`."}, {"code": "me, seen = None, None\nwhile True:\n    try:\n        me = me or ask(NAME)\n        doc = json.loads(ask(EVENTS))\n        if doc['DocumentIncarnation'] != seen:\n            seen = doc['DocumentIncarnation']\n            log(msg='document', incarnation=seen, events=len(doc['Events']))\n            for event in doc['Events']:\n                handle(event, me)\n    except (OSError, ValueError, KeyError) as err:\n        log(msg='no usable answer', error=repr(err))\n    time.sleep(1)\n", "note": "Perguntar uma vez por segundo. O nome é pedido uma vez e guardado. Um `DocumentIncarnation` novo quer dizer que a lista mudou e é lida de novo; o mesmo número quer dizer nada de novo. O que der errado vai para o log, e o laço dá mais uma volta."}]}
```

Na máquina ele rodaria como um serviço iniciado no boot, ao lado do relatório. Uma vez por segundo é
a recomendação da documentação, e fica dentro do limite do próprio serviço, cinco requisições por
segundo por máquina, acima do qual o serviço responde 429. **Toda falha nele vai para o log e o laço
continua**, porque um ouvinte que quebra com uma resposta inesperada para de ouvir justamente no
momento em que é preciso.

Testá-lo precisa de uma assinatura, e a Microsoft oferece um jeito de provocar o evento. Contra uma
máquina Spot de verdade, isto pede ao Azure que simule um despejo dela, e o ouvinte na máquina deve
então ver um Preempt como o do exemplo da documentação acima. Não foi executado neste curso:

```sh
az vm simulate-eviction --resource-group shop --name shop-report-1
```

## Para que servem trinta segundos

Trinta segundos bastam para parar e são curtos demais para terminar qualquer coisa. Drenar, então, é
uma lista curta de coisas a deixar de fazer:

1. parar de aceitar trabalho novo: sair do pool do load balancer, parar de ler a fila;
2. anotar até onde o trabalho em mãos chegou, num lugar que sobreviva à máquina. O guia diz para
   guardar os checkpoints fora da máquina Spot, numa conta de armazenamento, por exemplo;
3. largar o que não terminou, para que outra máquina o assuma. Uma fila faz isso sozinha quando uma
   mensagem não é concluída, como a lição 20 mostra.

O relatório faz o segundo desses, e é por isso que o disco da máquina dele não importa: ele grava um
checkpoint no Blob Storage a cada meia hora, e o tratamento de `SIGTERM` dele grava mais um e sai. O
guia também avisa que uma máquina Spot pode ser despejada logo depois de criada, antes de qualquer
ouvinte estar rodando, então nada que substitui máquinas pode depender da chegada do aviso. **Um
trabalho que pode ser parado a qualquer momento não precisa de nada desta seção**, e esse é o
argumento mais forte para escrevê-lo assim.
