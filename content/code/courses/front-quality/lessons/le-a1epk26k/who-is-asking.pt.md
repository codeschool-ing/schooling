---
title: Quem está pedindo, e como o servidor se lembra
version: 1
---

**O HTTP não tem memória: cada requisição chega sozinha, e um servidor que quer saber quem a mandou
precisa ser informado, toda vez.** Autenticação é a pergunta *quem é*, respondida uma vez, no login,
com algo que só aquela pessoa tem. Autorização é a pergunta feita em toda requisição depois disso,
*esta pessoa pode fazer isto*, e ela precisa que a resposta da primeira venha junto.

Como ela vem junto é o assunto desta aula, e há três respostas em uso:

- **Um cookie de sessão.** No login o servidor inventa um id aleatório longo, lembra a quem ele
  pertence, e o entrega ao navegador num cookie. O navegador devolve o cookie em toda requisição
  àquele site, e o servidor procura o id. O id não quer dizer nada sozinho; o significado está na
  memória do servidor.
- **Um token autocontido**, em geral um JWT. No login o servidor escreve quem você é e até quando,
  assina, e entrega. Em cada requisição ele confere a assinatura e lê a afirmação. Ele não se lembra
  de nada; o significado viaja dentro do token.
- **Identidade delegada**, o OAuth 2.0 e o OpenID Connect. O planner nem confere uma senha: ele manda
  você a alguém que já conhece você, um provedor de identidade, e recebe uma declaração dele. A
  declaração é um token, e o planner então carrega a resposta de um dos dois primeiros jeitos.

## O que é do front-end

Num site feito de páginas que o servidor desenha, tudo isso é assunto do back-end. **Um aplicativo como
o planner, cuja página é um programa rodando no navegador, participa disso**: ele envia o login, decide
onde um token fica guardado, o anexa às requisições ou confia que o navegador mande um cookie, e é o
código ao lado do qual o script de um atacante rodaria. O resto desta parte do curso, as aulas 5 a 9,
é a parte do front-end nisso.

O planner não tinha contas até agora, e nada nesta aula muda o que ele desenha. Ele ganha um servidor
próprio, com uma conta e as três respostas acima experimentadas contra ele, para cada uma ser vista
funcionando e não descrita.
