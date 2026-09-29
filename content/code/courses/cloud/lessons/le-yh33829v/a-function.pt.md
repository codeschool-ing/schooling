---
title: "Uma função: um evento entra, um resultado sai"
version: 1
---

Uma função numa plataforma serverless é menor que uma aplicação. **É um ponto de entrada que recebe
um evento, faz o seu trabalho e devolve um resultado**, e a plataforma cuida de tudo em volta: o
processo, o servidor web se houver um, a nova tentativa se falhar. No Lambda esse ponto de entrada se
chama handler, e em Python é uma função comum com dois parâmetros.

Este aqui responde a uma requisição HTTP que chega por um API gateway, no formato que a AWS documenta
para essa integração. Ele lê `name` da query string e responde com uma saudação em JSON:

```schooling-example
{"language": "python", "file": "handler.py", "parts": [{"code": "import json\n\nGREETING = \"hello\"\nserved = 0\n\n", "note": "**Código no nível do módulo roda uma vez**, quando um ambiente de execução novo carrega o arquivo, e não a cada chamada. Tudo o que é caro de criar fica aqui: um cliente de banco de dados, uma configuração lida. `served` é um contador posto aqui de propósito, para mostrar como é o estado entre chamadas."}, {"code": "def handler(event, context):\n    global served\n    served += 1", "note": "O ponto de entrada. A plataforma recebe o nome dele como `handler.handler`: o arquivo, depois a função. `event` é a requisição como um dict do Python, e `context` traz fatos sobre esta chamada, como quanto tempo resta; este handler não o usa."}, {"code": "    params = event.get(\"queryStringParameters\") or {}\n    name = params.get(\"name\", \"world\")", "note": "Com um API gateway, a query string chega já interpretada em `queryStringParameters`. Quando a requisição não tem nenhuma, a chave falta ou vale `null`, conforme o tipo de gateway, e o `or {}` cobre os dois casos."}, {"code": "    body = {\"message\": f\"{GREETING}, {name}\", \"served_by_this_copy\": served}", "note": "O que a resposta diz. `served_by_this_copy` mostra o contador, que só conta as chamadas atendidas por esta cópia da função."}, {"code": "    return {\n        \"statusCode\": 200,\n        \"headers\": {\"Content-Type\": \"application/json\"},\n        \"body\": json.dumps(body),\n    }", "note": "O formato que o gateway espera de volta: um código de status, cabeçalhos e um corpo que é uma **string**, e por isso o dict passa por `json.dumps`. O gateway transforma isso na resposta HTTP que o navegador recebe."}]}
```

Três propriedades do contrato importam mais que o código.

**O evento é dado, e o formato dele pertence a quem o mandou.** Uma requisição HTTP que passa por um
gateway chega com um caminho, cabeçalhos e uma query string. Um lote de mensagens de uma fila chega
como uma lista de registros, e um arquivo que cai num bucket chega como um aviso com o nome do bucket
e a chave. O handler é o mesmo tipo de função em todos os casos, e precisa saber qual formato vai
receber. Duas seções adiante, as origens mais comuns aparecem lado a lado.

**Nada tem garantia de sobreviver entre chamadas.** O contador `served` está ali para deixar isso
visível. Dentro de um ambiente de execução ele guarda o valor de uma chamada para a outra, porque o
processo Python continua vivo enquanto o ambiente é mantido. Mas a plataforma sobe tantos ambientes
quanto o tráfego pede e os descarta quando quer, então duas requisições da mesma pessoa podem cair
em duas cópias diferentes, cada uma com o seu contador. **Tudo o que precisa sobreviver — uma
sessão, um carrinho ou uma contagem — vai para um banco de dados ou um armazenamento fora da
função.**

**Toda chamada tem um timeout.** A função roda até devolver ou até acabar o tempo que você
configurou, e aí a plataforma a interrompe. **No Lambda o padrão é de 3 segundos e pode subir até 15
minutos, nunca além.** Um handler que ainda espera um banco de dados lento quando o tempo acaba não
chega a tratar o erro: ele é cortado, e quem chamou vê uma falha.

Para publicá-la, você informaria à plataforma quatro coisas: o runtime (uma versão do Python), o
handler como `handler.handler` (o arquivo, depois a função), a memória e o timeout. Este curso não
faz nada disso, porque não tem conta; o `aws-foundations` faz isso pelo console e pela linha de
comando.
