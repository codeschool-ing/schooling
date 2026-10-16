---
title: Comparando capturas de tela, em resumo
version: 1
---

Toda captura de tela até aqui foi evidência, tirada depois de uma falha para explicá-la. O
Playwright também usa uma captura como **a própria verificação**: tira uma foto da página, compara
com uma foto salva antes e falha quando elas diferem. A ideia atrai porque uma asserção cobre tudo o
que a página desenha, cores e espaçamentos incluídos, onde nenhum `toHaveText` chega. **É também a
verificação que mais falha por um motivo que não é defeito**, e esta seção mostra as duas metades.

## A referência é escrita pela primeira execução

`expect(page).toHaveScreenshot(name)` compara a página com uma foto guardada chamada **referência**
(*baseline*). Na primeira vez não há nenhuma, então a primeira execução escreve uma e falha. Salve
como `evidence/visual.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Fails once, on purpose: the first run has no picture to compare with,
// so it writes one and fails. Every run after compares against it.
test('the shop looks as it did', async ({ page, request }) => {
  await request.post('/api/reset');
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
  await expect(page).toHaveScreenshot('shop.png');
});
```

O teste esvazia a cesta primeiro, porque o cabeçalho mostra a contagem e o total da cesta, e a foto
de uma cesta que outro teste encheu é outra foto. Ele espera os oito cartões pelo mesmo motivo: a
foto da lista antes de ela se encher seria a referência de coisa nenhuma.

```
%%CAP visual-first%%
```

```
%%CAP visual-second%%
```

A referência foi parar ao lado do teste, em `evidence/visual.spec.js-snapshots/`, com o nome
`shop-linux.png`: o Playwright acrescentou o sistema operacional ao nome, e acrescenta também o
nome do projeto quando a configuração tem projetos. A segunda execução comparou e passou. A
referência é um arquivo do projeto e vai para o controle de versão junto com o teste, porque uma
referência que mora numa máquina só é um teste que passa numa máquina só.

## Uma mudança que ela pega

Agora uma cor em `app/public/style.css` muda: a borda de cada cartão, de `#c9d6c3` para o verde
escuro da loja, `#2f6f4e`. Nada que um `toHaveText` lê se mexeu. O mesmo teste:

```
%%CAP visual-changed%%
```

**4794 pixels diferem**: as bordas dos oito cartões. Isso é cerca de meio por cento dos 921.600
pixels de uma imagem de 1280 por 720, que a mensagem arredonda para uma proporção de 0.01. A falha
deixou três imagens além das evidências de sempre: `shop-expected.png`, a referência;
`shop-actual.png`, o que a página desenhou desta vez; e `shop-diff.png`, que marca onde elas
diferem. O registro de chamadas mostra também o Playwright tirando a captura duas vezes, com 100 ms
de intervalo, e só comparando depois que duas capturas seguidas concordaram entre si, para que uma
página ainda em movimento não falhe pelo movimento.

Esta execução é aquilo para que a verificação serve: uma mudança que nenhuma asserção de texto
veria, pega por uma linha. O estilo volta ao original depois, como toda mudança que este curso faz
na loja.

## Por que a foto em outra máquina é diferente

O texto é desenhado pelas fontes do sistema operacional. A loja pede `system-ui`, que é uma fonte
diferente no Ubuntu, no Windows e no macOS, e até duas máquinas Linux com fontes diferentes
instaladas desenham a mesma palavra um pixel mais larga ou mais estreita. O antisserrilhamento, a
borda suave em volta de cada letra, também muda entre drivers gráficos. **Uma referência escrita no
seu notebook e comparada num servidor de build pode falhar em toda linha de texto** sem nada de
errado na página. É por isso que o nome do arquivo leva `linux`: o Playwright guarda uma referência
por plataforma em vez de fingir que elas concordam.

Três coisas tornam a verificação utilizável, e cada uma tem um preço:

- **Comparar onde a referência foi feita.** Equipes rodam testes visuais só dentro de uma mesma
  imagem de contêiner, para que as fontes sejam sempre as mesmas; o preço é que rodar no notebook
  significa rodar o contêiner.
- **Tolerar um pouco.** O `toHaveScreenshot` aceita `maxDiffPixels` ou `maxDiffPixelRatio`, e um
  `threshold` para o quanto a cor de um pixel pode mudar antes de contar; o preço é que uma mudança
  menor que a tolerância passa.
- **Esconder o que muda sozinho.** A opção `mask` recebe localizadores e pinta por cima deles, para
  um relógio, um banner aleatório, um anúncio; o preço é que nada debaixo da máscara é verificado.

Quando uma mudança é intencional, `npx playwright test --update-snapshots` escreve referências
novas, e uma pessoa precisa olhar para elas antes do commit: uma execução de atualização aceita o
que a página desenhar, defeitos incluídos. Se um teste visual compensa essa manutenção, diante dos
defeitos que pegaria, é o tipo de julgamento de que trata a aula 22. Aqui basta saber que a
verificação existe e o que as falhas dela costumam significar.
