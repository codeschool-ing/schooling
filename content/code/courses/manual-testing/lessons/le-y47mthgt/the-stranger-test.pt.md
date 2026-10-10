---
title: O teste do estranho
version: 1
---

Um caso costuma ser julgado por conferir a coisa certa, e isso é necessário. Não é suficiente. Um
caso que confere a coisa certa e só pode ser executado por quem o escreveu é uma anotação pessoal
com uma tabela em volta. **Um caso está pronto quando alguém que nunca viu a aplicação, e não pode
perguntar nada a você, consegue executá-lo e chegar ao veredito a que você chegaria.** Esta aula
chama isso de teste do estranho, e é o padrão para o qual todo caso deste curso é escrito.

## Quem é o estranho

O estranho não é hipotético. Casos são escritos para serem executados por outra pessoa, e essa
pessoa aparece de quatro formas:

- **um colega** que entra no time em março e recebe os casos no primeiro dia;
- **o desenvolvedor**, o Rui, reproduzindo uma falha às onze da noite enquanto você dorme;
- **você, daqui a seis meses**, que já esqueceu o que *a conta de sempre* queria dizer;
- **um script.** Os cursos de automação que vêm depois deste na trilha `qa` transformam casos
  manuais em programas, e um programa faz exatamente o que o caso diz, não pergunta nada e não
  adivinha nada.

Neste curso o estranho tem uma descrição precisa. Ele sabe usar um navegador e um terminal. Ele tem
o caso, e o boxoffice rodando em `http://127.0.0.1:8000`. Nunca viu o boxoffice, não leu do R1 ao
R9, e não consegue falar com quem escreveu o caso. **Todo caso é escrito para essa pessoa**, e um
caso que precisa de algo que ela não tem está inacabado.

## Um caso que não passa no teste

Eis um caso que a Ana escreveu na primeira manhã dela, antes de a forma da aula 2 virar hábito. Não
é desleixo. Tudo nele estava claro para ela quando o escreveu:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l03-questions\" aria-label=\"Um primeiro rascunho de caso de teste com quatro linhas. Título: a reserva funciona. Pré-condição: logado como membro. Passos: reservar alguns ingressos para um espetáculo e conferir o total. Esperado: reserva bem-sucedida e o preço está correto. Marcadores numerados ao lado das linhas apontam oito perguntas que um estranho precisa fazer. Ao lado da pré-condição: 1, logar onde, não há página de login; 2, qual conta de membro; 8, a partir de que estado. Ao lado dos passos: 3, qual espetáculo; 4, quantos são alguns; 5, estudante marcado ou não. Ao lado do resultado esperado: 6, qual total é o correto; 7, como é bem-sucedida.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">TC-BOOK-04, primeiro rascunho</text><rect x=\"20.0\" y=\"38.0\" width=\"340.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"51.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">título</text><text x=\"124.0\" y=\"51.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">A reserva funciona</text><rect x=\"20.0\" y=\"74.0\" width=\"340.0\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">pré-condição</text><text x=\"124.0\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Logado como membro</text><circle cx=\"378.0\" cy=\"87.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"378.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">1</text><circle cx=\"402.0\" cy=\"87.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"402.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">2</text><circle cx=\"426.0\" cy=\"87.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"426.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">8</text><rect x=\"20.0\" y=\"110.0\" width=\"340.0\" height=\"41.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"130.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">passos</text><text x=\"124.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Reservar alguns ingressos para</text><text x=\"124.0\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um espetáculo e conferir o total.</text><circle cx=\"378.0\" cy=\"130.5\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"378.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">3</text><circle cx=\"402.0\" cy=\"130.5\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"402.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">4</text><circle cx=\"426.0\" cy=\"130.5\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"426.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">5</text><rect x=\"20.0\" y=\"161.0\" width=\"340.0\" height=\"41.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"181.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">esperado</text><text x=\"124.0\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Reserva bem-sucedida e</text><text x=\"124.0\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o preço está correto.</text><circle cx=\"378.0\" cy=\"181.5\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"378.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">6</text><circle cx=\"402.0\" cy=\"181.5\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"402.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">7</text><text x=\"456.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o que o estranho precisa perguntar</text><circle cx=\"466.0\" cy=\"52.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"484.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Logar onde? Não há página de login.</text><circle cx=\"466.0\" cy=\"82.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">2</text><text x=\"484.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Qual conta de membro?</text><circle cx=\"466.0\" cy=\"112.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">3</text><text x=\"484.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Qual espetáculo?</text><circle cx=\"466.0\" cy=\"142.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">4</text><text x=\"484.0\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Quantos são alguns?</text><circle cx=\"466.0\" cy=\"172.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">5</text><text x=\"484.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Estudante marcado ou não?</text><circle cx=\"466.0\" cy=\"202.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">6</text><text x=\"484.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Qual total é o correto?</text><circle cx=\"466.0\" cy=\"232.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">7</text><text x=\"484.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Como é bem-sucedida?</text><circle cx=\"466.0\" cy=\"262.0\" r=\"10\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></circle><text x=\"466.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">8</text><text x=\"484.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">A partir de que estado?</text></svg>", "caption": "O primeiro rascunho da Ana, lido por alguém que nunca viu o boxoffice. Quatro linhas levantam oito perguntas, e o resultado esperado levanta as duas que decidem o veredito."}
```

Agora execute-o como o estranho, linha por linha, e anote cada pergunta que ele obriga a fazer.

**A pré-condição** diz *logado como membro*. O estranho procura uma página de login, e o boxoffice
não tem nenhuma: a reserva pede um endereço de e-mail e mais nada (1). O endereço de quem? O
estranho não sabe que `member@example.org` existe, e *um membro* pode ser qualquer conta (2). E a
partir de que estado? Já há algo reservado, a aplicação acabou de ser iniciada (8)?

**Os passos** dizem *reservar alguns ingressos para um espetáculo*. Qual espetáculo, dos três (3)?
Quantos são *alguns* (4)? O formulário de reserva também tem uma caixa chamada Student (half
price), que o caso não menciona, e marcá-la corta o preço pela metade (5).

**O resultado esperado** diz *o preço está correto*. Correto segundo o quê (6)? O estranho nunca
leu o R5 e não tem como deduzir que um membro paga 10% menos. *Reserva bem-sucedida* também não
ajuda, porque nenhuma página do boxoffice diz essas palavras (7). A página que aparece diz que um
pedido está reservado. Isso é sucesso? Provavelmente. O caso não diz.

Oito perguntas a partir de quatro linhas.

## O que acontece com cada pergunta

Uma pergunta num caso termina de um de dois jeitos. **O estranho pergunta**, o que custa o seu
tempo, e só funciona quando você está lá para responder; às onze da noite você não está. Ou **o
estranho adivinha**, e o caso roda. Esse segundo desfecho é o perigoso, porque parece sucesso. O
caso ganha um veredito, mas é o veredito de outro teste, não do que você quis: o espetáculo dele, a
quantidade dele, a ideia dele de preço correto.

A pergunta 6 mostra até onde isso vai. Um estranho que não consegue deduzir o total correto não
consegue conferi-lo, então olha o total que aparecer e decide se parece razoável. Digamos que ele
reserve três ingressos para The Little Prince e a página diga R$ 81,00. Parece razoável. R$ 90,00
também pareceria, e é quanto os mesmos três ingressos custam sem o desconto de membro. O caso passa
dos dois jeitos. **Um caso cujo resultado esperado quem executa não consegue deduzir não confere
nada**, e nada no registro da execução diz isso.

## O resto desta aula

As oito perguntas caem em três famílias, e as próximas três seções tratam de uma cada. A seção 03
trata das palavras vagas, *alguns*, *correto*, *bem-sucedida*, e do que as substitui. A seção 04
trata dos dados e do estado, as duas entradas que um caso tem além dos passos, que o rascunho
deixou de fora por completo. A seção 05 reescreve este caso até o estranho não ter o que perguntar,
e executa o resultado. A seção 06 diz como descobrir se você conseguiu, porque essa é a parte que
ninguém pode corrigir por você.
