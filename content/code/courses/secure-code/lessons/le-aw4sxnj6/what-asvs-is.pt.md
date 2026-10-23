---
title: Um padrão contra o qual dá para verificar
version: 1
---

Cada aula deste curso terminou com uma recusa que uma aplicação deve. Um projeto real precisa da
lista inteira, e ninguém deveria ter de inventá-la. **O OWASP Application Security Verification
Standard, o ASVS, é essa lista**: um catálogo de requisitos de segurança para aplicações e serviços
web, cada um escrito para que alguém consiga verificar se uma aplicação o cumpre.

Ele é mantido pela OWASP, a Open Worldwide Application Security Project, uma fundação sem fins
lucrativos cujo material é gratuito e de licença aberta. A versão 5.0.0 saiu em maio de 2025,
substituindo a 4.0.3 de 2021, e é a versão que esta aula usa.

### Como é um requisito

Todo requisito começa com **"Verify that"** ("verifique que") e afirma algo que é verdadeiro ou
falso sobre uma aplicação. Essa forma é o ponto. *"A aplicação é segura"* não dá para verificar;
*"verifique que a validação no cliente não é usada como controle de segurança"* dá, lendo o código,
com um teste ou enviando uma requisição. A aula 3 foi esse requisito.

### Três níveis

Os requisitos são graduados em três níveis, e os níveis são **cumulativos**: cumprir o nível 2 quer
dizer cumprir também todo requisito do nível 1.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l20-levels\" aria-label=\"Os três níveis do ASVS 5.0.0 como caixas aninhadas, contados a partir do próprio arquivo do padrão. O nível 1 tem 70 requisitos, o mínimo para qualquer aplicação. O nível 2 acrescenta 183, num total de 253, o nível que a maioria das aplicações com dados pessoais deveria buscar. O nível 3 acrescenta 92, num total de 345, para aplicações em que uma falha seria das mais graves. Cada nível inclui tudo dos níveis dentro dele.\"><rect x=\"20\" y=\"14\" width=\"680\" height=\"222\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"40\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">nível 3</text><text x=\"40\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+92, todos os 345: onde a falha custa mais</text><rect x=\"60\" y=\"70\" width=\"600\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">nível 2</text><text x=\"80\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+183, 253 no total: dados pessoais, o portal da Vereda</text><rect x=\"100\" y=\"126\" width=\"520\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">nível 1</text><text x=\"120\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">70 requisitos: o piso de qualquer aplicação</text></svg>", "caption": "Os níveis são cumulativos. Um portal com dados de saúde busca o nível 2 e cumpre o nível 1 primeiro."}
```

| nível | feito para | para a Vereda |
|---|---|---|
| **1** | o mínimo de qualquer aplicação | o piso, cumprido primeiro |
| **2** | aplicações que lidam com dados pessoais ou qualquer coisa que valha proteger | o alvo: o portal guarda dados de saúde |
| **3** | aplicações que precisam da maior garantia, onde uma falha seria das mais graves | não é o alvo do portal, embora alguns requisitos valham a pena |

Escolher um nível é uma decisão com dono, como as decisões de risco que as aulas 17 e 18 pediram
por escrito. Ela pertence a quem responde pela aplicação, fica registrada e diz que requisitos o
projeto prometeu cumprir.

### O que o ASVS não é

Não é uma lista de ataques, e não ensina ninguém a quebrar uma aplicação. Ele descreve o que uma
aplicação **bem construída** faz. Também não é certificado: uma aplicação que cumpre o nível 2
cumpriu 253 requisitos escritos, o que é muito e ainda não diz nada sobre uma falha que nenhum
requisito descreve. A frase que faltava na aula 1, sobre de quem era o agendamento, está no ASVS só
como um requisito geral de autorização; reconhecê-la numa história específica continua sendo
trabalho de uma pessoa.
