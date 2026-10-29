---
title: O que uma divisão custa
version: 1
---

**Dividir tira código das páginas que não precisam dele, e toda divisão tem um preço.** Três, e cada um já
apareceu neste curso.

## Uma requisição, e uma corrente

Todo chunk é uma requisição. Uma página que carrega seis chunks faz seis requisições, e o HTTP/2 e o HTTP/3,
que levam muitas requisições numa conexão, deixam cada uma barata mas não de graça. O custo de verdade é a
corrente: um chunk descoberto só quando outro roda é uma ida e volta depois dele, como o gráfico foi. **Uma
divisão que acrescenta um degrau à primeira página que a pessoa vê é uma divisão que deixou essa página mais
lenta**, seja lá o que ela economizou em outro lugar.

Então o código da primeira tela fica nos arquivos que o HTML cita, e o que se divide é o que essa tela não
desenha. Quando o código que carrega depois é necessário com pressa, dá para avisar o navegador cedo, com
`modulepreload` ou com um aviso como o da seção anterior.

## Chunks pequenos demais

**Um bundler divide onde o código manda**, em cada `import()`, e em cada módulo que dois chunks dividem,
como o `planner`. Uma aplicação grande com centenas de chamadas a `import()` pode acabar com centenas de
chunks de poucos kilobytes cada, cada um uma requisição com cabeçalhos e uma compressão própria, e a
compressão funciona pior em arquivos pequenos. As opções de build do Vite podem agrupar módulos em chunks
escolhidos, e os frameworks têm os próprios padrões; a medida é a cascata, não a contagem.

## E uma coisa que ela compra além do tamanho

**Um chunk vai para o cache sozinho.** O Vite dá a cada arquivo o nome de um hash do conteúdo, as letras
depois de `chart-` na lista do build, então um arquivo que não mudou mantém o nome de um build para o outro.
Mude a página inicial, e o chunk do gráfico continua o mesmo arquivo, ainda no cache de todo visitante que
volta. Um arquivo só para tudo teria mudado de nome, e seria baixado inteiro de novo. Esse é o assunto da
aula 9, e o motivo de arquivos divididos e tempos de cache longos andarem juntos.
