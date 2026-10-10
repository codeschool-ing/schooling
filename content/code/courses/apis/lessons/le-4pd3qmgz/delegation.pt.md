---
title: Delegação em vez de senha
version: 1
---

A livraria quer um app de leitura que mostre os livros que você comprou, e essa lista fica atrás da
API da loja. **O primeiro jeito que qualquer um pensa para isso é o errado: o app pede a sua senha
da loja e entra como você.** Funciona no primeiro dia, e tudo nele é um passivo dali em diante.

Uma senha entregue a um app dá a ele quatro coisas que você nunca quis dar:

| o que o app recebe | o que você queria que ele tivesse |
|---|---|
| tudo o que a sua conta faz, inclusive trocar a senha | uma lista, para ler |
| acesso até você trocar a senha, o que também corta todo outro app a quem você a deu | um acesso que você encerra só para este app |
| a sua senha, guardada num servidor que você nunca viu | nada que funcione em outro lugar |
| uma identidade que a loja não distingue da sua | um log que diga qual app fez o quê |

**O OAuth 2.0 troca a senha por delegação.** O app manda você para a loja. Você entra lá, na
própria página da loja, e a loja pergunta se este app pode ler as suas compras. Se você disser sim,
o app recebe um **access token**: uma string que abre o que você aceitou e nada mais, por alguns
minutos, e que a loja pode deixar de honrar sem mexer na sua senha. O app nunca vê a senha. O OAuth
2.0 é a RFC 6749, publicada em 2012, e quase todo botão "Conectar sua conta" que você já apertou é
construído sobre ele.

O bearer token da aula 7 era feito pela API para uso próprio. Aqui há três partes: um serviço
emite o token, outro o aceita, e uma pessoa concordou com isso no meio.

## Os quatro papéis

O OAuth dá nome a quatro partes, e todo fluxo desta aula é uma conversa entre algumas delas:

| papel | na livraria | no laboratório desta aula |
|---|---|---|
| **dono do recurso** (*resource owner*) | você, dono das compras | a única usuária que o `idp.py` conhece, a Ana |
| **cliente** (*client*) | o app de leitura | você, digitando `curl`, cadastrado como `shelf-web` |
| **servidor de autorização** (*authorization server*) | o serviço de entrada da loja, que emite tokens | o `/authorize` e o `/token` do `idp.py` |
| **servidor de recursos** (*resource server*) | a API da loja, que aceita tokens | o `/books/stock` e o `/userinfo` do `idp.py` |

**"Cliente" quer dizer o app, nunca o navegador.** O navegador leva mensagens entre você e os
outros três, e é a parte em que o OAuth menos confia, porque o que passa por ele pode ser lido por
outras coisas que rodam ali: uma extensão, o histórico, um log.

O servidor de autorização e o servidor de recursos são dois trabalhos. Numa empresa são dois
programas, muitas vezes de duas equipes: a API nunca vê uma senha e o serviço de entrada nunca
serve um livro. O laboratório desta aula faz os dois num arquivo Python só, para caber num
arquivo, e a metade servidor de recursos confere um token como uma API separada conferiria: com a
chave pública do servidor de autorização e sem perguntar nada a ele.

**Para quem defende, o ganho está em onde a senha mora.** Ela fica num programa só, o servidor de
autorização, o único que precisa ser bom em proteger senhas. Todos os outros lidam com tokens, que
são mais estreitos, expiram em minutos e podem ser retirados de um app sem tocar nos outros.
