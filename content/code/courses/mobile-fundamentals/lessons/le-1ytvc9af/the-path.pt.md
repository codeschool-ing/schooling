---
title: De um build a um usuário, nas duas lojas
version: 1
---

**Nada nesta aula foi executado contra uma loja.** Não há conta no Play Console nem no App Store
Connect por trás dela, nenhum app foi enviado, e nenhuma tela de nenhum dos dois consoles aparece
aqui. O que ela descreve vem da documentação de cada loja, lida em 30 de outubro de 2026 e citada onde
é usada. Os dois programas pequenos perto do fim rodam no Node.js como o resto do curso, e modelam
regras; eles não falam com loja nenhuma. Nada aqui pede que você pague por coisa alguma.

**A imagem comum de publicar é um botão: o app está pronto, você o envia, e as pessoas baixam.** O
caminho real tem cinco etapas, e as do meio são onde um app passa as primeiras semanas. As duas lojas
têm as mesmas cinco, com nomes diferentes e regras diferentes dentro de cada uma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l20-path\" aria-label=\"O caminho de um build até todos os usuários, nas duas lojas, em cinco etapas da esquerda para a direita. Um build assinado; revisão; faixas de teste; uma liberação gradual; todo mundo. Na linha de cima, o Google Play: um app bundle assinado para o Play, a revisão do Google Play, teste interno, depois fechado, depois aberto, uma liberação gradual para uma porcentagem que a equipe escolhe, e produção. Na de baixo, a App Store: um build assinado pela Apple, o App Review, o TestFlight com testadores internos e externos, uma liberação em fases ao longo de sete dias, e todos os usuários. Abaixo das etapas, uma nota de que a revisão vem antes do público nas duas, e de que builds externos do TestFlight também são revisados.\"><defs><marker id=\"l20-path-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"156\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">um build assinado</text><text x=\"280\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">revisão</text><text x=\"404\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">faixas de teste</text><text x=\"528\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">liberação gradual</text><text x=\"652\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">todo mundo</text><text x=\"12\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Google Play</text><text x=\"12\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">App Store</text><rect x=\"100\" y=\"50\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"156.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app bundle,</text><text x=\"156.0\" y=\"82.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">assinado</text><path d=\"M212 76 L224 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"224\" y=\"50\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">revisão do</text><text x=\"280.0\" y=\"82.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Google Play</text><path d=\"M336 76 L348 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"348\" y=\"50\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">teste interno,</text><text x=\"404.0\" y=\"82.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">fechado, aberto</text><path d=\"M460 76 L472 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"472\" y=\"50\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"528.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">liberação gradual,</text><text x=\"528.0\" y=\"82.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">% que você escolhe</text><path d=\"M584 76 L596 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"596\" y=\"50\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"652.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">produção</text><rect x=\"100\" y=\"140\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"156.0\" y=\"159.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">build assinado</text><text x=\"156.0\" y=\"172.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pela Apple</text><path d=\"M212 166 L224 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"224\" y=\"140\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">App Review</text><path d=\"M336 166 L348 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"348\" y=\"140\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"404.0\" y=\"159.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">TestFlight:</text><text x=\"404.0\" y=\"172.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">interno, externo</text><path d=\"M460 166 L472 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"472\" y=\"140\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"528.0\" y=\"159.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">liberação em</text><text x=\"528.0\" y=\"172.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">fases, 7 dias</text><path d=\"M584 166 L596 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path><rect x=\"596\" y=\"140\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"652.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">todos os usuários</text><text x=\"404\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">builds externos do TestFlight também passam por revisão</text><path d=\"M404 204 L404 194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l20-path-ah-paper-dim)\"></path></svg>", "caption": "As mesmas cinco etapas nas duas lojas. Os nomes mudam; a ordem não. Nada aqui foi executado contra nenhuma das lojas.", "same": ["Google Play", "App Store", "App Review", "app bundle,", "TestFlight:"]}
```

## As etapas, em resumo

**Um build assinado.** Cada loja só aceita um app assinado com uma chave que prova que ele veio de
você, e a mesma chave, ou uma que a loja gerencia para você, assina toda versão seguinte. A assinatura
é o assunto inteiro das aulas 1 e 2 do `mobile-delivery`; esta aula supõe que um build assinado
existe.

**Uma conta na loja.** A do Google é o Play Console, a da Apple é o App Store Connect, a que se chega
pelo Apple Developer Program. A próxima parte diz quanto cada uma custa.

**Revisão.** As duas lojas olham um app antes de o público recebê-lo. A documentação do Android sobre
publicação diz que um app entra no ar "depois de passar pela revisão do Google Play"; a Apple revisa
todo app e toda atualização. A próxima seção trata do que a revisão recusa.

**Faixas de teste.** Antes de todo mundo, um build pode ir para a equipe, depois para um grupo de
testadores, depois para qualquer um que queira entrar. O Play as chama de teste interno, fechado e
aberto; a Apple chama a versão dela de TestFlight. Duas seções adiante, as duas aparecem lado a lado.

**Uma liberação gradual, depois todo mundo.** Uma versão nova não precisa chegar a todos os usuários no
mesmo dia. As duas lojas podem entregá-la primeiro a uma fração e ampliar, e as duas deixam você parar
quando algo dá errado. A última seção modela o cronograma da Apple.

## Quanto custa uma conta

**A Apple cobra uma anuidade; o Google cobra uma taxa de registro.** A página da Apple sobre o Apple
Developer Program traz uma "anuidade de US$ 99", conforme lida em 30 de outubro de 2026, e uma pessoa
ou uma organização a paga todo ano em que o app continua à venda. A mesma página traz o Enterprise
Program a US$ 299 por ano, que serve para distribuir apps de forma privada aos funcionários da própria
organização, não pela App Store.

O Google cobra uma taxa para registrar uma conta de desenvolvedor no Play Console. O valor e as
condições estão nas páginas de ajuda do Play Console em `support.google.com`, que não puderam ser
acessadas da máquina em que este curso foi escrito, então esta aula não cita um número que não leu.
Consulte lá antes de se registrar, e consulte de novo o da Apple também: os dois são preços, e preços
mudam.

**A aula 3 do `mobile-delivery` trata das contas a fundo**: os consoles, os papéis que uma equipe dá
aos membros, e as taxas com as condições delas. Este curso não precisa de nenhuma das contas. O
planner nunca sai do seu computador aqui, e os cursos depois da bifurcação chegam a um celular por um
emulador, um simulador ou o Expo, e nenhum deles precisa de conta de loja.

## O que muda, e o que não muda

**O código é uma parte pequena do que a loja vê.** Ela também vê uma página, capturas de tela, uma
descrição, uma declaração de privacidade (aula 13), uma classificação de conteúdo, os países onde o
app é vendido e um endereço de contato. Cada um desses é revisado, cada um pode ser o motivo de uma
recusa, e alguns podem ser mudados depois sem um build novo. O número de versão, mostram as próximas
seções, não volta atrás depois que um build com ele saiu.
