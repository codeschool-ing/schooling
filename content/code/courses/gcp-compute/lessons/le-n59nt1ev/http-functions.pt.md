---
title: Funções HTTP, e o framework debaixo delas
version: 1
---

A imagem com que a maioria das pessoas chega é que uma função é um servidor pequeno que você
envia: você escreve algo que escuta numa porta, e a nuvem o mantém rodando. **No Google Cloud uma
função é o contrário: um handler que você escreve, e um servidor web que o Google monta em volta
dele.** Você escreve uma função Python que recebe uma requisição e devolve uma resposta. O
servidor, a porta e o contêiner são da plataforma.

## O que a envolve

O envoltório é o **Functions Framework**, uma biblioteca de código aberto que o Google publica para
cada linguagem que suporta. Quando você publica uma função Python, o build do Google instala o
framework, aponta-o para a sua função pelo nome e roda o resultado como um contêiner no Cloud Run;
a lição 8 abre esse contêiner. O framework que você instalou na lição 1 é a mesma biblioteca, então
**uma função que responde no seu laptop sob o framework responde do mesmo jeito depois de
publicada**. O que muda é tudo em volta: quem pode chamá-la, quantas cópias rodam e quanto custa.

É também por isso que este curso consegue praticar funções de verdade quando não consegue
praticar o Compute Engine. Nada aqui imita o Google. O caminho da requisição até a sua função é
código do próprio Google.

## Uma função para a loja

O checkout da loja precisa de uma cotação antes de cobrar: uma lista de produtos e quantidades
entra, um total em centavos sai. **Crie `~/gcp/quote` e salve isto como `main.py` dentro dela:**

```schooling-example
{"language": "python", "file": "main.py", "parts": [{"code": "import functions_framework\n\nPRICES = {'mug': 3500, 'tee': 7900, 'poster': 2500}  # in cents\n\n\n", "note": "O Functions Framework, e os três produtos da loja com os preços em centavos. Dinheiro é inteiro aqui pelo mesmo motivo de sempre: um float não guarda 0,10 exatamente."}, {"code": "@functions_framework.http\ndef quote(request):\n    if request.method != 'POST':\n        return {'error': 'POST a list of items'}, 405\n", "note": "O decorador registra `quote` como função HTTP, e o framework entrega a ela uma requisição do Flask. Um dicionário devolvido com um número vira um corpo JSON com aquele status."}, {"code": "    items = (request.get_json(silent=True) or {}).get('items', [])\n    unknown = [i['sku'] for i in items if i['sku'] not in PRICES]\n    if unknown:\n        return {'error': 'unknown sku: ' + ', '.join(unknown)}, 400\n", "note": "O corpo é lido sem confiar nele: `silent=True` dá `None` para um corpo que não é JSON em vez de uma exceção, e um produto desconhecido é recusado pelo nome."}, {"code": "    total = sum(PRICES[i['sku']] * i['qty'] for i in items)\n    return {'items': len(items), 'total_cents': total}\n", "note": "A conta, e a resposta. Nada fica guardado entre chamadas: a próxima requisição pode cair em outra instância, e a função não pode se importar com isso."}]}
```

Depois abra um **segundo terminal**, digite as linhas da seção 02 da lição 1 que todo terminal
precisa e inicie o framework ali. `--target` dá o nome da função dentro do `main.py`; a porta é a
8080, a menos que você diga outra:

```
ana@laptop:~/gcp/quote$ functions-framework --target quote
```

Ele não imprime nada e fica esperando na porta 8080, o que é o framework funcionando, não falhando.
Deixe-o rodando, volte ao primeiro terminal e chame:

```
ana@laptop:~/gcp/quote$ curl -s -w '%{http_code}\n' -X POST localhost:8080 -H 'content-type: application/json' -d '{"items": [{"sku": "mug", "qty": 2}, {"sku": "tee", "qty": 1}]}'
{"items":2,"total_cents":14900}
200
ana@laptop:~/gcp/quote$ curl -s -w '%{http_code}\n' localhost:8080
{"error":"POST a list of items"}
405
ana@laptop:~/gcp/quote$ curl -s -w '%{http_code}\n' -X POST localhost:8080 -H 'content-type: application/json' -d '{"items": [{"sku": "hat", "qty": 1}]}'
{"error":"unknown sku: hat"}
400
```

Três respostas, três status. **Foi a função que decidiu cada um**: 200 com o total para um pedido
correto, 405 para um `GET`, que ela recusa pelo nome, e 400 para um produto que ela não vende. O
framework só transformou os dicionários devolvidos em JSON e os números em status.

## Não guardar estado não é estilo

Repare no que a função não faz. Ela não mantém contador, não escreve arquivo e não lembra nada de
uma chamada para a outra. Não é capricho. **Duas chamadas com um segundo de diferença podem cair
em duas instâncias diferentes**, e uma instância sem requisições é desligada sem aviso; a lição 11
mede quanto isso custa. Tudo que precisa sobreviver a uma chamada vai para algo feito para
guardar: um banco de dados, um bucket, uma fila.

A única exceção é trabalho caro de repetir e seguro de compartilhar, como a conexão de um cliente
ou uma tabela lida na partida. Ponha no nível do módulo, fora da função, e toda chamada que cair na
mesma instância o reaproveita. O `PRICES` acima é o menor exemplo disso.

Pare o framework com Ctrl+C no terminal dele quando terminar.
