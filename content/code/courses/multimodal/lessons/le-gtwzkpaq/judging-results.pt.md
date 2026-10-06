---
title: Julgando as imagens, e quanto custa uma aceita
version: 1
---

Uma grade de imagens não decide nada sozinha. Alguém olha para ela, e o olhar funciona melhor com uma lista escrita antes de chegar a primeira imagem, porque uma imagem impressionante que não atende à exigência continua sendo um erro.

Para o banner, a lista é a exigência e o guia de estilo:

1. O terço direito está vazio o bastante para uma manchete?
2. Há algum texto, ou algo que tente ser texto?
3. Há um rosto, ou algo que possa ser lido como uma pessoa real ou uma marca real?
4. O meio e a paleta são os do guia?
5. Um leitor veria uma pilha de livros, rapidamente, no tamanho em que a newsletter a mostra?

Cada imagem recebe sim ou não por linha, e só uma imagem com cinco sins é candidata. Escrever a lista primeiro é o que impede o julgamento de virar gosto.

## O custo de uma imagem aceita

A geração de imagens é cobrada por imagem. A tabela de onde o curso lê os preços (a do LiteLLM, no commit que o `lab.sh` fixa) diz isto sobre o modelo de imagem do Google:

```
ana@lab:~/mm$ sheet show gemini/gemini-2.5-flash-image | grep -E "output_cost_per_image|deprecation|source"
deprecation_date                           2026-10-02
output_cost_per_image                      0.039
output_cost_per_image_token                3e-05
source                                     https://ai.google.dev/gemini-api/docs/pricing
ana@lab:~/mm$ python -c "print(round(0.039 * 4, 3), round(0.039 * 12, 3))"
0.156 0.468
```

**0,039 dólar por imagem**, e uma **data de descontinuação em 2 de outubro de 2026**, quatro dias antes do calendário do laboratório. As duas coisas são fatos de um dia de um provedor, lidos da cópia que um terceiro faz da página de preços do Google, e as duas vão estar diferentes quando você ler isto. A aula 9 vê o que essa data significa para um código que cita o modelo.

O preço que importa não é por imagem, e sim **por imagem aceita**. Se uma imagem em quatro passa na lista, cada banner custa quatro gerações: 0,156 dólar. Se a equipe gera duas por variante, em cinco variantes, e fica com uma, custa 0,468 dólar por aquele banner, como a segunda linha acima calcula. Ainda é barato para um banner, e não é barato como um recurso que o cliente aperta de novo e de novo, que é o alerta da ficha de design sobre todo este curso e o assunto da aula 13.
