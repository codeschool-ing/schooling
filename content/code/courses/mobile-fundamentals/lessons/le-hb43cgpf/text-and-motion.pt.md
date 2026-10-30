---
title: Texto que cresce, movimento que para, e cor que não está sozinha
version: 1
---

**Três ajustes em todo celular mudam aquilo com que o app precisa lidar, e um app que os ignora quebra
em silêncio justamente para quem os ligou.** O usuário escolhe um texto maior; o usuário pede menos
movimento; e alguns usuários não distinguem duas cores, por melhor que seja o contraste entre elas.
Nada disso aparece no celular do próprio designer, e é por isso que cada um ganha uma regra e um
teste.

## Texto com o dobro do tamanho

**O critério 1.4.4 da WCAG 2.2, Resize Text, pede que o texto possa ser ampliado "até 200 por cento
sem perda de conteúdo ou de funcionalidade"**, e as HIG pedem o mesmo no celular: "dê às pessoas a
opção de ampliar o texto em pelo menos 200 por cento". A aula 18 preparou o planner para isso, pedindo
os tamanhos pelo papel, `bodyLarge` em `sp` no Android e o estilo de texto `.body` no iOS, para que o
sistema possa aumentá-los. Essa é metade do trabalho. A outra metade é um layout que sobreviva.

**A faixa do iPhone vai bem além de 200 por cento.** As tabelas das HIG dão 17 pontos para o `.body`
no tamanho padrão e 53 no maior tamanho de acessibilidade, o AX5: mais de três vezes maior. No AX2 ele
tem 33, quase o dobro. Uma linha desenhada em torno de texto de 17 pontos, com altura fixa de 44
pontos, corta as próprias palavras nesses tamanhos.

A linha de sessão do planner mostra o que dá errado, e o que as HIG sugerem em vez disso:

| no tamanho padrão | com o dobro do tamanho, mal feito | com o dobro do tamanho, bem feito |
|---|---|---|
| `SQL · Fri 23 Oct · 60 min` e um tique, numa linha | a mesma linha, cortada como `SQL · Fri 2…`, numa linha de altura fixa | o curso numa linha, a data e a duração abaixo, o tique ao lado, a linha tão alta quanto precisar |

**Três hábitos mantêm um layout vivo em tamanhos grandes.** Deixe a altura de uma linha seguir o
conteúdo em vez de fixá-la. Deixe o texto quebrar em quantas linhas precisar, porque as HIG pedem para
"reduzir ao mínimo o corte do texto conforme o tamanho da fonte aumenta". E onde itens ficam lado a
lado, deixe-os empilhar: o conselho das HIG para tamanhos grandes é "um layout empilhado, em que o
texto aparece acima dos itens secundários". O `sp` do Android segue a preferência de tamanho de fonte
do usuário do mesmo jeito, então os mesmos hábitos valem lá. Para experimentar, as HIG dão o caminho:
Ajustes, Acessibilidade, Tela e Tamanho do Texto, Texto Maior.

## Movimento que pode ser reduzido

**Movimento na tela pode deixar algumas pessoas tontas ou mal**, e as duas plataformas têm um ajuste
que pede aos apps que se movam menos. As HIG descrevem o do iOS, Reduzir Movimento, e pedem que o app
responda "reduzindo animações automáticas e repetitivas, incluindo zoom, escala e movimento
periférico", por exemplo trocando um deslizamento por um esmaecimento. O Android tem um ajuste próprio
para remover animações entre as opções de acessibilidade. O critério 2.3.3 da WCAG, Animation from
Interactions, pede o mesmo no nível mais exigente, AAA: o movimento disparado por uma interação pode
ser desligado, a menos que seja essencial.

No planner, a animação que vale conferir é a que toca quando uma sessão é marcada como feita. **Um
tique que se preenche é informação; uma linha que quica e sai voando é decoração**, e com Reduzir
Movimento a decoração vai embora enquanto a informação fica: o tique se preenche, sem o voo.

## Cor que não está sozinha

**O critério 1.4.1 da WCAG, Use of Color, é curto: a cor não pode ser "o único meio visual de
transmitir informação"**, e as HIG dizem o mesmo com as próprias palavras, citando os pares
vermelho-verde e azul-laranja que pessoas daltônicas acham difíceis. O contraste, da seção anterior,
não protege disso: uma linha verde de feita e uma vermelha de atrasada podem cada uma passar de 4,5:1
contra o branco e parecer idênticas para quem não distingue vermelho de verde.

**Por isso o estado de feita do planner tem três sinais, não um.** O tique está cheio ou vazio, que é
uma forma. Os minutos da linha estão riscados ou não, que é uma decoração de texto. E o verde também
está lá, para todo mundo que o vê. Tire a cor e a semana continua dizendo quais sessões estão feitas;
e o leitor de tela, das primeiras seções, não ouve nenhum dos três e recebe "marcada" em vez disso,
que é o quarto.

## O que nada disso substitui

As verificações desta aula são números que um programa consegue guardar: uma razão, um tamanho, uma
porcentagem. **O que elas não conseguem guardar é se o app é usável**, e as duas plataformas dizem
isso do mesmo jeito: ligue o leitor de tela, o texto grande e o movimento reduzido, e use o app. A
documentação do Android e a da Apple descrevem esse teste, e os cursos do planner depois da
bifurcação são onde ele é feito em telas de verdade.
