---
title: Uma troca com quem? Autenticando a troca de chaves
version: 1
---

**O Diffie-Hellman combina um segredo com quem respondeu, e sozinho não consegue dizer quem foi.** Um
atacante sentado entre a Ana e o servidor pode fazer uma troca com a Ana e outra com o servidor, e
repassar tudo entre os dois. Cada lado termina com um segredo compartilhado perfeitamente válido,
compartilhado com o atacante. Esse é o problema do *homem no meio* (*man-in-the-middle*), e todo
protocolo que usa Diffie-Hellman precisa responder a ele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Um homem no meio. A Ana faz uma troca Diffie-Hellman com o atacante, achando que é o servidor, e combina o segredo um. O atacante faz uma segunda troca com o servidor e combina o segredo dois. Tudo o que a Ana manda é decifrado com o segredo um, lido e recifrado com o segredo dois. Uma assinatura sobre a troca, conferida contra o certificado do servidor, é o que a Ana precisaria para perceber.\"><defs><marker id=\"mitm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ana</text><rect x=\"290\" y=\"60\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">atacante</text><text x=\"360\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê tudo</text><rect x=\"560\" y=\"60\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">servidor</text><polyline points=\"162,90 288,90\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#mitm-ah-amber)\"></polyline><polyline points=\"288,98 162,98\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#mitm-ah-amber)\"></polyline><text x=\"225\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">segredo 1</text><polyline points=\"432,90 558,90\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#mitm-ah-amber)\"></polyline><polyline points=\"558,98 432,98\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#mitm-ah-amber)\"></polyline><text x=\"495\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">segredo 2</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a correção: o servidor assina a troca com a chave do certificado</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e o atacante não consegue produzir essa assinatura</text></svg>", "caption": "Duas trocas honestas, uma parte desonesta no meio.", "same": ["Ana"]}
```

## Por que a troca não consegue perceber

Veja o que a Ana recebe na seção 02: um número, 19, sem nada junto dizendo quem o escolheu. Um
atacante que troca o 19 por um valor seu é indistinguível do Bruno. A matemática da troca continua
intacta; o atacante simplesmente faz duas trocas honestas. A cifragem por cima desse segredo
protege os dados da Ana de todo mundo, menos da única parte da qual ela deveria estar protegida.

## A correção: assinar a troca

A resposta junta esta aula com as aulas 3 e 8. O servidor tem um **par de chaves de longo prazo**, e
sua chave pública está amarrada ao nome dele por um certificado que uma AC assinou. Durante a troca,
o servidor **assina** seu valor público efêmero, e no TLS 1.3 a conversa inteira até ali, com essa
chave de longo prazo. A Ana confere:

1. que o certificado se encadeia a uma AC em que ela confia e nomeia o servidor que ela queria
   alcançar (aulas 8 e 9);
2. que a assinatura sobre a troca verifica com a chave daquele certificado.

Um atacante no meio ainda consegue fazer uma troca com a Ana, mas não consegue produzir aquela
assinatura, porque a chave privada nunca saiu do servidor. A verificação da Ana falha e ela para.
Cada chave faz um trabalho: o par **efêmero** fornece o segredo e o sigilo futuro; o par de **longo
prazo** fornece a identidade, e nunca cifra nada.

## Onde as pessoas desligam isso

O passo de autenticação é o que costuma ser desligado, em geral para fazer um erro sumir:

- `curl -k`, `verify=False` no `requests` do Python, `InsecureSkipVerify: true` no Go e
  `NODE_TLS_REJECT_UNAUTHORIZED=0` mantêm todos a cifragem e removem a verificação de **quem** está
  do outro lado. O que sobra é uma conversa cifrada com quem respondeu;
- o SSH faz a mesma pergunta na primeira vez que encontra um servidor (*"The authenticity of host …
  can't be established"*), e digitar `yes` sem comparar a impressão digital é a mesma escolha.

A correção para um erro de certificado quase nunca é parar de verificar. É descobrir por que a
verificação falhou, e a aula 10 é um passeio pelos motivos.
