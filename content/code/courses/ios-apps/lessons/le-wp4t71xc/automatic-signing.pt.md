---
title: Assinatura automática, e quando desligá-la
version: 1
---

**O Xcode consegue cuidar do certificado, do App ID, do perfil e da lista de aparelhos por você, e
para um desenvolvedor num Mac só ele deve.** O ajuste fica na aba *Signing & Capabilities* do target,
*Automatically manage signing*, com um **time** escolhido entre as contas conectadas ao Xcode. Escolha
o time e o Xcode cria um certificado de desenvolvimento para este Mac se não houver um, registra o App
ID para o bundle identifier, registra o aparelho que você conectar e baixa um perfil que cobre tudo
isso. Acrescente uma capability na mesma aba e o Xcode acrescenta o entitlement e atualiza o App ID.
Nada aqui foi executado; foi escrito a partir da ajuda do Xcode da Apple sobre assinatura, lida em 30
de outubro de 2026.

Os dois erros que você mais vai encontrar com ela ligada são mensagens sobre algo que o Xcode não
consegue fazer por você:

- **o bundle identifier já está tomado**: outro time o registrou antes, e a aula 1, seção 07, diz por
  que ele não pode ser dividido. Escolha outro identificador.
- **nenhuma conta para o time**, ou a assinatura do programa venceu: conecte-se de novo nos ajustes
  *Accounts* do Xcode, ou renove, seção 02.

## Quando um time a desliga

A assinatura automática supõe que o Xcode, neste Mac, é quem toma as decisões. Duas situações quebram
essa suposição:

- **um servidor de build**, que arquiva o app sem ninguém no teclado. Ele precisa de um certificado e
  de um perfil de distribuição instalados antes e citados explicitamente. A aula 10 de
  `mobile-delivery` trata de assinar dentro de um pipeline.
- **um time que divide uma identidade de distribuição**, em que uma escolha automática no Mac de uma
  pessoa não deveria revogar nem trocar o que os outros usam.

Desligá-la é a *assinatura manual*: cada configuração cita um certificado e um perfil, e o perfil é
criado à mão na conta de desenvolvedor, como a seção 06 descreveu. **A assinatura manual não é mais
segura, é mais explícita.** Ela troca a comodidade do Xcode por uma escolha escrita, que é do que
precisa um time com mais de um Mac e um servidor de build.
