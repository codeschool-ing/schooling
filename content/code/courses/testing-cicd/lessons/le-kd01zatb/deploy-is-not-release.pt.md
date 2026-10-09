---
title: Implantar não é liberar
version: 2
---

Tudo até aqui amarrava duas coisas: pôr código novo em produção e mostrá-lo aos clientes. Uma
**feature flag** separa as duas. O código de uma funcionalidade é implantado, mas uma chave lida em
tempo de execução decide quem a vê, e a chave começa desligada.

A versão 1.6.1 corrigiu o erro, e a Ana tomou mais uma precaução: a estimativa de entrega, o campo
novo da cotação, agora fica atrás de uma flag.

```schooling-example
{
  "language": "python",
  "file": "shipquote/flags.py",
  "parts": [
    {
      "code": "def load():\n    path = os.environ.get(\"SHIPQUOTE_FLAGS\")\n    if not path or not os.path.exists(path):\n        return {}\n    with open(path) as f:\n        return json.load(f)",
      "note": "As flags ficam num arquivo indicado por `SHIPQUOTE_FLAGS`, lido a cada requisição. Sem arquivo, sem flags, e toda funcionalidade atrás de uma fica desligada."
    },
    {
      "code": "def enabled(flags, name, customer):\n    \"\"\"On for the flag's percentage of customers, the same ones every time.\"\"\"\n    bucket = int(hashlib.sha256(f\"{name}:{customer}\".encode()).hexdigest(), 16) % 100\n    return bucket < flags.get(name, 0)",
      "note": "O cliente recebe um balde de 0 a 99, a partir de um hash do nome da flag com o id do cliente. A funcionalidade fica ligada para os baldes abaixo da porcentagem da flag. O mesmo cliente cai sempre no mesmo balde, então vê a mesma coisa em toda requisição."
    }
  ]
}
```

O tratador da cotação só acrescenta a estimativa quando a flag manda:

```python
        customer = args.get("customer", [""])[0]
        try:
            body = self.quote_body(cep, cents)
            if flags.enabled(flags.load(), "delivery_estimate", customer):
                body["days"] = quote.delivery_days(cep)
```

A green recebe o 1.6.1 e, desta vez, todo o tráfego de uma vez. Ainda não há arquivo de flags:

```
ana@laptop:~/shipquote$ ops/deploy.sh production-green dist/shipquote-1.6.1.tar.gz
smoke: http://127.0.0.1:8302 is up and running 1.6.1
ana@laptop:~/shipquote$ sed -i 's/"blue": 100, "green": 0/"blue": 0, "green": 100/' ~/envs/routes.json
ana@laptop:~/shipquote$ python3 ops/load.py http://127.0.0.1:8300 2000
backend    requests errors    rate
green          2000      0    0.0%
ana@laptop:~/shipquote$ ls ~/envs/flags.json
ls: cannot access '/home/ana/envs/flags.json': No such file or directory
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990&customer=c7"; echo
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
```

Duas mil requisições, nenhum erro, e uma cotação exatamente igual à do 1.5.0: sem `days`. O código
novo está em produção, rodando, e **nenhum cliente o viu**. Isso às vezes se chama **dark launch**.

## Por que se dar ao trabalho

- **O deploy fica sem graça.** Ele não muda nada que o cliente veja, então pode acontecer a qualquer
  hora, tantas vezes quantas o pipeline produzir releases. O momento arriscado passa para a flag, que
  é uma mudança pequena e separada.
- **Liberar vira decisão de outra pessoa.** Uma gerente de produto pode ligar uma funcionalidade numa
  data de lançamento sem deploy, e desligar sem rollback.
- **Trabalho inacabado pode ser integrado.** Uma funcionalidade que leva três semanas pode ir para o
  branch principal todo dia, desligada, em vez de viver num branch que se afasta de todo o resto. É
  assim que uma equipe que integra no dia em que a mudança é escrita, como pediu a aula 5, lida com
  uma mudança que leva semanas.

O preço é que o código agora tem os dois caminhos, o comportamento antigo e o novo, até alguém
remover um deles. A seção 13 trata desse preço.
