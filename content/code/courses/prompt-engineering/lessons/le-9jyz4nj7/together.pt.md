---
title: Usar os controles juntos
version: 1
---

Uma API que oferece temperatura, top-k e top-p deixa você ajustar os três numa requisição, e a
crença de que são três botões independentes é onde as pessoas se surpreendem. **Eles agem sobre a
mesma lista, um depois do outro, então cada um vê o que o anterior deixou.**

O `toylm` os aplica numa ordem fixa, escrita na docstring no topo do programa:

```localised
penalidades → temperatura → top-k → top-p → sorteio
```

As penalidades são a lição 17. O resto você já viu, e a ordem pesa mais entre temperatura e top-p.
Na seção anterior, p = 0,8 depois de `the coffee is` manteve três palavras na temperatura 1. Na
temperatura 2:

```
ana@lab:~/pe$ toylm dist "the coffee is" --temperature 2 --top-p 0.8
context: trigram after 'coffee is'
  hot       42.6%  #################
  strong    23.8%  ##########
  ready     18.5%  #######
  cold      15.1%  ######
```

As frações foram achatadas antes de o top-p medi-las, então foram precisas quatro palavras para
chegar a 80%. Em 0,5 a primeira já tinha 86,8% depois da divisão (lição 13), então o núcleo é
`hot` sozinha:

```
ana@lab:~/pe$ toylm dist "the coffee is" --temperature 0.5 --top-p 0.8
context: trigram after 'coffee is'
  hot      100.0%  ########################################
```

**Subir a temperatura também alarga o núcleo, e baixá-la o estreita.** Mude a temperatura com o
top-p ajustado e você mudou duas coisas.

No `toylm`, top-k e top-p juntos mantêm o conjunto que for menor. Aqui top-k 3 mantém três palavras
e top-p 0,8 também precisa de três, então o resultado é o que o top-p sozinho deu:

```
ana@lab:~/pe$ toylm dist "the coffee is" --top-k 3 --top-p 0.8
context: trigram after 'coffee is'
  hot       66.7%  ###########################
  strong    20.8%  ########
  ready     12.5%  #####
```

Nem toda implementação usa essa ordem, e as tabelas acima mostram que a ordem muda o resultado.
Onde isso importa, leia a documentação da API que você chama ou, como aqui, o código-fonte do
programa.

## Um controle por vez

**Mude um controle, olhe a saída, e só então mude o próximo.** Com dois mudados de uma vez você não
sabe qual produziu o que está vendo, e, como as tabelas acima mostram, eles não se somam de um jeito
simples.

Um jeito sensato de começar:

- deixe top-k e top-p nos padrões do provedor e ajuste primeiro a temperatura, porque é o controle
  de efeito visível e contínuo (lição 13);
- recorra ao top-p quando a saída de vez em quando fica estranha numa temperatura de que você gosta
  no resto. Ele tira a cauda sem deixar as escolhas comuns mais uniformes;
- trate o top-k como uma trava grosseira, um teto para quantas candidatas um sorteio pode considerar.

Alguns provedores recomendam mudar a temperatura ou o top-p, e não os dois; quando a documentação
diz isso, siga.

## Nem toda API oferece todos

O conjunto de controles é escolha do provedor. No momento em que este curso foi escrito (2026), a
temperatura está em quase todas, o top-p é muito oferecido, e o top-k falta em algumas APIs
conhecidas. Os nomes também variam: você pode encontrar `top_p`, `topP` ou `nucleus`. **Leia a
referência da API do modelo que você chama, confira a data na página, e não suponha que um parâmetro
existe porque outro provedor o tem.** Uma API pode recusar um parâmetro que não conhece ou ignorá-lo
em silêncio, e o segundo caso é o que custa uma tarde.
