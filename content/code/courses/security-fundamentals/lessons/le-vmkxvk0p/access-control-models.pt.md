---
title: Modelos de controle de acesso
version: 1
---

A autorização precisa de regras, e há quatro jeitos clássicos de organizá-las. Eles não são produtos
rivais; a maioria dos sistemas reais mistura dois ou três. Saber os nomes deixa você ler um projeto e
ver de onde vêm as decisões dele.

| modelo | quem decide | como uma regra se lê | na livraria |
|---|---|---|---|
| **DAC**, discricionário | o dono de cada recurso | "o bruno compartilha esta pasta com a ana" | permissões de arquivo do Linux, uma planilha compartilhada |
| **MAC**, obrigatório | uma política central que ninguém sobrepõe | "só quem tem habilitação *confidencial* lê arquivos *confidenciais*" | raro em empresas; comum em sistemas militares e de governo |
| **RBAC**, baseado em papéis | a organização, por meio de papéis | "membros de `hr` leem qualquer holerite" | a regra de `hr` do portal, a regra de `sudo` da aula 6 |
| **ABAC**, baseado em atributos | uma política sobre atributos do usuário, do recurso e do contexto | "a equipe lê o manual de um aparelho gerenciado em horário de trabalho" | as decisões Zero Trust da aula 7 |

O controle de acesso **discricionário** deixa cada dono decidir quem mais usa o que é dele. É
flexível e é como funciona quase todo compartilhamento de arquivos, e a fraqueza está no nome: depende
da discrição de cada dono, e donos compartilham com generosidade e esquecem de descompartilhar. O
acúmulo de privilégios da aula 6 cresce aqui.

O controle de acesso **obrigatório** tira a decisão dos donos. Todo recurso e toda pessoa levam um
rótulo, e uma política central os compara; nem o dono de um arquivo consegue entregá-lo a alguém cujo
rótulo não permite. É rígido e difícil de manter, e por isso vive onde o custo de um vazamento
justifica. Uma forma dele também aparece dentro dos sistemas operacionais, como o SELinux e o AppArmor,
que confinam o que os programas podem fazer, digam os donos o que disserem.

O controle de acesso **baseado em papéis** dá permissões a papéis, e papéis a pessoas. Quando o bruno
entra no financeiro, é posto em `hr` e recebe tudo o que `hr` pode; quando muda, é retirado e perde. Isso
facilita muito as entradas, mudanças e saídas da aula 6, porque uma alteração nos papéis de uma pessoa
é o trabalho inteiro. A fraqueza é a **explosão de papéis**: uma organização que cria um papel novo
para cada exceção acaba com mais papéis que pessoas.

O controle de acesso **baseado em atributos** escreve regras sobre qualquer atributo: o departamento
do usuário, a sensibilidade do recurso, o estado do aparelho, a hora, o lugar. É o mais expressivo e o
de que o Zero Trust precisa, porque "quem, de qual aparelho, em qual contexto" é uma regra sobre
atributos. A fraqueza é que as regras podem ficar difíceis de ler, e uma regra que ninguém consegue ler
é uma regra que ninguém consegue conferir.

### A regra do portal, classificada

O portal diz: *você lê um holerite se ele é seu, ou se você está em `hr`*. A segunda metade é RBAC puro.
A primeira compara um atributo do usuário (o nome) com um atributo do recurso (de quem é o holerite), o
que é um pedacinho de ABAC. Dois modelos numa linha é o caso normal.
