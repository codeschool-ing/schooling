---
title: Criando, alterando e removendo
version: 1
---

Ler é metade de uma API. A outra metade muda o equipamento, e cada verbo responde do seu jeito.
**`POST` cria** uma rota estática dentro da coleção:

```
ana@ctl:~$ curl -si --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" -H "Content-Type: application/json" -d '{"prefix": "192.0.2.128/25", "next_hop": "198.51.100.1"}' https://edge1.example.net/api/v1/static-routes
HTTP/1.1 201 Created
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:43 GMT
Content-Type: application/json
Content-Length: 80
Location: /api/v1/static-routes/192.0.2.128%2F25

{
  "prefix": "192.0.2.128/25",
  "next_hop": "198.51.100.1",
  "distance": 1
}
```

`201 Created`, e um cabeçalho `Location` com o endereço do novo recurso. A `/` dentro do prefixo
é escrita `%2F`, porque uma barra numa URL separa partes do caminho; isso se chama
**percent-encoding**, e toda API que usa um endereço como chave precisa dele. A rota está mesmo
no roteador, como uma linha de configuração que o `vtysh` mostra:

```
ana@ctl:~$ ssh netops@edge1 "show running-config" | grep "ip route"
ip route 192.0.2.128/25 198.51.100.1
```

**`POST` não é seguro para repetir.** A mesma requisição de novo:

```
ana@ctl:~$ curl -si --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" -H "Content-Type: application/json" -d '{"prefix": "192.0.2.128/25", "next_hop": "198.51.100.1"}' https://edge1.example.net/api/v1/static-routes
HTTP/1.1 409 Conflict
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:43 GMT
Content-Type: application/json
Content-Length: 121

{
  "error": "a static route to 192.0.2.128/25 already exists",
  "existing": "/api/v1/static-routes/192.0.2.128%2F25"
}
```

`409 Conflict`: a rota existe. O servidor disse isso em vez de criar uma segunda cópia, o que uma
API descuidada teria feito, e apontou para a que já existe.

**`PATCH` altera só os campos que envia.** A interface mantém o endereço, o MTU e o estado; só a
descrição muda:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -X PATCH -H "Authorization: Bearer $(cat .token)" -H "Content-Type: application/json" -d '{"description": "branch 1 LAN"}' https://edge1.example.net/api/v1/interfaces/eth2
{
  "name": "eth2",
  "description": "branch 1 LAN",
  "enabled": true,
  "oper_status": "up",
  "mtu": 1500,
  "mac_address": "52:54:00:00:71:01",
  "addresses": [
    "203.0.113.1/26"
  ]
}
```

**`DELETE` remove, e remover duas vezes não é um erro da rede**: a segunda requisição não
encontra nada e diz `404`, e a rota some de qualquer jeito.

```
ana@ctl:~$ curl -si --cacert lab-ca.pem -X DELETE -H "Authorization: Bearer $(cat .token)" https://edge1.example.net/api/v1/static-routes/192.0.2.128%2F25
HTTP/1.1 204 No Content
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:44 GMT
Content-Length: 0

ana@ctl:~$ curl -si --cacert lab-ca.pem -X DELETE -H "Authorization: Bearer $(cat .token)" https://edge1.example.net/api/v1/static-routes/192.0.2.128%2F25
HTTP/1.1 404 Not Found
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:44 GMT
Content-Type: application/json
Content-Length: 51

{
  "error": "no static route to 192.0.2.128/25"
}
```

Mais duas recusas, e as duas são o servidor protegendo o roteador. Um prefixo com bits de host
ligados é recusado com `422 Unprocessable Entity`, o que quer dizer que o JSON estava certo e o
significado dele não:

```
ana@ctl:~$ curl -si --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" -H "Content-Type: application/json" -d '{"prefix": "192.0.2.130/25", "next_hop": "198.51.100.1"}' https://edge1.example.net/api/v1/static-routes
HTTP/1.1 422 Unprocessable Entity
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:44 GMT
Content-Type: application/json
Content-Length: 107

{
  "error": "'192.0.2.130/25' is not a network in CIDR form, such as 192.0.2.0/24",
  "field": "prefix"
}
```

E um verbo que o recurso não suporta é `405`, com um cabeçalho `Allow` listando os que ele
suporta:

```
ana@ctl:~$ curl -si --cacert lab-ca.pem -X DELETE -H "Authorization: Bearer $(cat .token)" https://edge1.example.net/api/v1/interfaces/eth2
HTTP/1.1 405 Method Not Allowed
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:44 GMT
Content-Type: application/json
Content-Length: 66
Allow: GET, PATCH

{
  "error": "DELETE is not allowed on /api/v1/interfaces/eth2"
}
```

**Um script deve criar com `PUT` no endereço do próprio item quando puder**, porque `PUT` é
idempotente: enviar o mesmo corpo duas vezes deixa o roteador como enviar uma vez. Este lê
primeiro, só escreve quando a rota é diferente, e diz o que aconteceu:

```schooling-example
{
  "language": "python",
  "file": "static.py",
  "parts": [
    {
      "code": "import sys\n\nfrom devapi import Device\n"
    },
    {
      "code": "WANT = {\"prefix\": \"192.0.2.128/25\", \"next_hop\": \"198.51.100.1\", \"distance\": 10}\npath = \"/static-routes/\" + WANT[\"prefix\"].replace(\"/\", \"%2F\")\n\nedge1 = Device(sys.argv[1] if len(sys.argv) > 1 else \"edge1\")",
      "note": "**A rota pela qual este script responde**, como dado. `PUT` no endereço da própria rota quer dizer \"deixe exatamente assim\", então rodar o script duas vezes dá o mesmo resultado."
    },
    {
      "code": "current = next((r for r in edge1.all(\"/static-routes\") if r[\"prefix\"] == WANT[\"prefix\"]), None)\nif current == WANT:\n    print(f\"{WANT['prefix']}: already as intended\")\nelse:\n    edge1.request(\"PUT\", path, json=WANT)\n    print(f\"{WANT['prefix']}: {'created' if current is None else 'updated'}\")",
      "note": "**Ler primeiro, escrever só se diferir**, e informar qual foi o caso."
    }
  ]
}
```

```
ana@ctl:~$ python static.py
192.0.2.128/25: created
ana@ctl:~$ python static.py
192.0.2.128/25: already as intended
```
