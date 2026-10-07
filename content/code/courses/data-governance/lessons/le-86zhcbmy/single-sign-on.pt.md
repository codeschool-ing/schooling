---
title: Quando a empresa já sabe quem você é
version: 1
---

Seis papéis com seis senhas dá para administrar. Seiscentas pessoas espalhadas por um data
warehouse, uma ferramenta de BI, um serviço de notebooks e três bancos não dá: cada um acaba com
uma senha por sistema, ninguém as troca, e no último dia de alguém quem faz o desligamento
precisa lembrar de todos os sistemas em que essa pessoa tinha conta.

**O login único (*single sign-on*) tira a autenticação de cada sistema e a põe num lugar só**, o
**provedor de identidade** da empresa. A pessoa prova quem é ali — com senha e, quase sempre, um
segundo fator — e todos os outros sistemas aceitam a palavra do provedor. Desativar uma conta no
provedor fecha todas as portas de uma vez, e é isso que faz do desligamento uma ação só em vez de
uma lista de tarefas.

Como a palavra é passada depende do sistema:

| método | como funciona | onde aparece |
|---|---|---|
| **LDAP** | o banco pede a um servidor de diretório para conferir a senha | o método `ldap` do PostgreSQL; Active Directory |
| **Kerberos / GSSAPI** | a máquina da pessoa tem um tíquete que o banco consegue verificar, sem enviar senha | o método `gss` do PostgreSQL; domínios Windows |
| **OIDC e SAML** | o navegador é mandado ao provedor e volta com um token assinado | warehouses na nuvem, ferramentas de BI, serviços de notebook |
| **certificados de cliente** | o cliente prova que tem uma chave privada que a CA da empresa assinou | o método `cert` do PostgreSQL; a aula 3 o usa para o `etl_loader` |

O PostgreSQL 16 aceita os dois primeiros e o último no `pg_hba.conf`, ao lado de
`scram-sha-256`; OIDC chega no PostgreSQL 18, que este laboratório não roda. Nenhum dos três foi
configurado no laboratório, porque cada um precisa de um servidor que o laboratório não tem — um
diretório, um realm Kerberos, um provedor de identidade. A tabela os descreve; não é um
transcrito.

## O segundo fator mora no provedor

Um protocolo de banco de dados não tem onde pedir um código do celular. **A autenticação
multifator é exigida onde a pessoa faz login**, que é o provedor de identidade no caso de um
warehouse na nuvem e da ferramenta de BI, e a VPN ou o bastion host no caso de um banco alcançado
pela rede própria. Então uma empresa que "exige MFA para acesso a dados" normalmente quer dizer:
exige para chegar à rede ou à ferramenta atrás da qual o banco está. Perguntar onde isso vale e
onde não vale — uma conta de serviço, uma senha local antiga que ninguém removeu — é como se acha
a porta sem segundo fator.

## O que continua local

Mesmo com login único, dois tipos de login ficam no banco:

- **o superusuário**, alcançável só pelo sistema operacional (`peer`), para que o provedor de
  identidade fora do ar nunca tranque do lado de fora quem conserta as coisas;
- **as contas de serviço**, que não têm pessoa para fazer login e são autenticadas por um segredo
  ou um certificado, e seguem as regras da seção anterior.

Os dois são o que uma revisão de acesso olha primeiro, porque o desligamento do provedor não
chega até eles.
