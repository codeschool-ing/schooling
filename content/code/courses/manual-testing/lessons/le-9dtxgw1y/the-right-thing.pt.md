---
title: Quando o problema é o requisito
version: 1
---

As três primeiras seções desta aula produziram três tipos de achado, e só um deles é um defeito do
boxoffice. **Cada tipo vai para um lugar diferente e é decidido por uma pessoa diferente**, e mandar
um deles para o lugar errado é o jeito de um bom achado sumir.

## Quatro achados, quatro destinos

| o que você encontrou | o que é | para onde vai | quem decide |
|---|---|---|---|
| o boxoffice faz algo que R1 a R9 dizem que não pode | um defeito | um relato de defeito que cita o requisito, aula 15 | o time, na triagem, aula 16 |
| um requisito admite duas leituras | uma ambiguidade | uma pergunta ao dono do requisito, antes de os casos serem escritos | o dono |
| o boxoffice atende ao requisito e o requisito não atende à necessidade | um achado de validação | o mesmo dono, com a jornada que o mostra | o dono |
| o boxoffice se afasta do requisito e o desvio parece melhor | um defeito, por enquanto | um relato de defeito que diz isso, e uma proposta de mudança no requisito | o dono |

O dono aqui é a gerente do teatro, que escreveu R1 a R9. Numa organização maior é quem ocupa esse
papel: um product owner, um analista de negócios, o representante do cliente.

## Dois jeitos de perder um achado

**Relatar um achado de validação como defeito.** Ana registra "o boxoffice recusa um grupo escolar"
no sistema de defeitos. Rui lê o R4, vê que o boxoffice faz exatamente o que ele diz e fecha o
relato como funcionando conforme especificado. Ele está certo, e a pergunta sobre grupos escolares
agora está fechada junto, numa ferramenta que a gerente nunca lê. A aula 16 trata de rejeições
como essa, e a maioria delas está certa sobre o produto e calada sobre o requisito.

**Testar contra o que você acha que o teatro quer.** O erro oposto é mais silencioso. Ana decide
que meia, obviamente, é por ingresso, escreve os casos esperando R$ 152,00 para a família da seção
03 e relata um defeito quando o boxoffice cobra R$ 120,00. Agora o resultado esperado do caso dela
é a opinião dela, e Rui tem um relato dizendo que o código está errado diante de uma regra que
ninguém escreveu. A aula 1 disse que um testador testa contra algo escrito; quando o que está
escrito não está claro, a saída é fazer com que seja reescrito, e não preencher a lacuna por conta
própria.

O caminho entre os dois é testar o requisito como está escrito e levantar a pergunta sobre ele à
parte, ao dono dele, em palavras que o dono consiga responder.

## O desvio que parece melhor

A quarta linha da tabela é a que mais gera discussão. Suponha que Rui, achando o R6 incômodo,
tivesse feito o boxoffice deixar o cliente cancelar também um pedido pago, além de um reservado, e
que a gerente tivesse gostado. Isso ainda entra como defeito, com uma frase dizendo que parece uma
melhoria, porque **um requisito que não descreve mais o produto torna errado todo teste que vier
depois**. O próximo testador, ou a própria Ana na aula 10 rodando a suíte de regressão, relataria o
mesmo desvio de novo, e os casos que citam o R6 esperariam algo que o produto não faz mais. Ou o
produto volta ao R6, ou o R6 muda para bater com o produto. Quem escolhe é o dono, e o relato é o
caminho pelo qual a escolha chega até ele.

## O que acontece quando a resposta chega

Digamos que a gerente responda às perguntas do R5: a meia é por ingresso, e o estudante mostra a
carteirinha na porta. A mudança segue uma ordem fixa:

1. o requisito é reescrito primeiro, para carregar a resposta: "Cada ingresso de estudante custa
   metade do preço do espetáculo, e o estudante mostra a carteirinha na porta";
2. os casos que citam o R5 mudam em seguida, o que a rastreabilidade da aula 2 transforma numa
   busca em vez de um palpite;
3. o produto muda por último, e são os casos alterados que o conferem.

Fazer em qualquer outra ordem deixa um dos três fora de compasso com os outros por um tempo, e "por
um tempo" num projeto muitas vezes quer dizer até o dia da versão. Uma mudança de requisito no meio
de uma versão também pode mexer no plano, porque chegou trabalho novo; a seção 07 da aula 1 é onde o
cronograma diz o que espera pelo quê.

Nada disso é o testador reescrevendo requisitos. Ana pode propor a redação, e muitas vezes deve,
porque acabou de ler cada frase atrás do segundo sentido. A decisão fica com quem é dono da
necessidade, e **a parte do testador é que nenhuma pergunta deixe de ser feita e nenhuma resposta
fique fora dos requisitos escritos**.
