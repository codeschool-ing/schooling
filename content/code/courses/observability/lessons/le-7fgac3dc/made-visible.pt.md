---
title: Nada fica visível sem que alguém torne visível
version: 1
---

Uma imagem comum de observabilidade é um produto: algo que se instala, se aponta para a produção e
depois se olha. **Nenhum produto mostra um número que o seu código nunca produziu.** Um painel
desenha o que recebeu, uma busca em logs acha as linhas que alguém escreveu, e um rastro só existe
onde todo serviço do caminho concordou em levá-lo adiante. Antes de tudo isso, alguém decidiu o que
o sistema diria sobre si mesmo.

É por isso que este curso começa por instrumentar, e só depois chega às ferramentas que guardam e
desenham o que a instrumentação produz. Ler um painel é a metade fácil. Garantir que o painel tenha
algo verdadeiro para desenhar é a metade que exige um serviço rodando, e é ela que decide se a
outra vale alguma coisa.

**Monitoramento e observabilidade respondem perguntas diferentes.** Monitorar é vigiar condições
com as quais alguém já sabia que devia se preocupar: o serviço está no ar, o disco está cheio, os
erros passaram de dois por cento. Observabilidade é poder fazer uma pergunta que ninguém previu, de
fora, e obter resposta: *por que os checkouts pagos com uma bandeira de cartão estão mais lentos
desde terça?* O primeiro precisa de uma lista de verificações. O segundo precisa de sinais ricos o
bastante para que a pergunta lhes seja feita depois do fato.

Três tipos de sinal carregam quase tudo, e o meio os chama de **três pilares**:

| sinal | o que é um deles | o que ele responde bem |
|---|---|---|
| métrica | um número, amostrado ao longo do tempo, com poucos labels | quanto, com que frequência, se está piorando |
| log | um evento, escrito quando aconteceu, com campos | o que exatamente aconteceu, em palavras e valores |
| rastro (trace) | o caminho de uma requisição por todos os serviços que ela tocou | para onde foi o tempo, e qual chamada falhou |

"Pilar" sugere três estruturas separadas. **São três vistas dos mesmos eventos**, e o resto desta
aula pega um checkout lento e olha para ele através de cada uma. O OpenTelemetry, o padrão com que
este curso instrumenta, define os três e vem acrescentando um quarto, os perfis (profiles), que
este curso não cobre.
