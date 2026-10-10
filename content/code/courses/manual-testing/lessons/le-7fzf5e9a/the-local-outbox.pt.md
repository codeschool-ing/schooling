---
title: A caixa de saída como coletor de e-mail
version: 1
---

Um ambiente de teste que manda e-mail de verdade é um perigo: uma rodada com uma cópia dos dados de
produção e alguns milhares de clientes recebem um link que nunca pediram. **Por isso uma versão de
teste captura o próprio e-mail.** A aplicação continua compondo cada mensagem e continua achando que
a enviou, mas a mensagem para num lugar que o testador consegue ler e não vai adiante. As ferramentas
que fazem isso se chamam **coletores de e-mail** (mail catchers), e o boxoffice tem um embutido: a
caixa de saída, em `/outbox`, com a mensagem mais nova primeiro. A aula 1 disse que ela existia e que
esta aula diria por quê.

Os endereços deste curso ajudam na mesma direção. Todos terminam em `example.org`, um domínio
reservado para exemplos e documentação, então mesmo uma mensagem que escapasse não teria para onde
ir. Dados de teste com endereços de aparência real em domínios reais são o caminho para um estranho
acabar com um link de confirmação na mão.

## Cadastrar, ler, confirmar

Inicie o boxoffice do zero. No navegador, abra Sign up pelos links no pé de qualquer página e crie
uma conta para Caio Lima, `caio@example.org`, com qualquer senha de 8 a 64 caracteres. Do segundo
terminal, a mesma requisição é:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Caio+Lima&email=caio@example.org&password=ticket-office-9' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to caio@example.org.</p>
```

Agora abra o link Outbox. A página mostra uma mensagem, e é o e-mail como o cliente o teria recebido:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/outbox | grep -A 4 '<article>'
<article><h2>Confirm your account</h2><p>To: caio@example.org · 2026-10-10 14:00</p><pre>Hello Caio Lima,

Confirm your account within 24 hours:
http://127.0.0.1:8000/confirm?token=nbm7nh5xugmf6rdv
</pre></article>
```

Leia do jeito que o caso 9 pede: o endereço certo, o nome certo e um link para o endereço em que o
boxoffice responde. **Seu token vai ser outro**, uma sequência aleatória nova a cada execução; as
transcrições do curso vêm de uma versão iniciada de modo que os tokens se repetem. O link é texto
simples na página, então copie-o para a barra de endereço e abra:

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=nbm7nh5xugmf6rdv' | grep msg
<p class="msg">Your account is confirmed.</p>
```

Esse é o caso 1. Abra o mesmo link uma segunda vez, que é o caso 6:

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=nbm7nh5xugmf6rdv' | grep msg
<p class="msg">Your account is confirmed.</p>
```

O link continua funcionando depois de cumprir seu papel. **Isto não é um relatório de defeito**: o R3
nunca diz que um link vale uma vez só, então não há com o que comparar o resultado. Ele vai para a
sua lista de perguntas ao teatro, com a observação anexada. O caso 2, um token que ninguém emitiu, é
recusado como deveria:

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=nosuchtoken' | grep msg
<p class="msg">This link is not valid.</p>
```

## Pedir de novo, e tentar o link antigo

Os casos 4 e 5 precisam de um segundo link. O boxoffice não tem página com formulário para isso:
pedir um novo link é um envio de formulário para `/resend` com o endereço, então neste curso ele é
feito com curl. No Windows, deixe de fora o `| grep msg` do fim e procure a mesma frase na resposta.

Crie uma segunda conta, para Dora Reis, para que o histórico da primeira não atrapalhe:

```
ana@laptop:~/boxoffice$ curl -s -d 'name=Dora+Reis&email=dora@example.org&password=ticket-office-9' http://127.0.0.1:8000/signup | grep msg
<p class="msg">Account created. We sent a link to dora@example.org.</p>
```

Não abra o link dela. Peça outro, como faria alguém cujo primeiro e-mail sumiu:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=dora@example.org' http://127.0.0.1:8000/resend | grep msg
<p class="msg">If that account exists, we sent a new link.</p>
```

A caixa de saída agora tem três mensagens, a mais nova primeiro. Aqui estão só os destinatários e os
links:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/outbox | grep -oE 'To: [^ ]+|http://[^ ]+token=[a-z0-9]+'
To: dora@example.org
http://127.0.0.1:8000/confirm?token=je8xc3gqcheyuvsv
To: dora@example.org
http://127.0.0.1:8000/confirm?token=8mp9vq2ccu5dkrb8
To: caio@example.org
http://127.0.0.1:8000/confirm?token=nbm7nh5xugmf6rdv
```

O primeiro link da Dora é o segundo da lista. Pelo R3, ele parou de funcionar quando ela pediu um
novo. Abra:

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=8mp9vq2ccu5dkrb8' | grep msg
<p class="msg">Your account is confirmed.</p>
```

**O link antigo confirmou a conta.** O R3 diz que ele deveria ter respondido "This link is not
valid." Esse é o defeito 10, e ele vale mais do que parece. O motivo de alguém pedir um segundo link
muitas vezes é o primeiro ter ido para um lugar que a pessoa não controla, um endereço antigo, uma
caixa compartilhada, um domínio digitado errado; um primeiro link que continua funcionando pelas 24
horas inteiras deixa essa porta aberta depois que a pessoa achou que a tinha fechado. O relatório
precisa dos passos acima, dos resultados esperado e obtido lado a lado e do bloco de ambiente da aula
21.

O caso 7 se comporta como deve. Um endereço sem conta recebe exatamente a frase que a Dora recebeu,
então o formulário não conta a ninguém quem tem conta:

```
ana@laptop:~/boxoffice$ curl -s -d 'email=nobody@example.org' http://127.0.0.1:8000/resend | grep msg
<p class="msg">If that account exists, we sent a new link.</p>
```

## Expiração, e um teste que não consegue falhar

O caso 3 pede um link com mais de 24 horas, e `BOXOFFICE_NOW` parece o jeito de conseguir um: pare o
boxoffice, inicie-o um dia e uma hora depois e abra o link antigo da Dora.

```
ana@laptop:~/boxoffice$ BOXOFFICE_NOW=2026-10-11T15:00:00-03:00 python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=8mp9vq2ccu5dkrb8' | grep msg
<p class="msg">This link is not valid.</p>
```

Parece que passou. Antes de acreditar, rode o **controle**: os mesmos passos com o relógio onde
estava, para que só o tempo mude.

```
ana@laptop:~/boxoffice$ BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 python3 boxoffice.py
boxoffice 1.1 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

```
ana@laptop:~/boxoffice$ curl -s 'http://127.0.0.1:8000/confirm?token=8mp9vq2ccu5dkrb8' | grep msg
<p class="msg">This link is not valid.</p>
```

A mesma resposta sem tempo nenhum passando. **O reinício apagou todos os links**, porque o boxoffice
guarda tudo em memória, então a primeira execução foi recusada por esse motivo e não disse nada sobre
expiração. Um teste que dá o mesmo resultado com o comportamento certo ou errado não é um teste. E o
`BOXOFFICE_NOW` é lido quando o programa começa, então ele não move o relógio de um servidor que já
guarda um link.

Restam dois caminhos honestos. Um é o relógio real: inicie o boxoffice sem `BOXOFFICE_NOW`, cadastre
duas contas e deixe-o rodando, depois abra o link da primeira depois de 23 horas e o da segunda depois
de 25. Leva um dia e é um teste de verdade. O outro é pedir ao Rui um relógio que possa ser movido
com o programa rodando, o que é um pedido de testabilidade, e a aula 13 deu nome à ideia: um relógio
falso que o teste controla. Nenhum dos dois foi executado para este curso. Até um deles ser, o caso 3
fica **não testado**, e o relatório de teste diz isso com o motivo, o que vale mais do que uma
aprovação que não mediu nada.
