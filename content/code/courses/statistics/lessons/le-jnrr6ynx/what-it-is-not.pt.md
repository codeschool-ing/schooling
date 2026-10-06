---
title: O que um p-valor não é
version: 1
---

Estudos sobre como pesquisadores leem p-valores acham os mesmos erros de novo e de novo. Cada uma destas
afirmações parece razoável, e cada uma está errada.

## "A probabilidade de a hipótese nula ser verdadeira"

O p-valor de 0,165 do teste do sistema de rotas **não** significa 16,5% de chance de o novo sistema não fazer
diferença. O p-valor foi calculado supondo a nula verdadeira, então não pode ser também a probabilidade de
ela ser verdadeira. É a probabilidade dos **dados**, dada a nula, não a probabilidade da **nula**, dados os
dados.

As duas podem ser muito diferentes. Suponha que a maioria dos ajustes de rota que um fornecedor oferece não
faça nada. Então até um p-valor pequeno pode vir de um ajuste que não faz nada, porque os ajustes inúteis
superam de longe os úteis. Quão provável é uma hipótese depende do que era plausível antes dos dados, e o
p-valor ignora isso.

## "A probabilidade de o resultado ser obra do acaso"

Este é o primeiro erro com outras palavras. "Obra do acaso" significa "a nula é verdadeira", e o p-valor não
é a probabilidade disso.

## "Um menos p é a probabilidade de a alternativa ser verdadeira"

O p-valor de 0,0009 da envasadora não significa 99,91% de chance de a máquina estar fora do alvo. Mesmo
motivo: o p-valor trata dos dados sob a nula, e não diz nada direto sobre a probabilidade de qualquer uma das
hipóteses.

## "Um p-valor pequeno significa um efeito grande"

Um p-valor mistura o tamanho do efeito com o tamanho da amostra. Um efeito minúsculo medido numa amostra
enorme pode dar um p-valor minúsculo, e um efeito grande medido numa amostra pequena pode dar um grande. Os
4,6 g a mais da envasadora são significativos porque os sacos são muito regulares; os mesmos 4,6 g com uma
dispersão de 40 g não teriam sido. **Para saber quão grande é um efeito, olhe a estimativa e o intervalo
dela, não o p.**

## "Um p-valor grande significa que não há efeito"

O 0,165 do teste do sistema de rotas diz que os dados são compatíveis com nenhum efeito. Também são
compatíveis com uma melhora de um ou dois minutos, como a aula 13 notou. Ausência de evidência não é
evidência de ausência, e o intervalo de confiança da próxima seção torna isso visível.

## "O resultado vai se repetir com probabilidade 1 − p"

Um p-valor de 0,03 não significa 97% de chance de obter de novo um resultado significativo. Um resultado que
mal passou de 0,05 tem chances mais ou menos iguais de passar de novo num estudo idêntico. Replicação é
outra pergunta, com uma aritmética própria e menos lisonjeira.

Em 2016, a American Statistical Association publicou uma declaração com princípios para o uso de p-valores,
porque o mau uso tinha se espalhado demais. O primeiro princípio é a definição do começo desta aula, e a
maior parte do resto é esta seção.
