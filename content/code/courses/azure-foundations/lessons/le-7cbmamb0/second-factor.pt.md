---
title: Padrões de segurança, e o segundo fator que o Azure agora exige
version: 1
---

**As lições 9 e 10 decidiram o que uma identidade pode fazer depois que o Azure sabe quem ela é. Esta
lição é sobre o momento anterior: quanta certeza o Azure tem de que quem digita é a pessoa citada.**
Uma senha sozinha é uma resposta fraca. Ela é adivinhada, reaproveitada de um site que vazou,
digitada numa cópia convincente da página de login, e nada disso deixa um rastro que o dono da senha
perceberia. Um segundo fator, algo que a pessoa tem além de algo que ela sabe, é a maior melhoria
barata que existe.

Tudo nesta lição acontece dentro de um tenant real no momento do login, então **nada disso foi
executado**, com duas exceções: o laboratório mostra com qual aplicação a CLI do Azure faz login, e a
próxima seção confere uma política de acesso condicional contra o esquema dela.

## Padrões de segurança

A documentação da Microsoft descreve os **padrões de segurança** como um conjunto fixo de proteções,
ligado sem custo extra, para tenants sem as licenças premium que o acesso condicional exige. Um tenant
criado desde outubro de 2019 bem pode já tê-los ligados. Eles fazem quatro coisas:

- **todo usuário se cadastra para a autenticação multifator**, e é perguntado por ela quando o Entra ID
  julga o login arriscado;
- **administradores são perguntados toda vez** que fazem login;
- **quem chega ao gerenciamento do Azure**, o portal, a CLI, o PowerShell, é perguntado;
- **a autenticação legada é bloqueada**: protocolos antigos que mandam uma senha e não conseguem
  carregar um segundo fator, de onde a Microsoft diz que vem a maioria das tentativas de login que
  comprometem contas.

**É tudo ou nada.** Os padrões de segurança não se ajustam: sem exceções, sem condições, sem relatório
do que fariam. Essa é a virtude deles para um tenant pequeno e o limite para um maior, e desligá-los sem
pôr o acesso condicional no lugar deixa um tenant com menos proteção do que tinha. A próxima seção é o
que os substitui.

## MFA obrigatório para o Azure

Desde 2024, um segundo fator não é só uma boa ideia para o Azure: **a Microsoft o impõe a todo usuário
que faz login para gerenciar o Azure**, sejam quais forem as configurações do próprio tenant. A
documentação dela descreve duas fases:

| fase | desde | aplicações | operações |
|---|---|---|---|
| 1 | outubro de 2024, aplicada aos poucos | o portal do Azure, o Microsoft Entra admin center, o Intune admin center | qualquer criação, leitura, alteração ou exclusão |
| 2 | 1º de outubro de 2025, aplicada aos poucos | a CLI do Azure, o Azure PowerShell, o app móvel do Azure, ferramentas de infraestrutura como código, a API REST | criação, alteração e exclusão; leituras não são afetadas |

**Identidades de carga de trabalho não são afetadas por nenhuma das fases**: service principals e
identidades gerenciadas, das lições 7 e 8, fazem login com um certificado, um token federado ou as
credenciais da própria plataforma, não com uma senha e um telefone. A documentação da Microsoft tira a
consequência com todas as letras: uma conta de *usuário* usada como conta de serviço para automação
agora precisa de um segundo fator a cada login, então a automação que roda como pessoa deve passar para
uma identidade de carga de trabalho.

## Com qual aplicação a CLI faz login

Cada cliente da tabela da Microsoft tem um id de aplicação, porque cada um é uma aplicação registrada
no Entra ID, que faz o login de pessoas por conta própria. A CLI do Azure é uma delas, e a cópia do seu
laboratório traz o id dela no código-fonte:

```
ana@laptop:~/azure$ python3 -c 'from azure.cli.core.auth.constants import AZURE_CLI_CLIENT_ID; print(AZURE_CLI_CLIENT_ID)'
04b07795-8ddb-461a-bbee-02f9e1bf7b46
```

`04b07795-8ddb-461a-bbee-02f9e1bf7b46` é o mesmo id que a tabela da Microsoft lista para a CLI do Azure
na fase 2. **Ela é um cliente público**: uma aplicação sem segredo, que faz o login de uma *pessoa* e
depois age em nome dela, com os papéis dela. É por isso que o MFA obrigatório a alcança, e por isso que
um token que a CLI guarda vale exatamente o mesmo que a pessoa que fez login. A lição 7 traça a linha
entre uma aplicação como esta, agindo por uma pessoa, e um service principal agindo por si.
