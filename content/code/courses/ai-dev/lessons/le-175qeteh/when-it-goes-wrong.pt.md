---
title: Quando algo passa
version: 2
---

As defesas desta aula tornam os erros mais raros e menores. Elas não os tornam impossíveis, então
uma funcionalidade que usa um modelo precisa de um plano para o dia em que um passar, **escrito antes
desse dia**, quando ninguém está com pressa.

## Consiga desligar

**Um interruptor que para o modelo e mantém o produto funcionando**: a página de suporte mostra um
formulário de contato em vez do assistente, a ferramenta de rascunho entrega todo e-mail a uma
pessoa. É uma flag lida a cada requisição, não um deploy, porque quem precisa dela à noite pode não
ser quem consegue fazer deploy. Teste-a como a aula 10 testou o fallback: usando.

## Saiba o que aconteceu

- **O log de requisições da aula 11 seção 04** diz que requisição, que modelo, quantos tokens e por
  que parou, com o id de requisição para passar a um provedor.
- **Chamadas de ferramenta são registradas como ações**, com os argumentos e quem as aprovou. "O
  modelo reembolsou o pedido 1042" precisa ter resposta para quando, quanto e com o sim de quem.
- **Guarde os prompts e respostas que você escolheu guardar**, redigidos, por tempo suficiente para
  reler a conversa ruim. Um erro que você não consegue reproduzir não dá para consertar.

## Conter, depois consertar

1. **Pare o estrago**: o interruptor, ou tirar a ferramenta que causou o problema.
2. **Revogue o que pode ter vazado**: uma chave, um token, uma sessão. A regra da aula 10 vale: na
   suspeita.
3. **Desfaça o que dá para desfazer**: estorne o reembolso, corrija o pedido, avise o cliente.
4. **Conserte a causa no host**, não no prompt: a ferramenta que estava oferecida, a verificação que
   faltava, a aprovação que foi pulada.
5. **Ponha o caso na avaliação** da aula 5, para o próximo modelo ou o próximo prompt ser testado
   exatamente contra este e-mail.

## Avise as pessoas

Clientes atingidos por uma resposta errada merecem saber pela própria loja. **Dados pessoais que
foram para onde não deviam podem ser um assunto legal**: no Brasil, a LGPD pede que incidentes que
possam causar risco ou dano relevante sejam comunicados à ANPD e às pessoas afetadas. Quem cuida
disso na empresa deve estar no plano, com nome.
