---
title: O que uma linha de log carrega
version: 1
---

A aula 17 deixou uma promessa: voltar ao que uma linha de log precisa carregar para ser útil. Isto é
a A09, e é a categoria em que a pergunta do testador é a mais simples do plano. **Quando acontece
algo que importa para a segurança, alguém lendo o log amanhã conseguiria dizer o que aconteceu?** Se
a resposta precisa da pessoa que estava lá, o log falhou.

## Quatro coisas dentro, uma nunca

Um evento de segurança é um login, um login errado, uma recusa, um travamento, uma troca de papel,
um erro que ninguém previu. Uma linha que registra um deles carrega quatro coisas:

- **Quando**, até o milissegundo, com o fuso horário ou em UTC, para que linhas de duas máquinas
  possam ser postas em ordem.
- **Quem**: a conta que pediu, ou o nome com que alguém tentou entrar. Não a senha, e não mais dados
  pessoais do que a linha precisa.
- **O quê**: a ação e aquilo a que ela se dirigia, `GET /staff/bookings`, e não "uma requisição".
- **O resultado**: permitido, recusado, falhou, e por quê, em palavras que uma pessoa consegue
  procurar.

E ela **nunca carrega um segredo**: nenhuma senha, tentada ou real, nenhum token de sessão, nenhum
cookie, nenhuma chave de API, nenhum número de cartão inteiro. Um log é copiado para mais lugares e
guardado por mais tempo que o banco, e é lido por mais gente. Um segredo escrito nele vazou, no
sentido da aula 18, no momento em que a linha é escrita.

## As linhas do account.py, lidas contra a lista

As três sondas de "As linhas que um teste consegue segurar" foram ao mesmo serviço: uma senha errada
para `ana`, um login com um nome que tem uma quebra de linha e um marcador dentro, e `ana` pedindo a
lista da equipe. Estas são as três últimas linhas do terminal do serviço depois delas:

```
2026-10-15 21:39:57,369 WARNING failed sign-in for 'ana'
2026-10-15 21:39:57,437 WARNING failed sign-in for 'nft\nWARNING nft-probe'
2026-10-15 21:39:57,464 WARNING refused GET /staff/bookings to account 1: staff only
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l19-logline\" aria-label=\"Uma linha do log do account.py, cortada nas suas partes: 2026-10-15 21:39:57,464 é quando, WARNING é a gravidade, refused é o resultado, GET /staff/bookings é o que foi pedido, account 1 é quem pediu, e staff only é o motivo da recusa. Embaixo, o que uma linha nunca carrega: uma senha, um token de sessão, um cookie, uma chave de API.\"><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">uma linha que alguém consegue ler amanhã</text><rect x=\"84.0\" y=\"52.0\" width=\"553.2\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"96.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026-10-15 21:39:57,464</text><path d=\"M97.0 94.0 L239.9 94.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M168.4 94.0 L168.4 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"168.4\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">quando</text><text x=\"247.2\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WARNING</text><path d=\"M248.2 94.0 L290.3 94.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M269.2 94.0 L269.2 118.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"269.2\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">gravidade</text><text x=\"297.6\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">refused</text><path d=\"M298.6 94.0 L340.7 94.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M319.7 94.0 L319.7 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"319.7\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">resultado</text><text x=\"348.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET /staff/bookings</text><path d=\"M349.0 94.0 L466.7 94.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M407.9 94.0 L407.9 118.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"407.9\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">o quê</text><text x=\"474.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">to</text><text x=\"492.9\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">account 1</text><path d=\"M493.9 94.0 L548.6 94.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M521.2 94.0 L521.2 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"521.2\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">quem</text><text x=\"549.6\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:</text><text x=\"562.2\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">staff only</text><path d=\"M563.2 94.0 L624.2 94.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M593.7 94.0 L593.7 118.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"593.7\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">por quê</text><rect x=\"150.0\" y=\"170.0\" width=\"420.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">nunca numa linha</text><text x=\"360.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma senha · um token de sessão · um cookie · uma chave de API</text></svg>", "caption": "Quando, quem, o quê e o resultado, e nenhum segredo: a linha da recusa já tem tudo isso."}
```

A recusa é a linha boa para aprender. **Quando**: `2026-10-15 21:39:57,464`. **Quem**: `account 1`,
o id e não o nome, o que basta para quem pode consultar a conta e não diz nada a quem não pode.
**O quê**: `GET /staff/bookings`. **Resultado e motivo**: `refused`, `staff only`. Os dois logins
errados trazem o nome tentado e nenhuma senha, que é o que o
`test_a_failed_sign_in_is_logged_without_the_password` agora segura.

A segunda linha é a sonda. O nome enviado foi `nft`, uma quebra de linha e `WARNING nft-probe`. Se o
serviço o tivesse escrito como chegou, o log mostraria uma segunda linha começando com `WARNING`,
uma que o serviço nunca escreveu e em que alguém lendo o log acreditaria. **O serviço escreve nomes
com `%r`**, então a quebra sai como os dois caracteres `\n`, entre aspas, na linha a que pertence.
Um teste agora segura isso também, porque um log em que qualquer um consegue acrescentar linhas é um
log que ninguém consegue usar como evidência.

Ler as mesmas linhas contra a lista revela duas lacunas, e o trabalho de um testador é dizê-lo:

- **A hora não tem fuso.** `21:39:57` é a hora local desta máquina, e a linha não diz que fuso é
  esse. Numa máquina só, tudo bem; num conjunto de máquinas, ou depois de uma mudança de horário de
  verão, a ordem dos eventos vira um palpite. Uma correção pequena, no formato do log.
- **Um sucesso não deixa linha nenhuma.** `ana` se cadastrou e entrou no começo de "As linhas que
  um teste consegue segurar", e nenhuma das duas coisas aparece. Um login errado é evidência de
  alguém adivinhando; **um login bem-sucedido é o único rastro de alguém usando uma senha que não
  deveria ter**, e aqui não há nenhum. É o achado F19-3, e a gravidade é média porque é a linha de
  que uma investigação precisaria primeiro.

## Registrado não é o mesmo que percebido

A segunda metade do nome da A09 é *alerting*, alerta. Cinco logins errados e um travamento, escritos
direitinho num arquivo que ninguém lê até um cliente reclamar, não defenderam ninguém. **Uma linha de
log é um registro; um alerta é o que faz alguém agir sobre ele**, e os úteis para este serviço são
taxas, não linhas isoladas: recusas por minuto muito acima do normal, travamentos em muitos nomes ao
mesmo tempo. A aula 22 manda os logs e os números da bilheteria para um lugar onde eles podem ser
observados, e a aula 24 escreve os alertas e decide quem eles acordam.

A linha do plano para isso diz *uma revisão hoje*, com honestidade. O teste de um alerta é da aula
24, onde a regra existe para ser testada.
