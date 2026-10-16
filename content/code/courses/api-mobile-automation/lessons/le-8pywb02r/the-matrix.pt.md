---
title: A matriz de compatibilidade
version: 1
---

**Uma matriz de compatibilidade é a lista das configurações de aparelho em que um app promete
funcionar, e o subconjunto delas que você de fato testa.** As linhas são combinações: uma versão do
Android, um tamanho de tela, um fabricante, um idioma, e tudo o mais que muda o comportamento do
app. A lição 19 disse por que as combinações importam: as regras de segundo plano de um fabricante
ou uma tela pequena escondem cada uma os seus defeitos. Esta lição trata de quais testar, porque são
muitas demais para testar todas.

A primeira resposta de costume é pegar uma lista dos celulares mais vendidos do mundo, ou os dez
primeiros de um relatório de mercado, e testar esses. **Os celulares que importam são os dos seus
usuários**, e eles não são os do mundo. Um app de um teatro em São Paulo é aberto sobretudo nos
celulares Android intermediários e baratos vendidos no Brasil, por pessoas que ficam anos com o
mesmo aparelho. Uma lista de topos de linha de outro mercado não testa quase nenhum deles.

## As dimensões

| dimensão | por que importa | de onde vêm os valores |
|---|---|---|
| **versão do Android** | permissões, limites de segundo plano e APIs mudam de uma versão para a outra (lições 14 e 21) | os seus dados de uso; a ponta mais antiga é fixada pelo SDK mínimo do app, 26 no Tickets |
| **tamanho e densidade de tela** | layouts quebram nas telas menores e maiores, não naquela que o designer usou | os seus dados de uso, agrupados em poucas classes: celular pequeno, celular grande, tablet |
| **fabricante** | a versão do Android de cada fabricante tem launcher, ajustes e regras de segundo plano próprios (lição 19) | os seus dados de uso |
| **idioma e região** | o texto cresce na tradução, datas e dinheiro são escritos de outro jeito | os idiomas em que o app é distribuído, e as regiões para onde vende |
| **tudo de que o app depende** | Google Play services, uma câmera, um leitor de digital | o que os recursos do próprio app exigem |

Cada dimensão multiplica as outras. **Quatro versões do Android, três tamanhos de tela, três
fabricantes e dois idiomas já são 72 combinações**, e o script da seção 04 as conta. Acrescente uma
quinta versão ou um quarto fabricante e o número cresce um quarto ou um terço de uma vez. Ninguém
roda uma suíte em 72 configurações antes de cada versão, e ninguém deveria. A maioria dessas linhas
testa a mesma coisa que as vizinhas.

## Três jeitos de reduzir

O resto desta lição usa os três, nesta ordem:

1. A cobertura mantém os valores que a maioria dos seus usuários tem, até somarem uma fatia que
   você escolhe. Os raros ficam para uma verificação mais leve. Seção 03.
2. O pairwise escolhe combinações entre os valores mantidos, de modo que todo par de valores seja
   testado junto pelo menos uma vez. Isso é uma fração pequena do produto completo. Seção 04.
3. O aluguel roda as combinações que você não consegue ter em celulares reais numa nuvem de
   aparelhos. Seções 05 e 06.

Quando o app é novo e ainda não tem usuários, comece por números públicos do país onde ele é vendido,
e troque-os pelos seus assim que chegar o primeiro mês de dados de uso.
