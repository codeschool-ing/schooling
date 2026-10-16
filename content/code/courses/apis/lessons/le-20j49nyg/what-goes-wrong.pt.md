---
title: O que dá errado quando uma senha é guardada
version: 1
---

**Suponha que a tabela de usuários vai vazar e pergunte o que o vazamento entrega.** Essa é a ameaça
contra a qual esta aula se defende. Não é alguém tentando senhas no seu formulário de login, assunto
da aula 12; é alguém com uma cópia da tabela, no próprio computador, com todo o tempo do mundo. Um
backup no bucket errado, uma consulta que devolve uma coluna a mais, um disco velho: cada um desses
já aconteceu com alguém, e nenhum pede licença ao seu código de login.

A crença comum é que o banco está protegido, então pouco importa o que fica dentro dele. O banco está
protegido até o dia em que não está, e nesse dia é o que você guardou que decide o tamanho do
estrago. Há três jeitos de guardar mal uma senha, e cada um falha de um jeito.

**Texto puro.** A coluna guarda a própria senha. Quem lê a tabela entra como todo mundo, de uma vez,
e o estrago não para na sua API: as pessoas repetem senhas, então o mesmo par de endereço e senha
abre o e-mail e o banco delas. Você nunca fica sabendo quais dos seus usuários foram atingidos em
outro lugar.

**Cifragem.** A coluna guarda a senha cifrada com uma chave. Parece mais seguro, e é a mesma coisa com
um passo a mais, porque cifragem é feita para ser desfeita. Eis uma senha cifrada com uma chave e
decifrada de novo com a mesma chave:

```
ana@api:~$ printf %s sunshine | openssl enc -aes-256-cbc -pbkdf2 -pass pass:the-server-key -base64 > stored.txt && cat stored.txt
U2FsdGVkX18t4aosowNRR+TCnkoNAoicUlZ/l5pFzjE=
ana@api:~$ openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:the-server-key -base64 -in stored.txt; echo
sunshine
```

O programa que confere os logins precisa dessa chave para comparar, então a chave mora onde o
programa mora: num arquivo de configuração, numa variável de ambiente, no mesmo backup. Um vazamento
que leva os arquivos do servidor leva a chave junto, e aí todas as senhas voltam em claro.

**Um hash rápido.** A coluna guarda o SHA-256 da senha. Um hash não pode ser revertido, e essa é a
ideia certa, mas ainda assim falha. O SHA-256 é feito para ser rápido, então quem tem a tabela calcula
o hash de uma lista de senhas prováveis e compara cada resultado. Na máquina do laboratório da
próxima seção, um milhão desses palpites levou menos de um segundo.

| o que a coluna guarda | o que uma tabela vazada entrega |
|---|---|
| a senha | todas as senhas, na hora |
| a senha, cifrada | todas as senhas, assim que a chave vazar também |
| um hash rápido como o SHA-256 | toda senha que estiver numa lista de prováveis, a baixo custo |
| um hash de senha lento e com salt | cada senha só a um custo por palpite, por conta |

**Um login nunca precisa da senha de volta.** Ele precisa saber se o que alguém digitou é a mesma
senha que foi definida, e uma função de mão única responde isso: calcular o hash do que foi digitado
e comparar com o que foi guardado. O resto da aula é sobre deixar essa função cara de executar,
única para cada conta e legível mais tarde, quando os parâmetros dela mudarem.
