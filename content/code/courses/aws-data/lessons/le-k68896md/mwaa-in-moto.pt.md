---
title: O único serviço deste curso que o moto não tem
version: 1
---

**O moto 5.2.3 não tem MWAA nenhum.** Todos os outros serviços deste curso respondem no
laboratório, por pouco que façam por trás da resposta; este não responde, e o jeito como ele deixa
de responder merece uma leitura atenta, porque o erro aponta o culpado errado. Peça os ambientes:

```
ana@laptop:~/aws$ aws mwaa list-environments

aws: [ERROR]: Could not connect to the endpoint URL: "http://api.localhost:4567/environments"
ana@laptop:~/aws$ AWS_ENDPOINT_URL=http://127.0.0.1:4567 aws mwaa list-environments

aws: [ERROR]: Could not connect to the endpoint URL: "http://api.127.0.0.1:4567/environments"
ana@laptop:~/aws$ aws mwaa list-environments --debug 2>&1 | grep -o "'host_prefix': '[^']*'"
'host_prefix': 'api.'
ana@laptop:~/aws$ getent hosts api.localhost; echo "exit $?"
exit 2
```

**A linha de comando não perguntou ao `localhost`; perguntou ao `api.localhost`.** O primeiro erro
cita um endereço que ninguém configurou. O segundo comando prova que é coisa da linha de comando:
com o endpoint dado como endereço IP, ela perguntou a `api.127.0.0.1`, que nem é um nome válido. O
terceiro mostra por quê. A descrição da API do MWAA feita pela AWS, a partir da qual a linha de
comando é construída, diz que essas chamadas vão para um **prefixo de host**, `api.`, posto na frente
de qualquer host que o endpoint indique. Contra a AWS isso transforma
`airflow.sa-east-1.amazonaws.com` em `api.airflow.sa-east-1.amazonaws.com`, um endereço de verdade.
Contra o moto, transforma `localhost` num nome que, como mostra o último comando, esta máquina não
consegue resolver.

## O que a sua máquina mostra depende do resolvedor dela

**Alguns resolvedores respondem a todo nome terminado em `.localhost` com o endereço de loopback**,
como a norma desse nome diz que eles podem, e o do próprio Ubuntu faz isso. Numa máquina assim a
requisição chega ao moto, e o moto não tem nada para entregar:

```
ana@laptop:~/aws$ getent hosts api.localhost
127.0.0.1       api.localhost
ana@laptop:~/aws$ aws mwaa list-environments

aws: [ERROR]: An error occurred (500) when calling the ListEnvironments operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
ana@laptop:~/aws$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4567/environments
404
```

**Agora o nome resolve, a requisição chega, e o moto responde `500`**, um erro de dentro do
servidor; perguntado diretamente pelo mesmo caminho, ele diz `404`, não existe. De um jeito ou de
outro a conclusão é a que a primeira transcrição já tinha alcançado por outro caminho: não há MWAA
aqui com quem falar. Na máquina em que este curso foi gravado o nome não resolve, então a segunda
transcrição foi feita acrescentando esse único nome ao arquivo hosts da máquina dentro da gravação,
e ela é o que verá um aluno cujo resolvedor responde.

**Não "conserte" isso mandando `api.localhost` para algum lugar.** Apontar o nome para o moto, como
faz a segunda transcrição, leva você a um servidor sem MWAA dentro; o único conserto é um servidor
que tenha um, e nada no laboratório deste curso tem. Nada do que vem a seguir nesta lição precisa
dele: a pasta de DAGs é S3, que o moto tem, e a alternativa ao MWAA nas duas últimas seções são dois
serviços que o moto guarda fielmente.

## O que esta lição não consegue mostrar, então

**Tudo o que é do próprio MWAA não foi rodado aqui**: criar um ambiente, o que na AWS demora o
bastante para as pessoas irem fazer outra coisa; o scheduler pegando `nightly_orders.py` no bucket;
um worker ligando o job do Glue; o servidor web; os logs no CloudWatch. Tudo isso é ensinado a partir
do comportamento documentado da AWS. O que o laboratório mostra são as duas coisas que decidem se o
MWAA vale o preço: quanto o ambiente custa enquanto espera, na próxima seção, e como fica o mesmo
pipeline sem ele, nas duas seguintes.
