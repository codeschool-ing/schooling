---
title: Risco relevante, e a quinta
version: 1
---

A primeira pergunta, para a quinta, é fácil: **dados pessoais estavam envolvidos, ou possivelmente envolvidos.** De
dois tipos:

- **as credenciais do bruno.** Uma senha é dado pessoal, e o invasor tinha a dele.
- **o que quer que os 612 MB tivessem.** A aula 17 recuperou do servidor de arquivos uma exportação com nomes e e-mails
  de cinco contatos de clientes, e a aula 20 deixou em aberto se ela estava entre os bytes que saíram. O servidor
  também guardava documentos de clientes cujo conteúdo ninguém listou ainda.

A segunda pergunta é a difícil. O RCIS diz que um incidente **pode acarretar risco ou dano relevante** quando puder
afetar significativamente interesses e direitos fundamentais das pessoas envolvidas **e**, ao mesmo tempo, envolver
pelo menos um destes:

| critério | quinta |
|---|---|
| dados pessoais sensíveis, como saúde, religião ou biometria | não se sabe de nenhum no servidor |
| dados de crianças, adolescentes ou idosos | não se sabe |
| dados financeiros | não se sabe; os contratos têm valores, não contas pessoais |
| **dados de autenticação em sistemas** | **sim: a senha do bruno** |
| dados protegidos por sigilo legal, judicial ou profissional | não se sabe; depende do que são os documentos dos clientes |
| dados em larga escala | não: uma conta, cinco contatos, um servidor |

Então um critério está atendido, e outros ainda não podem ser descartados. Do outro lado: a senha do bruno foi
trocada na mesma manhã e perguntaram a ele se a usava em outro lugar; nomes e e-mails de cinco contatos profissionais,
sozinhos, são um risco pequeno.

Na quinta, o encarregado e o advogado decidem **comunicar**: dados de autenticação foram comprometidos, o conteúdo da
transferência não pode ser estabelecido, e comunicar dentro do prazo com o que se sabe, e depois complementar, é mais
seguro do que defender mais tarde uma decisão de não comunicar. Outra empresa, com os mesmos fatos, poderia
razoavelmente decidir o contrário, **e registrar por quê**. O que não seria defensável é nenhuma decisão, ou uma
decisão que ninguém escreveu.
