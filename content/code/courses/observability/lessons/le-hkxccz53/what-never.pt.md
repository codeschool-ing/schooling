---
title: O que nunca pode ser escrito
version: 1
---

Um log é a coisa mais amplamente lida que um sistema produz. Ele é copiado para um shipper, um
armazenamento, um backup e muitas vezes um fornecedor; é lido por todo desenvolvedor depurando e
todo operador de plantão; é guardado por dias ou meses; e ninguém o revisa linha a linha. **Tudo o
que é escrito num log deve ser tratado como legível por qualquer pessoa com acesso a qualquer um
desses lugares, pelo tempo da maior retenção.** A partir disso, a lista se escreve sozinha:

| nunca num log | porque |
|---|---|
| senhas, mesmo as erradas | uma senha errada costuma ser uma senha certa com um erro de digitação |
| tokens, cookies de sessão, chaves de API, cabeçalhos `Authorization` | quem ler a linha pode agir como o dono até o token expirar |
| números de cartão completos e códigos de segurança | as próprias regras do setor de cartões (PCI DSS) proíbem guardá-los em lugares assim |
| documentos e identificadores de uma pessoa: CPF, RG, passaporte | dado pessoal que identifica alguém diretamente |
| saúde, religião, filiação sindical, origem étnica, vida sexual | dado pessoal *sensível* na LGPD, com regras ainda mais rígidas |
| o corpo inteiro de uma requisição ou resposta | ele carrega tudo isso acima, mais cedo ou mais tarde |

A LGPD, a lei geral de proteção de dados do Brasil, é o quadro que importa para as pessoas para quem
este curso é escrito. Ela não proíbe registrar dados pessoais; ela exige uma finalidade, o mínimo
necessário para essa finalidade, segurança proporcional ao risco, e a capacidade de responder a uma
pessoa que pergunte o que se guarda sobre ela ou peça para apagar. **Um log cheio de dados pessoais
falha nas quatro de uma vez**: a finalidade era depurar, ele guarda tudo, é lido por muitos, e as
seções seguintes mostram como é difícil recuperá-lo.

O que um log deve carregar no lugar é **um identificador que não significa nada fora do sistema**: um
id de pedido, o id interno de uma conta, um id de rastro. Eles permitem a uma investigação achar tudo
o que precisa no sistema dono dos dados, sob os controles de acesso desse sistema, sem que o log vire
uma segunda cópia, desprotegida.
