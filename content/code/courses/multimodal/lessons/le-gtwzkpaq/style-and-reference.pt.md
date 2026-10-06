---
title: Estilo, referências e manter uma identidade
version: 1
---

Uma newsletter que sai toda semana precisa de imagens que pareçam pertencer ao mesmo lugar. Um banner bom é um prompt; cinquenta banners que parecem da mesma loja são um **estilo**, e manter um é mais difícil do que encontrar um.

## De onde vem um estilo

**Das palavras.** As partes de meio, estilo e paleta do prompt, mantidas fixas em todo banner, são o jeito mais barato de segurar uma identidade. Escreva-as uma vez, guarde-as no programa como constante, e deixe só o assunto mudar de semana em semana. O `axes.py` já tem esse formato.

**De uma imagem de referência.** Várias APIs recebem uma imagem existente junto com o prompt e a usam como guia. O modelo de imagem do Gemini recebe imagens no mesmo pedido que o texto, e o endpoint de edição da OpenAI recebe uma ou mais imagens de entrada (aula 9). Uma referência segura cores, textura e composição muito melhor do que palavras, e é assim que uma marca mantém uma identidade ao longo de um ano.

**Do nome de um artista.** Esse é o atalho mais procurado, e deve ser evitado num produto. Pedir "no estilo de" um ilustrador vivo copia o trabalho identificável de uma pessoa que não concordou e não é paga por isso. Vários provedores hoje recusam ou suavizam prompts que citam artistas vivos. Descreva as qualidades que você quer (aquarela solta, textura de papel aparente, verdes apagados) e elas são suas.

## Editar, não gerar de novo

Quando uma imagem está quase certa, gerar de novo joga fora o que estava certo junto com o que estava errado, porque uma nova execução parte de um novo ruído. **Editar** mantém a imagem e redesenha só uma região: você manda a imagem, uma **máscara** marcando a parte a mudar e um prompt descrevendo o que deve estar ali. O resto da imagem fica como estava. A aula 9 faz isso pela API, com máscara e tudo.

## Um guia de estilo para imagens

O texto da Marginalia tem uma voz; as imagens deveriam ter um guia escrito também, curto o bastante para colar num prompt:

| fixo | livre |
|---|---|
| meio: ilustração em aquarela | o assunto |
| paleta: ocre quente e verde escuro | a hora do dia, dentro do razoável |
| composição: larga, espaço vazio no terço direito | o número de objetos |
| nenhum texto na imagem, nenhum rosto de pessoa | |

A segunda linha da coluna "fixo" é tanto uma decisão quanto um estilo: **sem rostos** evita gerar algo que pareça uma pessoa real, que é o assunto da próxima seção.
