---
title: Persistência, e o que ela faz quando um servidor morre
version: 1
---

Algumas aplicações guardam o estado de um visitante na memória do servidor que o atendeu primeiro: o
conteúdo de um carrinho, o fato de ele ter feito login. Mande a próxima requisição para outro servidor e
esse estado não está lá. **A melhor correção é uma aplicação que guarda o estado num lugar compartilhado**,
um banco de dados ou um cache que todo servidor lê, para que qualquer servidor atenda qualquer pessoa. Onde
isso ainda não foi feito, o balanceador precisa mandar cada visitante de volta ao mesmo servidor toda vez,
e isso é a **persistência**, também chamada de sticky sessions.

Um balanceador de camada 7 consegue fazer isso com um cookie. `cookie SERVERID insert` diz ao HAProxy para
acrescentar um cookie próprio à primeira resposta, com o nome do servidor que respondeu, e para mandar toda
requisição seguinte que trouxer esse cookie de volta ao mesmo servidor:

```
ana@lb1:~$ sed -n "/^backend/,\$p" /etc/haproxy/haproxy.cfg
backend web
    balance roundrobin
    cookie SERVERID insert indirect nocache
    server web1 192.0.2.21:80 cookie w1
    server web2 192.0.2.22:80 cookie w2
    server web3 192.0.2.23:80 cookie w3
ana@laptop:~$ curl -s -D - -o /dev/null http://www.example.com/ | grep -i set-cookie
set-cookie: SERVERID=w1; path=/
ana@laptop:~$ for i in $(seq 4); do curl -s -b "SERVERID=w3" http://www.example.com/; done
served by web3
served by web3
served by web3
served by web3
ana@laptop:~$ for i in $(seq 3); do curl -s http://www.example.com/; done
served by web2
served by web3
served by web1
```

A primeira requisição, sem cookie, recebeu **`SERVERID=w1`**, porque o round robin a mandou para `web1`.
Quatro requisições com `SERVERID=w3` foram todas para `web3`, e três sem cookie nenhum continuaram
distribuídas entre `web2`, `web3` e `web1`. **O cookie prende os clientes que o têm e deixa o resto para o
algoritmo.** O valor é um rótulo que a configuração escolheu, de `w1` a `w3`, não o endereço do servidor,
então não conta nada a um visitante curioso sobre a rede atrás do balanceador.

## O servidor fixado morre

Agora o `nginx` de `web3` é parado, fora da tela, e o cliente preso a ele pede de novo:

```
ana@laptop:~$ curl -s -b "SERVERID=w3" http://www.example.com/
<html><body><h1>503 Service Unavailable</h1>
No server is available to handle this request.
</body></html>
```

**503 Service Unavailable.** Dois servidores estavam de pé e um terceiro não, e o balanceador mesmo assim
mandou a requisição para o morto, porque o cookie dizia `w3` e nada tinha avisado o HAProxy de que `web3`
tinha caído. Esta configuração não tem health checks, então ele não tinha como saber. Mandou a requisição
para onde o cookie dizia, a conexão falhou, e não havia outro lugar para onde ele pudesse mandá-la.
Persistência sem health checks transforma um servidor morto numa queda justamente para os usuários que
estavam nele, enquanto todo o resto segue normal e os painéis parecem bem.

Duas linhas resolvem. Eis o backend como o `sed` o imprimiu em `lb1` depois da mudança, com o que cada linha
faz:

```schooling-example
{"language": "conf", "file": "haproxy.cfg", "parts": [{"code": "backend web\n    balance roundrobin", "note": "Os visitantes novos continuam distribuídos por round robin. A persistência só vale para uma requisição que já traz um cookie."}, {"code": "    option redispatch", "note": "Se o servidor que o cookie indica estiver fora do ar, manda a requisição para outro servidor em vez de falhar. Esta linha é nova."}, {"code": "    cookie SERVERID insert indirect nocache", "note": "`insert`: o próprio HAProxy acrescenta o cookie à resposta, então a aplicação não sabe nada dele. `indirect`: um cliente que já tem um válido não o recebe de novo, e ele é tirado da requisição antes de o servidor vê-la. `nocache`: uma resposta que o define é marcada para que um cache compartilhado não a guarde e entregue o cookie de um visitante a outros."}, {"code": "    server web1 192.0.2.21:80 cookie w1 check inter 1s\n    server web2 192.0.2.22:80 cookie w2 check inter 1s\n    server web3 192.0.2.23:80 cookie w3 check inter 1s", "note": "`cookie w1` é o valor que quer dizer este servidor. `check inter 1s` é novo: o HAProxy testa cada servidor a cada segundo, então descobre em segundos que um parou de responder. A aula 16 mostrou essas verificações marcando um servidor como DOWN."}]}
```

```
ana@laptop:~$ curl -s -D - -b "SERVERID=w3" http://www.example.com/ | grep -iE "set-cookie|served"
set-cookie: SERVERID=w1; path=/
served by web1
```

O mesmo cliente, com o mesmo `SERVERID=w3`, foi atendido por **`web1` e recebeu um cookie novo, `w1`**,
então a próxima requisição dele vai direto para `web1`, sem ser redirecionada de novo. É o melhor que um
balanceador pode fazer, e vale deixar claro o que ele não faz: **o que a sessão do visitante tinha na
memória de `web3` morreu com `web3`.** O carrinho está vazio e o login se foi. A persistência leva um
visitante de volta ao mesmo servidor; não consegue tirar o estado dele de um servidor que parou, e esse é o
argumento mais forte para o armazenamento compartilhado do primeiro parágrafo desta seção.
