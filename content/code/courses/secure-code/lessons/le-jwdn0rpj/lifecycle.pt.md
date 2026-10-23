---
title: O que é uma sessão, e seus quatro momentos
version: 1
---

O HTTP não tem memória. Cada requisição chega sozinha, e nada no protocolo diz que o pedido de
`/bookings` vem da mesma pessoa que digitou uma senha um minuto antes. Uma **sessão** é a memória
que a aplicação acrescenta: no login o servidor emite um **id de sessão**, o navegador o devolve
num cookie a cada requisição, e o servidor o consulta para saber quem está pedindo.

Isso faz o id valer exatamente o mesmo que a senha. **Quem apresenta o id é o paciente, e nenhuma
senha é pedida de novo.** Uma falha de sessão é, portanto, uma falha de autenticação que pula a
senha: quem ataca nunca precisa conhecê-la.

A ideia errada mais comum é que sessão é problema do framework. O framework emite um cookie, o
cookie funciona, o paciente continua logado, e todo teste manual passa. O que o framework não pode
decidir por você é quando o id precisa mudar, quando precisa parar de valer e o que "sair" quer
dizer no servidor. São decisões sobre a sua aplicação, e cada uma é uma linha de código.

### Quatro momentos

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l10-life\" aria-label=\"Os quatro momentos de uma sessão, da esquerda para a direita. Nasce: na primeira visita o servidor emite um id aleatório e guarda uma linha para ele; o navegador guarda o id num cookie marcado HttpOnly, Secure e SameSite. Renovada: no login o id antigo é apagado e um novo é emitido. Expira: a cada requisição o servidor confere o limite de inatividade de 15 minutos e o limite absoluto de 8 horas. Termina: logout, troca de senha ou a equipe apaga a linha no servidor. Embaixo, uma nota: o cookie leva só o id, e o servidor guarda todo o resto.\"><defs><marker id=\"l10-life-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"94\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">nasce</text><rect x=\"20\" y=\"44\" width=\"148\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"94.0\" y=\"79.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">id aleatório, 256 bits</text><text x=\"94.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cookie: HttpOnly,</text><text x=\"94.0\" y=\"104.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Secure, SameSite</text><path d=\"M168 92 L196 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-life-ah-paper-dim)\"></path><text x=\"270\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">renovada</text><rect x=\"196\" y=\"44\" width=\"148\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"270.0\" y=\"79.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no login:</text><text x=\"270.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">id antigo apagado,</text><text x=\"270.0\" y=\"104.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">id novo emitido</text><path d=\"M344 92 L372 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-life-ah-paper-dim)\"></path><text x=\"446\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">expira</text><rect x=\"372\" y=\"44\" width=\"148\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"446.0\" y=\"79.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">toda requisição confere</text><text x=\"446.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">inatividade: 15 min</text><text x=\"446.0\" y=\"104.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">absoluto: 8 h</text><path d=\"M520 92 L548 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-life-ah-paper-dim)\"></path><text x=\"622\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">termina</text><rect x=\"548\" y=\"44\" width=\"148\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"622.0\" y=\"79.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">logout, troca de</text><text x=\"622.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">senha, a equipe:</text><text x=\"622.0\" y=\"104.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">linha apagada no servidor</text><rect x=\"20\" y=\"168\" width=\"676\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"358\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o cookie leva só o id; o servidor guarda todo o resto</text></svg>", "caption": "Quatro momentos, cada um com uma regra. Toda regra é conferida no servidor, onde um id copiado não tem argumento.", "same": ["cookie: HttpOnly,", "Secure, SameSite"]}
```

Toda sessão passa por quatro momentos, e cada um tem uma regra.

1. **Nasce.** O id vem de um gerador aleatório criptograficamente seguro, com pelo menos 128 bits
   de aleatoriedade, para que ninguém adivinhe nem calcule o de outra pessoa. O cookie que o leva
   é marcado `HttpOnly`, `Secure` e `SameSite`.
2. **É renovada.** Quando o paciente entra, ou ganha qualquer privilégio novo, o id que ele tinha
   antes é descartado e um novo é emitido. Um id que existia antes do login pode ter sido visto por
   outra pessoa.
3. **Expira.** Um id para de valer depois de um período sem requisições (o **limite de
   inatividade**) e depois de um tempo fixo, por mais que esteja em uso (o **limite absoluto**).
   Uma sessão esquecida aberta no computador da recepção de uma clínica precisa terminar sozinha.
4. **Termina.** Sair apaga a sessão **no servidor**. Apagar o cookie no navegador não basta: uma
   cópia do id em outro lugar continua valendo enquanto o servidor a aceitar.

### Onde a sessão mora

O `session` embutido do Flask guarda tudo no próprio cookie, assinado com a `secret_key` para que
não possa ser alterado. É prático, e tem uma consequência que importa aqui: **um cookie assinado
não pode ser revogado.** O servidor não guarda lista dos cookies que emitiu, então não consegue
recusar um que continua com assinatura válida, a não ser trocando a chave e deslogando todo mundo
de uma vez. O portal da aula 1 o usou porque aquela aula tratava de outra coisa.

O portal desta aula guarda as sessões **no servidor**: o cookie leva só um id aleatório, e uma
tabela no servidor liga cada id ao paciente, a quando a sessão foi criada e a quando foi usada pela
última vez. Encerrar uma sessão passa a ser apagar uma linha. Em produção a tabela é um banco de
dados ou um armazenamento como o Redis, e extensões como o Flask-Session cuidam da contabilidade;
aqui é um dicionário, para o programa inteiro caber na página e cada regra ser uma linha que você
consegue ler.
