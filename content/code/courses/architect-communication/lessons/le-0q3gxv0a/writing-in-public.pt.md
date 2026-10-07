---
title: Escrever em público, e o que você pode dizer
version: 1
---

**Um artigo útil conta aos leitores sobre um problema que eles provavelmente vão ter, o que foi
tentado, o que falhou e o que funcionou, e diz só o que a empresa concordou que pode ser dito.** Na
prática, a segunda metade dessa frase vem primeiro: quase tudo o que um engenheiro sabe sobre o
próprio trabalho pertence ao empregador, e uma parte pertence aos clientes.

## Pergunte antes de escrever, não depois

Lívia queria escrever sobre o incidente de 6 de março e as cotas de conexão que vieram depois. Antes
de rascunhar qualquer coisa, ela consultou Otávio e a pessoa que cuida da comunicação pública da
Marola, com um esboço de um parágrafo. Eles concordaram, com três condições:

1. **Nenhum nome de cliente.** A Boa Praça não aparece.
2. **Nenhum número de receita ou de pedidos**, que a concorrência leria. "Milhares de checkouts com
   falha" pode; "1.350" não pode.
3. **Nenhum detalhe de segurança** que ajudasse alguém a atacar o sistema, o que excluiu citar as
   versões exatas de qualquer coisa.

Essas condições moldaram o artigo e o deixaram melhor: sem os números exatos, o artigo teve de explicar
o *formato* do problema, que é o que outros engenheiros conseguem de fato usar.

## O formato de um artigo útil

O post que Lívia publicou no blog de engenharia, *Como um job em lote derrubou nosso checkout, e a cota
que impediu que acontecesse de novo*, seguiu um formato que serve para a maior parte da escrita técnica
para um público de fora:

| parte | o que ela faz |
|---|---|
| o problema, como o leitor o reconheceria | "um job em segundo plano e o seu serviço mais movimentado dividem um banco de dados" |
| o que aconteceu | a noite, na ordem em que aconteceu, sem culpados |
| o que foi tentado, inclusive o que falhou | o alerta que apontou para o serviço errado; o primeiro palpite |
| o que funcionou | cotas por serviço, a janela no runbook, o alerta de conexões |
| o que faríamos diferente | "teríamos definido cotas no dia em que adicionamos o segundo serviço" |
| o que ainda não sabemos | limites honestos, que tornam o resto crível |

A quinta e a sexta linhas são onde a maioria dos posts de blog de empresa é mais fraca, e onde a
confiança do leitor é conquistada. **Um artigo que só mostra sucesso parece anúncio; um que mostra as
falhas parece experiência.**

## A aula 1 continua valendo

O leitor é um estranho com trinta segundos. O título diz o que ele vai aprender, o primeiro parágrafo
diz por que isso importa para ele, e os subtítulos carregam o argumento para quem só passa o olho. As
passadas de revisão da aula 1 valem com um acréscimo: **um leitor de fora da empresa**, que vai dizer o
que o artigo pressupõe e que ninguém fora da Marola sabe.
