---
title: Salve ids, não objetos, e pese o que você salva
version: 1
---

**O estado salvo é pequeno de propósito, e o jeito de mantê-lo pequeno é salvar o id de cada coisa
da tela, nunca a coisa em si.** A versão tentadora é salvar o objeto que a tela está mostrando, o
curso inteiro com as sessões, porque aí nada precisa ser procurado depois de restaurar. Funciona nos
testes, com um plano de quatro sessões. Aí um usuário com um plano de verdade encontra o limite, e no
Android o limite é uma exceção.

## Meça

O terceiro modo de `restore.ts` monta um plano de 2.000 sessões geradas, alguns anos de um estudante
dedicado, e salva a mesma tela de dois jeitos: como os ids que a etapa anterior salvou, e com o
curso aberto e o plano inteiro dentro do estado salvo.

```
ana@dev:~/planner$ node restore.ts sizes
ids only:       80 bytes
the whole plan: 157479 bytes, 153.8 KiB, 1968 times as much
```

**80 bytes contra 157.479, quase duas mil vezes mais, para a mesma tela.** Os 80 não crescem com o
plano: um estudante com vinte sessões e um com vinte mil salvam o mesmo id, a mesma posição de
rolagem e o mesmo rascunho. A versão com o plano inteiro cresce a cada sessão que o usuário
acrescenta, o que quer dizer que ela vai bem no celular de quem desenvolve e falha no celular de
quem mais usa o app.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" data-fig=\"l05-sizes\" aria-label=\"Duas barras medindo o estado salvo da mesma tela. Salvo como ids: 80 bytes, pequeno demais para aparecer nesta escala. Salvo com o plano inteiro de 2.000 sessões dentro: 157.479 bytes. Uma marca mostra 50 KB, o máximo que o guia do Android recomenda para estado salvo; o plano inteiro passa disso umas três vezes.\"><defs><marker id=\"l05-sizes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"34\" width=\"1\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"28\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">só ids: 80 bytes</text><rect x=\"20\" y=\"78\" width=\"600\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"28\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o plano inteiro: 157.479 bytes</text><path d=\"M215 62 L215 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M215 120 L215 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l05-sizes-ah-phosphor)\"></path><text x=\"215\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">guia do Android: menos de 50 KB</text></svg>", "caption": "A mesma tela, salva de dois jeitos. Medido com node restore.ts sizes; a marca de 50 KB vem do guia do Android sobre Parcelables e Bundles, lido em 30 de outubro de 2026."}
```

## O que o Android faz com um estado salvo grande

O guia do Android sobre Parcelables e Bundles, lido em 30 de outubro de 2026, põe números nisso:

- o estado salvo passa pelo buffer de transações do Binder, que tem um tamanho fixo limitado,
  atualmente 1 MB, compartilhado por todas as transações em andamento do processo inteiro, e não por
  tela;
- quando esse limite é ultrapassado, o sistema lança uma `TransactionTooLargeException`, e a partir
  do Android 7.0 ela é lançada como exceção de runtime, o que derruba o app;
- para estado salvo especificamente, o guia recomenda manter o estado salvo abaixo de 50 KB de dados,
  porque o processo do sistema guarda esses dados enquanto o usuário puder voltar à tela, mesmo
  depois de o processo do app ter sido morto.

**157.479 bytes é umas três vezes a recomendação**, e isso é compartilhado com tudo o mais que o app
estiver passando pelo mesmo buffer naquele momento. O conselho do guia na página sobre salvar estado
é a mesma regra do título desta etapa: guardar a quantidade mínima de dados necessária, como um ID, e
recarregar o resto de onde os dados moram.

**O iOS não dá número, e diz a mesma coisa.** A página da Apple sobre `@SceneStorage` pede dados
leves, diz que dados grandes, como dados de modelo, não devem ser guardados ali, e avisa que o
desempenho pode sofrer. O React Native não tem limite nenhum, que é o perigo que a etapa anterior
apontou: o app pode gravar um plano inteiro no próprio armazenamento a cada ida ao segundo plano, e
nada o impede até o salvamento ficar lento demais para terminar no tempo que o sistema permite.

## Por que ids também são mais corretos

**Um objeto salvo é uma cópia, e uma cópia pode estar errada quando for lida.** Se o planner
salvasse o objeto do curso e o usuário renomeasse o curso em outro aparelho, a restauração desenharia
o título antigo. Salvar `courseId` e procurar o curso nos dados desenha o que os dados dizem agora; a
restauração da etapa anterior fez exatamente isso, tirando o título do plano.

**E um id pode não apontar para nada.** Um curso apagado enquanto o app estava morto deixa um id
salvo sem curso por trás. O `restore.ts` recusa esse caso com erro em vez de desenhar uma tela vazia;
um app de verdade voltaria para a lista de cursos e diria por quê. De um jeito ou de outro o caso é
tratado de propósito, e essa é a diferença entre salvar ids e salvar cópias: com ids, o dado velho é
uma busca que falha onde dá para ver, e não uma cópia antiga desenhada como se fosse atual.

A aula 6 passa do que o sistema tira para o que o app faz com o tempo que tem, começando pela única
thread em que toda tela é desenhada.
