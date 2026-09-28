---
title: Pessoas fazem login uma vez, com um segundo fator
version: 1
---

O arranjo com que a maioria dos times pequenos começa é um usuário por pessoa em cada conta de nuvem,
cada um com uma senha e muitas vezes uma chave de acesso. Funciona, e se multiplica: três contas e
seis pessoas são dezoito usuários, dezoito senhas e quantas chaves houver, cada uma algo que precisa
ser criado no primeiro dia e lembrado no último. Quem sai fica com uma chave funcionando na conta em
que ninguém pensou.

## A identidade mora num lugar só

A maioria das organizações já tem um lugar onde toda pessoa tem conta: o **provedor de identidade**,
ou IdP, que cuida do e-mail e do login em todo o resto — Microsoft Entra ID, Google Workspace e Okta
são comuns. Federação quer dizer que a conta de nuvem confia nesse provedor para dizer quem alguém é,
em vez de manter a própria lista de senhas.

Um login fica assim:

1. A pessoa abre a página de login da organização e entra ali, com senha e segundo fator.
2. O provedor de identidade manda ao provedor de nuvem uma declaração assinada: esta é a Ana, ela
   pertence a estes grupos. A declaração é escrita num de dois formatos padrão, SAML 2.0 ou OpenID
   Connect.
3. O provedor de nuvem confere a assinatura contra o provedor de identidade em que foi instruído a
   confiar, e mapeia os grupos da Ana para as roles que ela pode assumir.
4. A Ana recebe credenciais temporárias de uma dessas roles — no console ou na linha de comando —,
   e elas expiram como as de qualquer role.

Na AWS o serviço que faz isso para pessoas é o IAM Identity Center, e a captura da seção anterior
mostrou o rastro dele: `sso` na cadeia de credenciais é a CLI procurando uma sessão deixada por um
login desse tipo. Nada disso foi executado aqui; também não há provedor de identidade neste curso.

**A saída vira uma mudança só.** Desative a Ana no provedor de identidade e ela não consegue entrar em
nenhuma conta que confia nele. Há uma lacuna honesta: credenciais já entregues continuam funcionando
até expirar. Esse é o argumento para sessões curtas — uma hora perdida para quem saiu é um risco bem
diferente de uma chave que funciona por um ano.

## O segundo fator, e qual

Um segundo fator quer dizer que uma senha roubada não basta. Eles não são todos iguais:

- uma chave de segurança física, com FIDO2 ou WebAuthn, só responde ao site verdadeiro em que foi
  registrada, então uma página de login falsa convincente não consegue nada dela;
- um app autenticador gera um código de seis dígitos que muda a cada trinta segundos; ele barra uma
  senha roubada ontem, mas uma pessoa numa página falsa pode ser convencida a digitar nela o código
  de hoje;
- um código enviado por SMS é o mais fraco dos três, porque o próprio número de telefone pode ser
  levado para outro chip por alguém que convença a operadora a fazer isso.

Ponha o fator no provedor de identidade, por onde passa todo login, e no usuário root de cada conta,
que não entra por ele.

## Programas fora da nuvem, também

A mesma confiança funciona para máquinas que não estão na nuvem. Um pipeline de build que faz deploy
numa conta precisava de uma chave de acesso guardada. Hoje a própria plataforma do pipeline emite um
token assinado para cada execução, a conta confia nessa plataforma na política de confiança de uma
role, e o pipeline assume a role com o token — `assume-role-with-web-identity`, a terceira linha da
cadeia de credenciais. O GitHub Actions e o GitLab CI oferecem isso. Não há chave para guardar, e
portanto nenhuma para vazar.

## Chaves de longa duração para pessoas são o último recurso

Alguma ferramenta não vai fazer nada disso. Aí a chave é a exceção, com a menor política de que a
ferramenta precisa, com rotação agendada e registrada num lugar que quem revisa vai ver. **Uma chave
para uma pessoa é justamente o que a federação existe para eliminar**, e cada uma que sobrar deveria
ter um motivo que alguém saiba dizer.
