---
title: Grupos, e a regra que mantém um grupo em dia
version: 1
---

**Dê acesso a grupos, nunca a pessoas.** É a regra mais antiga do ofício, e é uma regra sobre sair,
não sobre entrar. Uma permissão dada à `bia` fica com a `bia` até alguém lembrar de tirá-la; uma
permissão dada ao grupo de engenharia sai com ela no dia em que ela sai do grupo, e ninguém precisa
lembrar de nada. A lição 9 atribui todo papel do Azure deste curso a um grupo por esse motivo.

O Entra ID tem dois tipos de grupo, e só um deles é para acesso:

| tipo | para que serve | guarda |
|---|---|---|
| **segurança** | acesso: a recursos do Azure, a aplicações, e aos papéis do próprio diretório | usuários, dispositivos, service principals, outros grupos |
| **Microsoft 365** | colaboração: uma caixa de correio compartilhada, agenda, arquivos e uma equipe do Teams | só usuários |

Um grupo do Microsoft 365 também pode receber acesso, e há empresas que fazem isso, mas os membros
dele são quem entrou numa equipe para dividir uma agenda. **A loja guarda o acesso em grupos de
segurança**, com nomes que dizem isso: `grp-shop-engineering`, `grp-shop-prod-readers`.

## Atribuído, ou calculado

Os membros de um grupo são **atribuídos**, acrescentados e removidos um a um, ou **dinâmicos**,
calculados pelo Entra ID a partir de uma regra sobre os atributos dos próprios usuários:

```
user.department -eq "Engineering"
```

Todo usuário cujo `department` é `Engineering` é membro, e só esses. Contrate alguém para a engenharia
e o sistema de RH que preenche o departamento dela também lhe deu o grupo; mude-a para o marketing e
ela sai do grupo, em minutos, sem ninguém mexer nele. **Um grupo dinâmico transforma em acesso um fato
que a empresa já mantém**, que é o argumento mais forte a favor dele e também o risco: quem consegue
editar o departamento de um usuário agora consegue pôr esse usuário num grupo com acesso à produção.
Escolha atributos que só o sistema de RH escreve.

Grupos dinâmicos vêm com dois limites. Eles precisam de uma licença **Microsoft Entra ID P1**, o nível
pago, para os usuários a que se aplicam, então um tenant novo no nível gratuito não pode tê-los. E um
grupo dinâmico não aceita membros acrescentados à mão: a regra é a participação inteira, e é essa a
ideia.

## Grupos dentro de grupos

Um grupo de segurança pode conter outro grupo, e **se os membros do grupo de dentro contam depende do
recurso**. O acesso baseado em papéis do Azure segue o aninhamento: um papel dado a `grp-shop-all`
alcança os membros de `grp-shop-engineering` se esse grupo estiver dentro dele. Vários outros recursos
leem só os membros diretos; a documentação da Microsoft diz isso recurso por recurso, e atribuir uma
aplicação a um grupo é um caso em que os membros aninhados ficam de fora. **Mantenha o aninhamento
raso**, de um nível no máximo, e leia a documentação do recurso que vai consumir o grupo antes de
contar com ele.

## Quem é dono de um grupo

Todo grupo pode ter **donos**, usuários que podem mudar a participação nele sem serem administradores
do diretório. Isso é útil para uma equipe que cuida do próprio pessoal, e também é uma porta: um dono
de um grupo com acesso à produção pode acrescentar qualquer um a ele. **Um grupo que dá acesso à
produção tem donos só da equipe de plataforma**, e a próxima seção restringe os administradores do
mesmo jeito.
