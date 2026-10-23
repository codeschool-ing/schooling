---
title: À esquerda de quê
version: 1
---

"Shift left" aparece em toda reunião de DevSecOps. Metade das vezes quer dizer algo com que ninguém
concordaria se fosse dito com todas as letras: **o trabalho do time de segurança, repassado aos
desenvolvedores, sem tempo a mais para fazê-lo.** Não foi para isso que a expressão nasceu, e um
time que a ouve desse jeito aprende a se ressentir de cada checagem que este curso acrescenta.

A esquerda é um lugar num desenho. Estenda a vida de uma mudança da esquerda para a direita, do
momento em que alguém decide o que construir até o momento em que ela roda para os usuários, e cada
checagem fica em algum ponto dessa linha. **Deslocar para a esquerda é levar uma checagem para um
ponto anterior, para que a resposta chegue enquanto quem pode agir sobre ela ainda está trabalhando
na mudança.** Nada nessa frase diz quem faz o trabalho, e nada diz que toda checagem deve se mover.

### De onde vem a expressão

Larry Smith deu o nome em 2001, num artigo da *Dr. Dobb's Journal* chamado "Shift-Left Testing". O
assunto dele era teste, não segurança: testadores que entravam no fim de um projeto achavam defeitos
que os desenvolvedores já não conseguiam corrigir barato, então ele defendeu testar tão cedo quanto o
código permitisse. A versão de segurança chegou com o vocabulário DevSecOps dos anos 2010 e carrega a
mesma afirmação. Um achado vale mais quanto antes chega a quem fez a mudança.

### A linha, com os lugares nela

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 186\" role=\"img\" data-fig=\"sp-l02-line\" aria-label=\"A vida de uma mudança desenhada da esquerda para a direita, com os seis lugares onde uma checagem pode rodar e o tempo que uma pessoa espera em cada um: o editor, menos de um segundo, lendo um arquivo; o hook de pre-commit, alguns segundos, lendo as linhas em stage; cada push, cerca de dez minutos, lendo o commit inteiro; depois do merge na main, mais ou menos o tempo de um push, lendo o commit do merge; a execução noturna, uma hora ou mais, lendo a main reconstruída; produção, que nunca acaba, lendo o que está rodando. Deslocar para a esquerda leva a checagem para perto do editor; ela só vai até onde existe aquilo que ela lê.\"><defs><marker id=\"sp-l02-line-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"12\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a espera</text><rect x=\"12\" y=\"32\" width=\"109\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"66.5\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">editor</text><text x=\"66.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">menos de 1 segundo</text><text x=\"66.5\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um arquivo</text><rect x=\"128\" y=\"32\" width=\"109\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"182.5\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pre-commit</text><text x=\"182.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">alguns segundos</text><text x=\"182.5\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">as linhas em stage</text><rect x=\"244\" y=\"32\" width=\"109\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"298.5\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">cada push</text><text x=\"298.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cerca de 10 minutos</text><text x=\"298.5\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o commit inteiro</text><rect x=\"360\" y=\"32\" width=\"109\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"414.5\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">main</text><text x=\"414.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">como um push</text><text x=\"414.5\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o commit do merge</text><rect x=\"476\" y=\"32\" width=\"109\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"530.5\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">noturno</text><text x=\"530.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma hora ou mais</text><text x=\"530.5\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a main reconstruída</text><rect x=\"592\" y=\"32\" width=\"109\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"646.5\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">produção</text><text x=\"646.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nunca acaba</text><text x=\"646.5\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o que está rodando</text><text x=\"12\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o que ela lê</text><path d=\"M700 150 L20 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-line-ah-phosphor)\"></path><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">shift left: mais cedo, enquanto o autor ainda tem o contexto</text></svg>", "caption": "Cada lugar da linha tem um orçamento e algo que pode ler. Uma checagem só vai para a esquerda até onde existe aquilo que ela lê.", "same": ["editor", "pre-commit", "main"]}
```

Cada lugar responde a uma pergunta diferente, e o que dá para perguntar depende do que já existe
ali. No editor há um arquivo. Num commit há um conjunto de mudanças. Num push há um commit inteiro
que pode ser construído. Depois do merge há um artefato que vai ser entregue. Em produção há um
serviço rodando e uma internet que não para de publicar avisos de segurança sobre o que ele usa.
**Uma checagem só vai para a esquerda até onde existe aquilo que ela lê.** A varredura da imagem
construída não roda no editor, porque ainda não existe imagem.

### Três maneiras de usar mal a expressão

**Mover o trabalho em vez do retorno.** O backlog de achados do time de segurança é atribuído aos
desenvolvedores, e o scanner que o produziu é ligado ao pipeline deles, sem mudança e sem ajuste. As
checagens não foram para mais cedo na mudança de ninguém; a fila só mudou de mesa. O teste é
simples: uma checagem deslocada para a esquerda fala da mudança que está na sua frente, e uma
checagem despejada fala de tudo o que alguém já escreveu.

**Mover toda checagem, custe o que custar.** Uma varredura dinâmica de vinte minutos é posta em cada
push porque mais cedo é melhor. O pipeline vai de quatro minutos para vinte e cinco, os
desenvolvedores juntam mudanças para fazer menos push, e os lotes ficam maiores e mais difíceis de
revisar. Mais cedo era para deixar os achados mais baratos; isto deixou toda mudança mais lenta, e a
aula 1 já apontou o fim dessa estrada, uma checagem marcada como "pode falhar".

**Ir para a esquerda e deixar a direita vazia.** Um código que não muda há um ano pode ficar
vulnerável hoje de manhã, porque saiu um aviso de segurança sobre uma biblioteca que ele usa. Nenhuma
checagem da esquerda vê isso: a mudança em que ela rodaria não existe. As checagens que vigiam o que
já está rodando são a ponta direita da mesma linha, e **"shift left" nunca quis dizer tirá-las de
lá**. Há quem diga "shift everywhere" para marcar o ponto; o desenho marca sem precisar de slogan.

### O que esta aula faz com isso

O resto da aula transforma o desenho em decisões para o linkbox. A próxima seção trata do número
usado para justificar tudo isso, e de quanto dele sobrevive a uma olhada na fonte. Depois cada lugar
ganha um orçamento de tempo, e o pipeline ganha uma segunda lista, `ci/nightly`, para o que não cabe
no orçamento de um push. **O objetivo é um push que responde em minutos, e checagens que não se
perdem por serem lentas.**
