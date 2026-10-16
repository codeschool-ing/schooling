---
title: O handler, e o runtime que o chama
version: 1
---

Uma função Lambda parece, vista de fora, um programa que começa quando chega um pedido e termina
quando ele é respondido. **Essa imagem está errada justo na parte que custa dinheiro e tempo.** O
que o Lambda inicia é um **ambiente de execução**: uma pequena máquina isolada com o seu código e um
runtime da linguagem dentro. O runtime importa o seu arquivo uma vez e depois chama uma função dele,
o handler, uma vez por evento, enquanto o Lambda mantiver esse ambiente vivo. Tudo nesta aula, e as
partidas a frio da aula 17, decorre dessa separação entre a importação e a chamada.

## Um handler, peça por peça

O redimensionador é demais para uma primeira função, então esta cumprimenta. Crie um diretório para
ela, `mkdir -p ~/aws/greet`, e salve isto como `~/aws/greet/app.py`; as notas não são copiadas:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "import json\nimport time\n\nLOADED = time.time()\n\n\n", "note": "Tudo no nível do módulo roda **uma vez por ambiente de execução**, quando o runtime importa o arquivo, antes do primeiro evento. `LOADED` guarda quando foi isso, então cada resposta pode dizer há quanto tempo esta cópia da função está viva."}, {"code": "def handler(event, context):\n", "note": "O handler é o nome que você dá ao Lambda como `app.handler`: o arquivo `app.py` e a função `handler` dentro dele. Ele é chamado uma vez por evento, com dois argumentos."}, {"code": "    if event.get('fail'):\n        raise ValueError('asked to fail')\n    name = event.get('name', 'world')\n", "note": "`event` é o JSON que quem chamou enviou, já convertido num dicionário. O formato é o que quem chama decidir; a aula 15 mostra os formatos que o S3, o SQS e os outros enviam. Uma exceção levantada aqui é o erro da função, e quem chamou fica sabendo."}, {"code": "    print(json.dumps({'msg': 'greeting', 'name': name}))\n", "note": "Tudo o que é impresso vai para o log da função, que na AWS é o CloudWatch Logs. Um objeto JSON por linha é um log que uma consulta consegue filtrar."}, {"code": "    return {\n        'greeting': f'hello, {name}',\n        'request_id': context.aws_request_id,\n        'remaining_ms': context.get_remaining_time_in_millis(),\n        'memory_mb': context.memory_limit_in_mb,\n        'warm_for_s': round(time.time() - LOADED, 3),\n    }\n", "note": "`context` é o lado do runtime na chamada: o id deste pedido, os milissegundos que faltam até o timeout, a memória que a função recebeu. O que o handler devolve é serializado em JSON e vira a resposta."}]}
```

**O contrato é dois argumentos de entrada e um valor JSON de saída.** O Lambda nunca roda o `app.py`
como script, então não há `if __name__ == '__main__'` e nada lê a entrada padrão. O nome
`app.handler` é a configuração que liga as duas coisas: a próxima seção o entrega ao `aws lambda
create-function`, e o emulador abaixo o recebe na linha de comando.

## Rodando de verdade, no seu laptop

O moto guarda um registro da função e não a executa aqui, como a próxima seção mostra. Para ver um
handler sendo chamado de fato, este curso usa **a imagem que a AWS publica para construir funções
Lambda como contêineres**, `public.ecr.aws/lambda/python:3.12`. Ela traz o mesmo runtime Python que
o Lambda usa e o **Runtime Interface Emulator**, um pequeno servidor que aceita uma invocação por
HTTP e conduz o runtime como o próprio serviço do Lambda conduz. É a primeira vez que este curso
precisa de Docker para o Lambda, e os passos são os que o curso `docker` ensinou, em resumo:

```sh
docker --version
docker pull public.ecr.aws/lambda/python:3.12
```

O primeiro imprime a versão do Docker que você instalou naquele curso; se falhar, a aula de
instalação daquele curso é o lugar para voltar. O segundo baixa cerca de 180 MB, uma vez só. A
imagem já estava na máquina onde estas transcrições foram gravadas:

```
ana@laptop:~/aws$ docker image ls public.ecr.aws/lambda/python
IMAGE                               ID             DISK USAGE   CONTENT SIZE   EXTRA
public.ecr.aws/lambda/python:3.12   1965397387ba        725MB          183MB        
ana@laptop:~/aws$ docker image inspect public.ecr.aws/lambda/python:3.12 --format '{{.Os}}/{{.Architecture}}'
linux/amd64
```

`linux/amd64` é a cópia de uma máquina x86; num laptop Arm, o Docker baixa a `arm64` com o mesmo
nome. Agora inicie a função, com o diretório montado onde o Lambda põe o seu código, `/var/task`, e
o handler nomeado como o Lambda o nomearia. A porta 9000 da sua máquina chega à 8080 do emulador, e
cada `curl` é uma invocação:

```
ana@laptop:~/aws/greet$ docker run --rm -d --name greet -p 9000:8080 -v "$PWD":/var/task:ro public.ecr.aws/lambda/python:3.12 app.handler
b50acffe515f4c8da1c5b4f4a3bc0418ab31d9f7695378c73cbcd000246ea081
ana@laptop:~/aws/greet$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{"name": "ana"}'; echo
{"greeting": "hello, ana", "request_id": "1e3d5af4-31db-4163-985f-addb24aeeae1", "remaining_ms": 299949, "memory_mb": "3008", "warm_for_s": 0.002}
ana@laptop:~/aws/greet$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}'; echo
{"greeting": "hello, world", "request_id": "db33bb33-d270-4972-bc2c-4051478fa77b", "remaining_ms": 299999, "memory_mb": "3008", "warm_for_s": 0.014}
ana@laptop:~/aws/greet$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{"fail": true}'; echo
{"errorMessage": "asked to fail", "errorType": "ValueError", "requestId": "8ff0739a-61f7-4aa4-8a51-13f4ed94cc8e", "stackTrace": ["  File \"/var/task/app.py\", line 9, in handler\n    raise ValueError('asked to fail')\n"]}
```

Três eventos, três respostas. As duas primeiras voltaram como o dicionário que o handler devolveu,
com um id de pedido diferente em cada; `memory_mb` é uma string, porque é assim que o runtime a
informa. A terceira levantou uma exceção, e **quem chamou recebeu o erro como dado**: um tipo, uma
mensagem e a pilha, que é o que quem chama de forma síncrona recebe na AWS também, com um cabeçalho
na resposta dizendo que a função falhou. `warm_for_s` aumentou entre as duas primeiras chamadas,
porque o módulo foi importado uma vez e os dois eventos foram tratados pela mesma importação.

## O log, e o que nele é do emulador

```
ana@laptop:~/aws/greet$ docker logs greet 2>&1 | cut -c1-175
16 Oct 2026 16:33:11,638 [INFO] (rapid) exec '/var/runtime/bootstrap' (cwd=/var/task, handler=)
16 Oct 2026 16:33:13,659 [INFO] (rapid) INIT START(type: on-demand, phase: init)
16 Oct 2026 16:33:13,659 [INFO] (rapid) The extension's directory "/opt/extensions" does not exist, assuming no extensions to be loaded.
16 Oct 2026 16:33:13,659 [INFO] (rapid) Starting runtime without AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN , Expected?: false
START RequestId: 85230ba9-81fa-4d65-b202-ee31c4a097fe Version: $LATEST
16 Oct 2026 16:33:13,710 [INFO] (rapid) INIT RTDONE(status: success)
16 Oct 2026 16:33:13,710 [INFO] (rapid) INIT REPORT(durationMs: 50.490000)
16 Oct 2026 16:33:13,710 [INFO] (rapid) INVOKE START(requestId: 1e3d5af4-31db-4163-985f-addb24aeeae1)
{"msg": "greeting", "name": "ana"}
16 Oct 2026 16:33:13,711 [INFO] (rapid) INVOKE RTDONE(status: success, produced bytes: 0, duration: 1.344000ms)
END RequestId: 1e3d5af4-31db-4163-985f-addb24aeeae1
REPORT RequestId: 1e3d5af4-31db-4163-985f-addb24aeeae1	Init Duration: 0.04 ms	Duration: 52.06 ms	Billed Duration: 53 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
START RequestId: bf409612-c549-46c9-a8d9-f2ce1a73e308 Version: $LATEST
16 Oct 2026 16:33:13,722 [INFO] (rapid) INVOKE START(requestId: db33bb33-d270-4972-bc2c-4051478fa77b)
{"msg": "greeting", "name": "world"}
END RequestId: db33bb33-d270-4972-bc2c-4051478fa77b
REPORT RequestId: db33bb33-d270-4972-bc2c-4051478fa77b	Duration: 1.05 ms	Billed Duration: 2 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
16 Oct 2026 16:33:13,723 [INFO] (rapid) INVOKE RTDONE(status: success, produced bytes: 0, duration: 0.922000ms)
START RequestId: 3588d8de-b215-4f4c-926b-5579950e1e11 Version: $LATEST
16 Oct 2026 16:33:13,731 [INFO] (rapid) INVOKE START(requestId: 8ff0739a-61f7-4aa4-8a51-13f4ed94cc8e)
LAMBDA_WARNING: Unhandled exception. The most likely cause is an issue in the function code. However, in rare cases, a Lambda runtime update can cause unexpected function beha
16 Oct 2026 16:33:13,736 [INFO] (rapid) INVOKE RTDONE(status: success, produced bytes: 0, duration: 4.871000ms)
END RequestId: 8ff0739a-61f7-4aa4-8a51-13f4ed94cc8e
REPORT RequestId: 8ff0739a-61f7-4aa4-8a51-13f4ed94cc8e	Duration: 4.98 ms	Billed Duration: 5 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
```

As linhas sem `(rapid)` são as que o log de uma função na AWS também traz, no CloudWatch Logs:
`START`, o que o handler imprimiu, `END` e um `REPORT` por invocação. As linhas `(rapid)` são do
próprio emulador, e mostram a separação com que esta seção começou: uma fase `INIT`, que levou
50,49 ms neste laptop, e depois um `INVOKE` por evento, sem segundo `INIT`.

**Vários números desse log são do emulador e não do Lambda, e vale saber disso.** `Memory Size` é
3008 MB porque o emulador dá isso a toda função se não receber outra instrução; uma função de
verdade tem o que a configuração dela diz, 128 MB por padrão. `Max Memory Used` só repete o tamanho,
onde o Lambda mede. O primeiro `REPORT` põe a inicialização dentro de `Duration` e imprime um `Init
Duration` de 0,04 ms, onde o Lambda informa a importação em `Init Duration` e só o handler em
`Duration`. E `remaining_ms` começou perto de 300.000 porque o timeout do emulador é de cinco
minutos, onde uma função criada com os padrões tem três segundos. Os tempos em si são deste laptop.
**O que vale também na AWS é o formato**, e uma regra: `Billed Duration` é a `Duration` arredondada
para cima até o milissegundo seguinte, 1,05 ms cobrado como 2 ms, que é como o Lambda cobra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Dois ambientes de execução num eixo de tempo. O primeiro roda o INIT uma vez, onde o runtime inicia e o código do nível do módulo roda, depois três fases INVOKE para os eventos 1, 2 e 3, congelado entre elas, e é desligado quando o Lambda decide. O segundo ambiente começa depois, para um evento que chegou enquanto o primeiro estava ocupado, e roda o seu próprio INIT antes do seu INVOKE.\"><defs><marker id=\"life-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um ambiente de execução</text><rect x=\"20\" y=\"36\" width=\"170\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\" font-weight=\"600\">INIT</text><text x=\"105\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o runtime inicia, o módulo roda</text><rect x=\"210\" y=\"36\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">INVOKE</text><text x=\"260\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">evento 1</text><rect x=\"350\" y=\"36\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">INVOKE</text><text x=\"400\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">evento 2</text><rect x=\"490\" y=\"36\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">INVOKE</text><text x=\"540\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">evento 3</text><path d=\"M314 62 L346 62\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\" fill=\"none\"></path><path d=\"M454 62 L486 62\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\" fill=\"none\"></path><text x=\"380\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">congelado entre eventos</text><rect x=\"598\" y=\"36\" width=\"114\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"655\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">desligado</text><text x=\"655\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quando o Lambda quer</text><text x=\"105\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">LOADED é definido aqui,</text><text x=\"105\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">e só aqui</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um segundo, para um evento que chegou enquanto o primeiro estava ocupado</text><rect x=\"350\" y=\"174\" width=\"170\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\" font-weight=\"600\">INIT</text><text x=\"435\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a sua própria importação, do zero</text><rect x=\"540\" y=\"174\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">INVOKE</text><text x=\"590\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">evento 4</text><path d=\"M20 250 L700 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#life-ah)\"></path><text x=\"690\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "Um ambiente de execução importa o código uma vez e depois trata os eventos um por vez. Um segundo ambiente, iniciado para um evento que se sobrepôs, importa tudo de novo; esse INIT repetido é a partida a frio da aula 17, e quantos ambientes rodam ao mesmo tempo é a concorrência da aula 16."}
```

Pare a função antes de seguir:

```
ana@laptop:~/aws/greet$ docker stop greet
greet
```
