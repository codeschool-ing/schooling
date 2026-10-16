---
title: Adoção se mede, não se impõe
version: 1
---

O jeito mais rápido de padronizar qualquer coisa é exigir. Um comunicado diz que todo serviço novo
parte do template, uma revisão confere se partiu, e em um trimestre o número de adoção marca 100%.
**Esse número mede obediência, e obediência não diz nada sobre o padrão ser bom.** Um time que teria
saído do caminho por um bom motivo agora fica nele e o contorna, e o motivo nunca chega a quem
poderia ter consertado o caminho.

O template da Coreto nunca foi obrigatório. A Rafaela o publicou, mostrou no encontro geral de
engenharia e depois contou o que aconteceu.

## O número

No primeiro ano do template a Coreto criou 26 serviços novos, e 18 deles partiram do template:
**18 de 26, ou 69%**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 192\" role=\"img\" aria-label=\"Vinte e seis quadrados, um por serviço novo criado na Coreto no primeiro ano do template. Dezoito estão acesos: esses serviços começaram pelo template. Oito estão apagados: começaram de outro jeito.\"><text x=\"360\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">Serviços novos criados no primeiro ano do template: 26</text><rect x=\"52\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"100\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"148\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"196\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"244\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"292\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"340\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"388\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"436\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"484\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"532\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"580\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"628\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"52\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"100\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"148\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"196\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"244\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"292\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"340\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"388\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"436\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"484\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"532\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"580\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"628\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"52\" y=\"162\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"74\" y=\"174\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">começaram pelo template: 18 (69%)</text><rect x=\"392\" y=\"162\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"414\" y=\"174\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">começaram de outro jeito: 8</text></svg>", "caption": "Uma adoção que ninguém exigiu. Cada quadrado aceso é um time que julgou o template menos trabalhoso do que construir as mesmas camadas por conta própria; cada um apagado é um time com um motivo que vale a pena perguntar."}
```

Os 69% valem alguma coisa justamente porque ninguém precisava chegar a eles. Cada um dos 18 foi um
time decidindo que o template dava menos trabalho do que fazer tudo sozinho, que é a única evidência
de que um caminho pavimentado é pavimentado. Um 100% imposto teria escondido os oito que foram por
outro lado, e os oito são onde estava a próxima melhoria.

## Os oito que foram por outro lado

A Rafaela perguntou ao time de cada um dos oito por quê. As respostas caíram em três tipos, e cada
tipo pede uma reação diferente:

| o que o time disse | o que significa | o que a Plataforma fez |
|---|---|---|
| "Não serve para o que a gente constrói" | trabalho legítimo fora do caminho | nada — os jobs noturnos de Dados pertencem ao lado de fora |
| "Faltava uma coisa de que a gente precisava" | uma lacuna no caminho | acrescentou ao template um consumidor de fila quando um segundo time pediu |
| "A gente não sabia que existia" | uma falha de comunicação | pôs o link do template na página onde os times pedem um repositório novo |

Só a linha do meio é um defeito do caminho, e só a primeira é motivo para o número ficar abaixo de
100% para sempre. **Uma parcela de serviços novos que fica fora do caminho por escolha é um sinal
saudável**: quer dizer que o caminho é estreito o bastante para ser mantido funcionando e que os
times continuam usando o próprio julgamento onde ele serve mal.

## Medidas que mantêm o número honesto

Um número sozinho convida os jogos de sempre, então a Rafaela o acompanhou ao lado de duas perguntas
mais difíceis de maquiar:

1. **Os serviços continuam no caminho?** Um serviço que partiu do template e depois foi editado até
   o pipeline não aceitar mais as atualizações do template saiu do caminho em tudo menos no nome.
   Contar só os começos deixaria esse desvio passar.
2. **O que os times deixaram de fazer?** O objetivo do template eram os dias gastos com montagem no
   começo de cada serviço novo. Perguntar aos times se esses dias sumiram testa o motivo de o
   template existir, e não o template em si.

Ela não definiu uma meta para a parcela. Uma meta transforma uma medida num objetivo, e a aula 1 já
mostrou o que acontece com uma meta sem plano por trás: ela é cumprida por reetiquetagem. A parcela
é lida pela tendência e pelos motivos dos serviços que ficaram de fora.

## Quando uma regra é a ferramenta certa

Algumas coisas devem ser exigidas, e a linha fica clara depois de dita. **Imponha o resultado quando
existe uma resposta certa; ofereça um caminho quando existe um jeito melhor.**

Dados de cartão são o caso na Coreto. Como Pagamentos guarda e transmite dados de cartão tem uma
resposta certa, definida pelas regras da indústria de cartões, e deixar isso à preferência de cada
time seria um risco sem nenhum ganho. Então a regra é escrita como resultado — dados de cartão nunca
passam por um serviço fora de Pagamentos — e é verificada. Como um time monta seu pipeline não tem
uma resposta certa desse tipo. Existe um jeito mais barato e um mais caro, e o time que escolhe o
caro paga por ele.

Até um resultado imposto é mais fácil de manter quando o caminho o torna o padrão. Se o template é o
jeito mais fácil de construir um serviço e já envia logs sem números de cartão, a maioria dos times
cumpre a regra sem pensar nela. A regra pega o resto.

| use uma regra | use um caminho pavimentado |
|---|---|
| existe uma resposta certa | existe um jeito melhor |
| sair cria risco para os outros | sair custa só ao time que sai |
| verificada, e uma exceção é escalada | medido, e uma exceção é uma conversa |
| dados de cartão, acesso à produção, dados pessoais | pipelines, bibliotecas de log, estrutura de serviço |

A aula 15 é o oposto da história desta seção: uma ferramenta em que a Coreto gastou muito e que os
times não escolheram, e o que foi preciso para descobrir por quê.
