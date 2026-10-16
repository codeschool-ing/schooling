---
title: Prophet em resumo
version: 1
---

O **Prophet** é uma biblioteca de previsão lançada pelo Facebook em 2017 para analistas e não para
estatísticos, e é comum em times de BI. Ele escreve uma série como a soma de peças ajustadas juntas:

- uma **tendência** que é uma reta com permissão para dobrar em **pontos de mudança**, lugares
  onde a taxa de crescimento muda, que o Prophet acha sozinho ou recebe de você;
- **sazonalidades** desenhadas como curvas suaves, anual e semanal, o que combina com dado diário
  com várias sazonalidades ao mesmo tempo;
- **feriados**, dados como uma lista de datas com uma janela em volta de cada uma, então um feriado
  móvel como o Carnaval ganha um efeito próprio onde quer que caia;
- **regressores** extras, outras séries que a previsão pode usar, como uma verba de marketing.

Duas dessas peças resolvem problemas que este curso já encontrou. Os pontos de mudança são um jeito
de tratar uma mudança brusca de nível como o aumento de preço da Panela, e a lista de feriados é a
cura para o Carnaval móvel que os dois modelos desta aula erraram.

**Este curso não o instala, e nada nesta seção foi rodado.** O Prophet ajusta o modelo com um motor
estatístico separado, o Stan, então é uma instalação mais pesada que todo o resto do curso junto, e
um lugar comum para a instalação falhar. Tudo o que ele faz pode ser feito com as ferramentas que
você já tem, e a aula 6 faz a parte dos feriados com statsmodels. Se o seu time usa Prophet, o
vocabulário acima é o que você precisa para ler a saída dele: uma tendência com pontos de mudança,
componentes que você pode desenhar um por um e uma tabela de feriados que alguém escreveu e alguém
deveria conferir.

A própria documentação do Prophet é honesta sobre onde ele é fraco: ele foi feito para séries de
negócio com sazonalidades fortes e vários anos de histórico, e em séries sem isso pode se sair pior
que métodos simples. A próxima seção é exatamente sobre isso.
