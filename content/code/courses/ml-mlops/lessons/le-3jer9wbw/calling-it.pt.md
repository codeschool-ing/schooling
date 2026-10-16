---
title: Chamando o serviço, e as respostas que não são notas
version: 1
---

No primeiro terminal, três pedidos e uma medição de tempo:

```
ana@dev:~/ml$ curl -s http://127.0.0.1:8000/lapse/2; echo
{"member_id":2,"p_lapse":0.098,"features_as_of":"2026-02-28","model_version":1}
ana@dev:~/ml$ curl -s -i http://127.0.0.1:8000/lapse/8; echo
HTTP/1.1 404 Not Found
date: Fri, 16 Oct 2026 00:45:10 GMT
server: uvicorn
content-length: 53
content-type: application/json

{"detail":"no features fresh enough for this member"}
ana@dev:~/ml$ curl -s http://127.0.0.1:8000/lapse/abc; echo
{"detail":[{"type":"int_parsing","loc":["path","member_id"],"msg":"Input should be a valid integer, unable to parse string as an integer","input":"abc"}]}
ana@dev:~/ml$ curl -s -o /dev/null -w "%{time_total}\n" http://127.0.0.1:8000/lapse/2
0.011410
```

**O membro 2** recebe uma probabilidade, a data dos atributos de onde ela saiu e a versão do modelo,
tudo o que alguém depurando uma nota estranha precisa na própria resposta. **O membro 8** recebe
`404 Not Found` com o motivo no corpo: o armazenamento online da lição 6 o deixou de fora por estar
velho demais, e o serviço diz isso em vez de inventar uma nota. **`abc`** nunca chega à função: o
FastAPI responde `422` e diz qual parte do pedido estava errada.

**A última linha é a ida e volta inteira, em segundos**, medida pelo `curl`: cerca de um centésimo
de segundo na máquina da gravação, para um pedido que leu uma linha do SQLite e fez uma predição. É
esse o número que a lição 9 acompanha, junto com o de todos os outros pedidos.

A probabilidade do membro 2 aqui, 0,098, não é o 0,090 que a lição 7 imprimiu para o mesmo membro, e
as duas estão certas: a lição 7 pontuou o membro em 30 de novembro, e este serviço o pontua pelo
fotografia desta noite. Uma nota é sempre uma nota *em* alguma data, e é por isso que a resposta traz a
data.

Pare o serviço com Ctrl+C no terminal dele quando terminar; a lição 9 o inicia de novo.
