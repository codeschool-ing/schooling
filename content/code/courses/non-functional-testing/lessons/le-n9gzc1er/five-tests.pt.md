---
title: Cinco testes, cinco perguntas
version: 1
---

"Rodamos um teste de carga" é a frase que abre a maioria dos relatórios de desempenho, e ela não
diz quase nada, porque a mesma ferramenta e o mesmo script podem responder cinco perguntas
diferentes. **O que distingue os cinco é a forma da carga ao longo do tempo**, e a pergunta que
essa forma foi escolhida para responder. Escolha a pergunta primeiro; a forma vem dela, e o que
*passar* quer dizer também.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 440\" role=\"img\" data-fig=\"l02-shapes\" aria-label=\"Cinco testes desenhados como carga contra o tempo, um por linha. Teste de carga: uma rampa até a carga esperada, um patamar longo, uma rampa de descida; passa quando o requisito se mantém durante todo o patamar. Teste de estresse: degraus que continuam subindo além da carga esperada; é lido por onde e como ele quebra, e se se recupera. Teste de pico: uma carga normal e plana, um salto repentino para muitas vezes ela por pouco tempo, e a volta; passa quando os erros ficam limitados e os tempos voltam ao normal logo depois. Teste de resistência: a carga esperada mantida plana por horas; passa quando nada deriva, os tempos do fim iguais aos do começo. Teste de escalabilidade: os mesmos degraus subindo, rodados duas vezes, com uma porção de recursos e depois com o dobro; passa quando a segunda rodada carrega mais ou menos o dobro da vazão.\"><text x=\"105.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">o teste e a sua pergunta</text><text x=\"340.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">carga contra o tempo</text><text x=\"600.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">passa quando</text><text x=\"30.0\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">carga</text><text x=\"30.0\" y=\"74.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">atende ao requisito</text><text x=\"30.0\" y=\"87.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">na carga esperada?</text><path d=\"M230.0 96.0 L450.0 96.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230.0 46.0 L230.0 96.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"450.0\" y=\"107.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">minutos</text><path d=\"M230.0 62.0 L450.0 62.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"454.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">esperada</text><path d=\"M230.0 96.0 L270.0 62.0 L410.0 62.0 L440.0 96.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"520.0\" y=\"61.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">os limites valem durante</text><text x=\"520.0\" y=\"74.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">todo o patamar</text><path d=\"M20.0 114.0 L700.0 114.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"30.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">estresse</text><text x=\"30.0\" y=\"154.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">onde ele quebra, como,</text><text x=\"30.0\" y=\"167.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e ele volta?</text><path d=\"M230.0 176.0 L450.0 176.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230.0 126.0 L230.0 176.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"450.0\" y=\"187.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">minutos</text><path d=\"M230.0 152.0 L450.0 152.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"454.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">esperada</text><path d=\"M230.0 176.0 L230.0 168.0 L265.0 168.0 L265.0 160.0 L300.0 160.0 L300.0 152.0 L335.0 152.0 L335.0 144.0 L370.0 144.0 L370.0 136.0 L405.0 136.0 L405.0 128.0 L440.0 128.0 L440.0 128.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"520.0\" y=\"141.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">não há aprovação fixa: o resultado</text><text x=\"520.0\" y=\"154.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">é o ponto e o jeito da quebra</text><path d=\"M20.0 194.0 L700.0 194.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"30.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">pico</text><text x=\"30.0\" y=\"234.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aguenta uma multidão</text><text x=\"30.0\" y=\"247.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">repentina, e se recupera?</text><path d=\"M230.0 256.0 L450.0 256.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230.0 206.0 L230.0 256.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"450.0\" y=\"267.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">minutos</text><path d=\"M230.0 244.0 L320.0 244.0 L325.0 207.0 L355.0 207.0 L360.0 244.0 L445.0 244.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"520.0\" y=\"221.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">erros limitados, tempos de volta</text><text x=\"520.0\" y=\"234.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ao normal logo depois</text><path d=\"M20.0 274.0 L700.0 274.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"30.0\" y=\"294.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">resistência</text><text x=\"30.0\" y=\"314.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">algo cresce ou</text><text x=\"30.0\" y=\"327.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">deriva com o tempo?</text><path d=\"M230.0 336.0 L450.0 336.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230.0 286.0 L230.0 336.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"450.0\" y=\"347.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">horas</text><path d=\"M230.0 336.0 L245.0 302.0 L435.0 302.0 L445.0 336.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"520.0\" y=\"301.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a última hora se parece</text><text x=\"520.0\" y=\"314.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">com a primeira</text><path d=\"M20.0 354.0 L700.0 354.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"30.0\" y=\"374.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">escalabilidade</text><text x=\"30.0\" y=\"394.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais recursos carregam</text><text x=\"30.0\" y=\"407.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais carga?</text><path d=\"M230.0 416.0 L450.0 416.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230.0 366.0 L230.0 416.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"450.0\" y=\"427.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">minutos</text><text x=\"278.0\" y=\"368.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">×1 recursos</text><text x=\"393.0\" y=\"368.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">×2 recursos</text><path d=\"M230.0 416.0 L230.0 416.0 L230.0 406.0 L254.0 406.0 L254.0 396.0 L278.0 396.0 L278.0 386.0 L302.0 386.0 L302.0 376.0 L326.0 376.0 L326.0 416.0 L345.0 416.0 L345.0 406.0 L369.0 406.0 L369.0 396.0 L393.0 396.0 L393.0 386.0 L417.0 386.0 L417.0 376.0 L441.0 376.0 L441.0 416.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"520.0\" y=\"381.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o dobro de recursos dá perto</text><text x=\"520.0\" y=\"394.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">do dobro da vazão</text></svg>", "caption": "Os cinco testes pela carga que cada um aplica. É a forma que os distingue; a ferramenta e o script podem ser os mesmos."}
```

## Carga: atende ao requisito?

Um **teste de carga** aplica a carga que o sistema deve enfrentar, a que está escrita no
requisito da aula 1, e a mantém. A forma é uma rampa até essa carga, um trecho plano e longo
nela, e uma rampa de descida. A rampa existe para o sistema não ser atingido a frio com tudo de
uma vez, o que seria outro teste; a aula 3 diz quanto tempo ela deve durar.

Só o trecho plano é julgado. **Ele passa quando todos os limites do requisito valem durante todo o
patamar**: o percentil 95 abaixo de 200 ms e os erros abaixo de 1%, a 50 requisições por segundo,
por dez minutos. A nota de aprovação dele é o próprio requisito, e é por isso que é nele que uma
entrega é barrada ou liberada.

## Estresse: onde ele quebra, e como?

Um **teste de estresse** continua acrescentando carga além do nível esperado até alguma coisa
ceder. A forma é uma escada que não para de subir. Ele não tem nota de aprovação no sentido
comum, porque a pergunta não é se o sistema quebra (todo sistema quebra), e sim onde, e de que
jeito:

- **O ponto de quebra**: a carga em que um limite é ultrapassado pela primeira vez. É a capacidade
  do sistema sob aquele requisito, e a distância entre ela e a carga esperada é a margem.
- **O jeito**: um servidor que responde ao excesso depressa com uma recusa, um `503` que diz
  *tente de novo*, está falhando bem. Um que deixa toda requisição esperar até todas expirarem
  está falhando mal, e a bilheteria faz a segunda coisa, como "Três formas na bilheteria" mostra.
- **A recuperação**: quando a carga cai, ele volta sozinho, ou fica quebrado até alguém
  reiniciá-lo?

Um teste de estresse *reprova* quando o jeito está errado: dados corrompidos sob pressão, um
assento vendido duas vezes, um servidor que nunca se recupera. Isso são defeitos, qualquer que
tenha sido o ponto de quebra.

## Pico: aguenta uma multidão repentina?

Um **teste de pico** vai do normal para muitas vezes o normal quase de uma vez, mantém isso por
pouco tempo e volta. É a bilheteria às 10:00, quando um espetáculo concorrido abre as vendas e as
pessoas que estavam esperando apertam o botão no mesmo minuto. Um teste de estresse sobe devagar o
bastante para os caches esquentarem e os pools crescerem; um pico não dá ao sistema tempo de se
adaptar, e é exatamente essa a situação a que ele precisa sobreviver.

Ele passa quando os erros durante o pico ficam dentro do combinado e **os tempos de resposta voltam
ao normal num tempo declarado depois dele**. A segunda metade é a que as pessoas esquecem. Um
sistema que enfileira um pico e depois leva dois minutos para esvaziar a fila continua reprovando
os clientes que chegam nesses dois minutos, com uma carga que já voltou ao normal.

## Resistência: alguma coisa deriva?

Um **teste de resistência**, também chamado de *soak* ou de endurance, mantém a carga esperada por
horas: oito, doze, um fim de semana. A forma é a linha plana do teste de carga, esticada. Nada na
carga é exigente; a pergunta é o que se acumula. Memória que um handler nunca libera, conexões com
o banco abertas e não devolvidas, um arquivo de log enchendo um disco, uma tabela que cresce a cada
requisição e deixa cada consulta mais lenta que a anterior.

Ele passa quando **a última hora se parece com a primeira**: os mesmos tempos de resposta, a mesma
memória, o mesmo número de conexões abertas. Um teste de resistência é lido como uma tendência, e
a aula 22 monta as métricas que um teste de resistência acompanha por horas. Nada nesta aula roda
um, porque uma demonstração que leva uma noite não é uma que você consiga acompanhar.

## Escalabilidade: mais recursos carregam mais carga?

Um **teste de escalabilidade** faz uma pergunta sobre a arquitetura, e não sobre a entrega: se o
sistema ganhar mais processadores, mais memória ou mais cópias do servidor, ele carrega
proporcionalmente mais carga? A forma é uma escada de estresse, rodada uma vez por configuração, e
o número comparado é a **capacidade**, a maior vazão que cada configuração sustenta dentro do
requisito.

Um **teste de capacidade** é a mesma medida feita uma vez, na configuração que você tem: quanta
carga esta máquina aguenta antes de o requisito reprovar? As equipes usam os dois nomes sem muito
rigor, e a distinção que vale guardar é que a capacidade é um número sobre uma configuração, e a
escalabilidade é como esse número se move quando a configuração muda.

Ele passa quando a capacidade cresce numa fração declarada dos recursos acrescentados. Dobrar os
processadores e obter 1,8 vez a vazão é um sistema que escala. Dobrá-los e obter 1,1 vez é um
sistema com alguma coisa dentro dele pela qual um processador ou cem vão esperar, um de cada vez,
e a aula 9 trata de encontrar essa coisa.

## Os nomes não estão fixados, as perguntas estão

Equipes e ferramentas diferentes traçam essas linhas de jeitos diferentes. Algumas chamam todos de
teste de carga; algumas chamam um pico de um tipo de teste de estresse; o glossário do ISTQB e a
documentação de uma ferramenta não concordam em todos os detalhes. **O que importa num plano de
teste é a pergunta estar escrita ao lado do nome**, para quem lê saber se um resultado com erros é
uma reprovação ou a descoberta.

| teste | a carga | responde | lido como |
|---|---|---|---|
| carga | a esperada, mantida | atende ao requisito? | passa ou reprova contra os limites |
| estresse | subindo além da esperada | onde e como ele quebra? | um ponto de quebra e um jeito |
| pico | um salto repentino e a volta | aguenta e se recupera? | erros limitados, tempo de recuperação |
| resistência | a esperada, por horas | alguma coisa deriva? | uma tendência que deveria ser plana |
| escalabilidade | uma escada por configuração | recursos acrescentam capacidade? | a razão entre capacidades |
