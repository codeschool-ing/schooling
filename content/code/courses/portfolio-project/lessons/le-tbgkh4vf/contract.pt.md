---
title: Erros como parte do contrato
version: 1
---

O passo 8, *Answer every error as JSON*, fez cada linha da tabela responder. Aqui estão todas, uma depois da
outra:

```
ana@laptop:~/loanbook$ curl -s -i localhost:8000/api/nothing
HTTP/1.0 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sun, 27 Sep 2026 06:34:31 GMT
Content-Type: application/json
Content-Length: 43

{"error": "Nothing lives at /api/nothing."}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d 'not json'
{"error": "The body is not JSON."}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/9/loan -d '{"borrower": "Beatriz Nunes"}'
{"error": "There is no item 9."}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d '{"borrower": ""}'
{"error": "Say who is borrowing it."}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d '{"borrower": "Beatriz Nunes"}'
{"item": "Projector 2", "borrower": "Beatriz Nunes", "due_on": "2026-10-04"}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/loan -d '{"borrower": "Carlos Mendes"}'
{"error": "Projector 2 is already lent to Beatriz Nunes until 2026-10-04."}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/return
{"item": "Projector 2", "returned_on": "2026-09-27"}
ana@laptop:~/loanbook$ curl -s -X POST localhost:8000/api/items/1/return
{"error": "Projector 2 is not out, so it cannot come back."}
```

Toda resposta é JSON, e todo erro tem o mesmo formato: **um campo, `error`, com uma frase que uma pessoa
consegue ler.** A página mostra essa frase como veio, então o servidor decide o que o usuário vê, e há um
lugar só para mudar isso. O código de status carrega o tipo de erro para programas: 400 para uma requisição
errada, 404 para algo que não existe, 409 para uma regra que diz não.

O código que faz isso é o tratamento do POST, anotado:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "    def do_POST(self):\n        m = re.fullmatch(r\"/api/items/(\\d+)/(loan|return)\", self.path)\n        if not m:\n            return self.reply(HTTPStatus.NOT_FOUND, {\"error\": f\"Nothing lives at {self.path}.\"})", "note": "Um endereço que não casa com nenhuma rota recebe um 404 no mesmo formato de todo outro erro, em vez da página HTML da biblioteca."}, {"code": "        item_id, action = int(m[1]), m[2]\n        try:\n            body = json.loads(self.rfile.read(int(self.headers.get(\"Content-Length\") or 0)) or b\"{}\")", "note": "A leitura do corpo fica dentro do `try`. Um corpo que não é JSON é erro do cliente, e recebe um 400, não uma conexão derrubada."}, {"code": "            with closing(connect()) as db:\n                if action == \"loan\":\n                    result = lend(db, item_id, body.get(\"borrower\"), date.today())\n                    return self.reply(HTTPStatus.CREATED, result)\n                return self.reply(HTTPStatus.OK, give_back(db, item_id, date.today()))", "note": "O caminho feliz. `lend` e `give_back` não sabem nada de HTTP: quando as regras dizem não, levantam `Refused` com um status e uma frase."}, {"code": "        except json.JSONDecodeError:\n            self.reply(HTTPStatus.BAD_REQUEST, {\"error\": \"The body is not JSON.\"})\n        except Refused as r:\n            self.reply(r.status, {\"error\": r.message})", "note": "Dois tipos de não, cada um virando uma resposta. Nada mais é capturado, de propósito: um erro que ninguém esperava é um bug, e o lugar dele é o log do servidor."}]}
```

Duas coisas nele são decisões que vale saber explicar. **As regras moram em `lend` e `give_back`, que
levantam `Refused`, e só o tratamento conhece HTTP.** É por isso que os testes da aula 12 conseguem
verificar toda regra sem servidor. E **só os erros esperados são capturados.** Um `KeyError` ou um disco
cheio não é erro do usuário, e transformá-los numa frase simpática esconderia um bug da única pessoa que
poderia corrigi-lo.

O que o loanbook não faz, e poderia: um erro inesperado ainda fecha a conexão. Uma resposta melhor é um 500
com uma frase que não diz nada específico, *algo deu errado do nosso lado*, enquanto os detalhes vão para o
log. Isso está anotado na retrospectiva da aula 21 como a próxima mudança.
