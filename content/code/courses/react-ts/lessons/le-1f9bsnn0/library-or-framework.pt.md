---
title: Uma biblioteca que você chama, um framework que chama você
version: 1
---

**O React faz um trabalho só.** Dado o que o seu app sabe agora, ele calcula o que a tela deveria
mostrar e muda a página até ela mostrar isso. Qual endereço mostra qual tela, como os dados chegam
de um servidor, como um formulário confere o que foi digitado, como o código é gerado e como é
testado: o React não decide nada disso. O Angular traz cada uma dessas coisas na mesma caixa,
escritas pelo mesmo time e lançadas juntas sob um único número de versão.

A imagem com que a maioria das pessoas chega é a de que o React é um Angular menor, o mesmo tipo de
coisa com menos peças. **A diferença não é o tamanho. É quem decide.**

## Quem chama quem

O jeito comum de separar as duas palavras é perguntar qual código chama qual. **Uma biblioteca é
código que você chama**: você decide quando, e ela faz o trabalho e devolve. **Um framework é código
que chama o seu**: ele é dono da forma do programa, e o seu código preenche os lugares que ele deixa
abertos.

O React fica dos dois lados dessa linha, e o projeto que você cria mais adiante nesta aula mostra
onde. Este é o arquivo que o inicia:

```
ana@dev:~/planner$ cat src/main.tsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
```

Você chama o React uma vez, nas últimas quatro linhas: encontre o elemento com o id `root` e
renderize nele o componente `App`. Daí em diante **o React chama o `App`**, toda vez que algo de que
ele depende muda, e você nunca o chama por conta própria. Para desenhar a tela, o React se comporta
como um framework. Para todo o resto ele é uma biblioteca: nunca chama o seu roteador, porque não
sabe que você tem um.

## O que o Angular decide por você

Um projeto Angular é criado pela ferramenta de linha de comando do próprio Angular, e chega com um
roteador, um cliente HTTP, um módulo de formulários, um jeito de entregar serviços aos componentes
que precisam deles e um build, tudo de pacotes chamados `@angular/…` que andam juntos. Há um jeito
de fazer cada coisa, e a documentação ensina esse jeito.

Um projeto React chega com o React. Todo o resto é um pacote que você escolhe, de outro time, com o
próprio calendário de lançamentos:

```schooling-figure
{"svg": "<svg data-fig=\"who-decides\" viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Sete tarefas de que um app precisa, de desenhar a tela a rodar testes. Num projeto React só as duas primeiras vêm do pacote react, e as outras cinco são pacotes escolhidos à parte, cada um com a aula deste curso que o acrescenta. Num projeto Angular as sete vêm dos pacotes do próprio Angular, dentro de uma fronteira só.\"><text x=\"330\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">um projeto React</text><text x=\"600\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">um projeto Angular</text><rect x=\"222\" y=\"44\" width=\"216\" height=\"78\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><rect x=\"482\" y=\"44\" width=\"236\" height=\"268\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"12\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">desenhar a tela</text><rect x=\"230\" y=\"50\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">react</text><rect x=\"490\" y=\"50\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/core</text><text x=\"12\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">estado num componente</text><rect x=\"230\" y=\"88\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">react</text><rect x=\"490\" y=\"88\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/core</text><text x=\"12\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">qual endereço, qual tela</text><rect x=\"230\" y=\"126\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">react-router · 17</text><rect x=\"490\" y=\"126\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/router</text><text x=\"12\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dados de um servidor</text><rect x=\"230\" y=\"164\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">@tanstack/react-query · 11</text><rect x=\"490\" y=\"164\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/common/http</text><text x=\"12\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">formulários e validação</text><rect x=\"230\" y=\"202\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">react-hook-form · 10</text><rect x=\"490\" y=\"202\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/forms</text><text x=\"12\" y=\"253\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build e servidor de dev</text><rect x=\"230\" y=\"240\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vite · 20</text><rect x=\"490\" y=\"240\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/cli</text><text x=\"12\" y=\"291\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">testes</text><rect x=\"230\" y=\"278\" width=\"200\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"291.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vitest · 22</text><rect x=\"490\" y=\"278\" width=\"220\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"291.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">@angular/cli</text><text x=\"330\" y=\"328\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tracejado: um pacote que você escolhe</text></svg>", "caption": "Quem decide cada tarefa. Os números são as aulas deste curso que acrescentam cada peça."}
```

Nenhum dos dois arranjos é melhor em geral, e a aula 24 volta a essa pergunta com as quatro opções
da trilha lado a lado. O que este custa a você são **escolhas**. Quem programa em React encontra
perguntas que quem programa em Angular nunca precisa responder: qual roteador, qual jeito de buscar
dados, qual biblioteca de formulários. Uma escolha errada não é fatal, e uma biblioteca abandonada
vira uma migração mais tarde. A vantagem é que cada peça pode ser trocada sozinha, e o próprio React
continua pequeno o bastante para ser aprendido inteiro.

## Frameworks construídos sobre o React

Como o React deixa tanta coisa em aberto, outros times construíram frameworks em volta dele que
fecham essas perguntas por você. O **Next.js** e o **React Router** no modo framework são os dois que
você vai encontrar com mais frequência, e a própria documentação do React recomenda começar um app
novo com um deles. Ela também documenta a outra estrada: uma ferramenta de build como o Vite, e as
peças acrescentadas uma de cada vez.

Este curso pega a segunda estrada primeiro, de propósito. Cada peça que um framework esconderia é
uma que você mesmo acrescenta, na aula que a explica, para que, quando a aula 18 entregar o Next.js,
você consiga ver o que ele está fazendo por você. A próxima seção lista as peças e a aula em que cada
uma chega.
