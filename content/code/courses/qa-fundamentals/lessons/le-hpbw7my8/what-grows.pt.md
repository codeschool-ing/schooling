---
title: O que cresce quando um defeito é achado tarde
version: 1
---

**Um defeito tardio não custa mais porque o tempo passou. Custa mais por causa do que aconteceu nesse
tempo.** Quatro coisas se acumulam entre o momento em que um erro é cometido e o momento em que ele é
achado, e cada uma é um motivo separado. Nomeá-las é mais útil que qualquer multiplicador, porque você
pode olhar para um defeito específico e perguntar quanto de cada uma ele juntou.

## 1. O que foi construído em cima

Código se constrói sobre código. Uma decisão errada sobre como a loja guarda uma reserva é, no dia em que é
tomada, uma decisão. Três meses depois ela é a base do mapa de assentos, da tela de reembolso, do
relatório da noite e da impressão da bilheteria, e corrigi-la significa mudar todos eles e testar todos
eles de novo. **O defeito não cresceu; o que depende dele cresceu.**

É por isso que os defeitos que crescem mais rápido são os de requisito e de projeto. Um preço errado numa
linha do `tickets.py` não tem nada construído em cima. Uma ideia errada sobre o que é uma reserva tem tudo
construído em cima.

## 2. Quem topou com ele

Antes da entrega, um defeito só encontrou o time. Depois, encontra clientes, e cada um que topa com ele
acrescenta um custo que não tem nada a ver com o código:

- o cliente que foi cobrado errado, que precisa ser achado e reembolsado;
- o cliente que percebeu, reclamou no balcão e agora confia um pouco menos na loja;
- a Célia, que passa a noite explicando;
- em alguns domínios, um órgão regulador, porque cobrar inteira de um aposentado no Brasil não é só um
  defeito, é o descumprimento de uma lei.

**Um defeito antes da entrega é um problema técnico. Depois, é um problema comercial**, e às vezes jurídico.
A correção no código pode ser idêntica nos dois momentos; tudo em volta dela não é.

## 3. Quem lembra por quê

No dia em que escreveu `age > 60`, o Rafael sabia exatamente por quê. Seis meses depois, a linha é uma entre
milhares, ele pode estar trabalhando em outra coisa, e quem a corrigir precisa redescobrir o que o código
devia fazer antes de conseguir mudá-lo com segurança. **O contexto se perde**, e reconstruí-lo é um
trabalho lento e caro que não aparece na estimativa de ninguém.

Esta também é a mais barata das quatro de reduzir sem achar defeito nenhum mais cedo: testes que descrevem
para que o código serve, e requisitos guardados ao lado dele, são contexto que não se perde.

## 4. Por quantos passos a correção precisa passar

Um defeito achado enquanto o Rafael ainda escreve o código é corrigido pelo Rafael, no editor, em um
minuto. Um achado no teste precisa de um relato, uma triagem, uma correção, uma revisão e uma segunda
rodada de teste. Um achado em produção precisa de tudo isso mais uma entrega, que em algumas empresas é
agendada com semanas de antecedência, e uma verificação depois de que a correção chegou a todo cliente.

Cada passo é o tempo de alguém, e **cada passo é uma fila**. A aula 13 é sobre filas; a versão curta é que
uma correção esperando em quatro filas demora mais do que quatro vezes o trabalho que há nela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 250\" role=\"img\" data-fig=\"l03-what-grows\" aria-label=\"Uma grade. Colunas, da esquerda para a direita: achado na frase, na revisão, no teste, depois da entrega. Linhas: o que foi construído em cima, quem topou com ele, quanto contexto se perdeu, quantos passos a correção exige. O construído em cima cresce de nada para uma linha, uma funcionalidade e a loja inteira. Quem topou com ele continua sendo o time até depois da entrega, quando clientes e a Célia entram. O contexto perdido vai de nenhum a quase todo. Os passos vão de uma resposta a uma edição, depois relato, correção e reteste, depois tudo isso mais uma entrega. As células escurecem para a direita.\"><text x=\"198.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">na frase</text><text x=\"334.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">na revisão</text><text x=\"470.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">no teste</text><text x=\"606.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">depois da entrega</text><text x=\"120.0\" y=\"59.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">construído em cima</text><rect x=\"132.0\" y=\"38.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"198.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">nada</text><rect x=\"268.0\" y=\"38.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"334.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">uma linha</text><rect x=\"404.0\" y=\"38.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"470.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">uma funcionalidade</text><rect x=\"540.0\" y=\"38.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"606.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">a loja</text><text x=\"120.0\" y=\"105.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">quem topou com ele</text><rect x=\"132.0\" y=\"84.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"198.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">o time</text><rect x=\"268.0\" y=\"84.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"334.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">o time</text><rect x=\"404.0\" y=\"84.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"470.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">o time</text><rect x=\"540.0\" y=\"84.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"606.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">clientes, Célia</text><text x=\"120.0\" y=\"151.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">contexto perdido</text><rect x=\"132.0\" y=\"130.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"198.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">nenhum</text><rect x=\"268.0\" y=\"130.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"334.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">nenhum</text><rect x=\"404.0\" y=\"130.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"470.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">algum</text><rect x=\"540.0\" y=\"130.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"606.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">quase todo</text><text x=\"120.0\" y=\"197.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">passos da correção</text><rect x=\"132.0\" y=\"176.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"198.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">uma resposta</text><rect x=\"268.0\" y=\"176.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"334.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">uma edição</text><rect x=\"404.0\" y=\"176.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"470.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">relato, correção, reteste</text><rect x=\"540.0\" y=\"176.0\" width=\"132.0\" height=\"42.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"606.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">tudo isso, mais uma entrega</text></svg>", "caption": "As quatro coisas que crescem, para o defeito da pessoa de sessenta anos achado em quatro momentos. Toda célula da coluna da direita é um custo que a correção em si não mostra."}
```

## Usando as quatro

Quando você relata um defeito, as quatro são aquilo em que pensar, e o relato fica mais forte com elas. Não
"este é um bug grave", mas: *é uma regra de preço, então não há nada construído em cima e a correção é uma
linha; não foi para produção, então nenhum cliente topou com ele; o Rafael o escreveu semana passada e
lembra; pode sair na entrega de sexta.* Esse é um defeito barato, e dizer isso é tão útil para o time
quanto dizer quando um é caro.

As mesmas quatro defendem a prevenção sem uma única razão inventada. Um defeito parado no requisito não
tem nada construído em cima, não encontrou ninguém, não precisa que ninguém lembre de nada, e não passa
por fila nenhuma.
