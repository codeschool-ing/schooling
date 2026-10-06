---
title: Testando as camadas no laboratório
version: 1
---

Uma defesa em camadas se testa do jeito que se projeta: **suponha que cada camada já falhou e veja se
a próxima segura.** Esta seção faz isso contra o portal da equipe da loja, a partir de uma máquina na
internet. O alvo é o holerite do bruno, que só o bruno e o financeiro deveriam ler.

### Camada 1: ninguém entra sem fazer login

A primeira tentativa é de um estranho sem nada:

```
ana@outside:~$ curl -s http://www.example.com/payslips/bruno
sign in first
```

O `curl` pede ao portal `/payslips/bruno` e o portal responde `sign in first` ("faça login
primeiro"). O login está fazendo o trabalho dele.

### Camada 2: estar logado não é o mesmo que ter permissão

Agora suponha que a primeira camada falhou: a senha da ana vazou, talvez reaproveitada em outro site
que foi invadido. O atacante tem um usuário e uma senha de verdade:

```
ana@outside:~$ curl -s -u ana:lab-ana-pass http://www.example.com/payslips/ana
payslip for ana, September 2026
ana@outside:~$ curl -s -u ana:lab-ana-pass http://www.example.com/payslips/bruno
not yours to read
```

A senha vazada funciona, e abre o holerite **da ana**, que é o estrago desse vazamento. Não abre o
do bruno: o portal verifica não só quem está pedindo, mas se essa pessoa pode ler aquele holerite, e
responde `not yours to read` ("não é seu para ler"). A aula 8 dá nome a essas duas verificações,
autenticação e autorização; aqui basta que sejam duas camadas, e a segunda segurou quando a primeira
caiu.

### Camada 3: o programa não lê o que não precisa

Suponha pior: um defeito no portal deixa um atacante fazê-lo ler qualquer arquivo do servidor. A
planilha de salários mora na mesma máquina. O administrador confere quem pode lê-la e depois tenta
lê-la como a conta com que o portal roda, `shop`:

```
root@www:~# ls -l /srv/hr/salaries.csv
-rw-r----- 1 bruno hr 33 Sep 30 17:00 /srv/hr/salaries.csv
root@www:~# setpriv --reuid=shop --regid=shop --clear-groups cat /srv/hr/salaries.csv
cat: /srv/hr/salaries.csv: Permission denied
```

O `ls -l` mostra que o arquivo é do bruno e do grupo `hr`, e `rw-r-----` quer dizer que o bruno lê e
escreve, membros de `hr` leem, e todos os outros, `shop` incluído, não fazem nada. O `setpriv` roda o
`cat` sob a conta `shop`, exatamente como o portal rodaria, e o sistema operacional recusa:
`Permission denied`. Um defeito na aplicação agora é um defeito que só lê o que `shop` lê. Isso é
menor privilégio, o assunto da aula 6, funcionando como camada.

### Camada 4: alguém veria

Nenhuma das camadas acima avisou ninguém. A quarta é o log do portal:

```
root@www:~# cat /var/log/lab/portal.log
203.0.113.50 - "GET /payslips/bruno HTTP/1.1" 401 -
203.0.113.50 ana "GET /payslips/ana HTTP/1.1" 200 -
203.0.113.50 ana "GET /payslips/bruno HTTP/1.1" 403 -
```

Três linhas, uma por pedido: o endereço de onde veio, o usuário se alguém fez login, a página e a
resposta que o portal deu (401, 200, 403). A segunda e a terceira são as que importam. **A conta da
ana, usada de um endereço na internet em vez do escritório, pediu o holerite de outra pessoa.**
Nenhuma camada acima foi rompida, e o log ainda guarda a prova de que a senha da ana está nas mãos
erradas. Um controle detectivo que alguém lê, ou que dispara um alerta, é o que transforma isso numa
senha trocada na mesma tarde, em vez de uma descoberta meses depois.
