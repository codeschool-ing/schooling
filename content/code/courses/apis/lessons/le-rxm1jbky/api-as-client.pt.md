---
title: Quando a API é o cliente
version: 1
---

**Toda aula deste curso até aqui defendeu uma API contra as requisições que ela recebe. A API7 e a
API10 são sobre as requisições que ela manda.** Uma API que baixa a capa de um livro de uma URL, chama
um provedor de pagamentos ou lê cotações de câmbio de outra empresa é um cliente, e um cliente tem dois
jeitos próprios de dar errado: ir aonde não devia, e acreditar no que lhe dizem.

## API7: server-side request forgery

Suponha que o shelf deixasse um cliente anexar uma capa a um livro mandando o endereço da imagem, e o
servidor a baixasse. O recurso parece inofensivo porque o cliente poderia ter baixado a imagem ele
mesmo. **A diferença é de onde a requisição sai.** O servidor está dentro de uma rede que o cliente não
vê. De lá ele alcança o próprio `127.0.0.1`, o banco de dados, outros serviços internos e, na maioria
das nuvens, um serviço de metadados em `169.254.169.254`, que entrega as credenciais da própria
máquina a qualquer coisa que pergunte de dentro. Um endereço que o cliente escolhe, buscado pelo servidor, é uma
requisição feita com a posição e a confiança do servidor. Isso é server-side request forgery, SSRF.

A defesa começa por não oferecer o recurso na forma aberta. Uma capa pode ser enviada como bytes em
vez de buscada num endereço, e o serviço de um parceiro pode ser um nome na configuração em vez de algo
que uma requisição fornece. Onde a API realmente precisa buscar um endereço que recebeu:

- uma lista de destinos permitidos, os hosts com que ela deve falar, comparados exatamente, como
  `ORIGINS` no `secure.py`, com `https` como único esquema;
- o endereço conferido, não o nome: resolver o nome, recusar o que não for endereço público, e
  conectar no endereço que foi conferido, para que um nome que resolva diferente na segunda vez não
  ganhe nada;
- nenhum redirecionamento seguido sem conferir o destino novo do mesmo jeito, já que um
  redirecionamento é um segundo endereço que o cliente escolheu;
- um timeout e um limite de tamanho para o que volta, e a resposta nunca repassada inteira ao
  cliente.

A biblioteca padrão do Python já sabe quais endereços são públicos. De cinco endereços, só o primeiro
é um que uma API deveria buscar em nome de um cliente:

```
ana@api:~/shelf$ for a in 1.1.1.1 127.0.0.1 10.0.0.7 169.254.169.254 ::1; do python3 -c "import ipaddress, sys; a = sys.argv[1]; print(a, ipaddress.ip_address(a).is_global)" $a; done
1.1.1.1 True
127.0.0.1 False
10.0.0.7 False
169.254.169.254 False
::1 False
```

Loopback, uma rede privada e a faixa link-local onde moram os metadados da nuvem dão todos `False`.
Uma verificação construída sobre isso, com a lista de permissões na frente, recusa cada um deles antes
de abrir uma conexão.

## API10: unsafe consumption of APIs

O segundo jeito é confiar. A API de um parceiro responde, e a resposta vai para o banco, para uma
página, para a próxima requisição, com menos verificação do que a entrada de um usuário teria, porque
o parceiro é uma empresa com contrato. O parceiro pode ser invadido, pode mudar o formato sem aviso,
ou pode simplesmente ter um bug, e **o que ele manda então entra no seu sistema com a autoridade da sua
API.**

As defesas são as que este curso aplica aos próprios clientes, viradas ao contrário:

- validar a resposta contra um schema, com as mesmas ferramentas que a aula 2 usa para requisições,
  e recusar o que não bate em vez de guardar uma parte;
- manter a verificação de TLS ligada, sempre, como a seção de HTTPS diz; um cliente que a pula
  conversa com qualquer um que responda;
- definir um timeout e um limite de tamanho, para que uma resposta lenta ou enorme de um parceiro não
  prenda as threads da sua API;
- tratar o texto dele como não confiável onde quer que seja mostrado ou guardado, exatamente como se
  um estranho o tivesse digitado;
- não seguir os redirecionamentos dele às cegas, pelo motivo dado na API7.

Os dois riscos são o mesmo erro em duas direções: uma API cuidadosa com as requisições que recebe e
descuidada com as requisições que faz.
