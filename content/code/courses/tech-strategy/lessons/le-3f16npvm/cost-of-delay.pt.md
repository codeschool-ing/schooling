---
title: Custo de atraso, em reais por semana
version: 1
---

Don Reinertsen, em *The Principles of Product Development Flow* (2009), defendeu que, se um time
quantifica uma coisa só sobre o seu trabalho, deve quantificar o **custo de atraso**: quanto custa ter
isto mais tarde em vez de agora. A aula 12 de process-management o pôs em pontos relativos. Aqui ele
vai em dinheiro, por um motivo: os quatro itens na mesa do Davi disputam as mesmas pessoas, e a
comparação precisa sobreviver depois que todos saem da sala.

## As quatro estimativas da Coreto

Davi e Júlia sentaram com as pessoas mais próximas de cada item e fizeram a mesma pergunta para cada
um: a cada semana em que isto não está pronto, o que a Coreto perde? Combinaram responder em reais
por semana e anotar o que cada estimativa contém.

| candidato | custo de atraso por semana | duração | o que a estimativa contém |
|---|---|---|---|
| Pix parcelado | R$ 48.000 | 12 semanas | taxas das vendas perdidas para compradores que querem parcelar e vão para um vendedor que oferece isso |
| Mapas de assentos para festivais | R$ 30.000 | 6 semanas | taxas de ingressos de festival, conforme os organizadores escolhem uma plataforma com mapa de assentos para o próximo evento |
| Correção das reservas | R$ 18.000 | 3 semanas | as aberturas de vendas em risco enquanto as reservas bloqueiam linhas, e os juros que todos os times pagam sobre o código |
| API de parceiros | R$ 12.000 | 4 semanas | taxas dos ingressos que os revendedores venderiam nos próprios sites |

**São estimativas, e são honestas sobre isso.** Ninguém na Coreto sabe ao real quanto custa por
semana não ter o Pix parcelado. O que se sabe basta para pô-lo ao lado dos outros três com alguma
confiança, e o método não precisa de mais precisão que isso. Dois itens com estimativas próximas
trocam de lugar com uma pequena mudança em qualquer uma delas, e a próxima seção trata isso como
motivo para discuti-los, não para confiar nas casas decimais.

## O que entra numa estimativa

Três hábitos deixam os números comparáveis, o que importa mais do que deixá-los exatos.

**Uma unidade para tudo.** Reais por semana, para todos os itens. Uma estimativa em "clientes
afetados" para um item e em "incidentes evitados" para outro não cabe numa fila só. A correção das
reservas mostra por que isso é difícil: o custo dela é risco, uma abertura de vendas que falha ou
não numa dada semana. Davi a precificou como uma média ao longo das semanas, o que é grosseiro; a
aula 20 mostra como fazer isso direito, com uma probabilidade e um valor.

**As premissas escritas ao lado do número.** "Taxas de vendas perdidas" dá para conferir depois;
"valor estratégico", não. Quando a estimativa errar — e algumas destas vão errar —, uma premissa
escrita mostra qual parte estava errada.

**Produto é dono do valor, engenharia é dona da duração.** O time da Júlia sabe o que os
compradores pedem e com o que as casas ameaçam; o do Davi sabe quanto tempo o trabalho leva. Cada um
confere o outro, e nenhum estima sozinho. Um time de engenharia que estima o custo de atraso do
próprio trabalho de dívida, sem ninguém de produto na sala, produz um número que produto vai
descontar à primeira vista.

## A premissa por baixo

A conta da próxima seção supõe que o custo de cada item corre num **ritmo constante** em cada semana
de espera: R$ 48.000 nesta semana, o mesmo na próxima, e assim por diante. É o perfil de urgência
padrão da aula 12 de process-management, e é um primeiro modelo razoável para a maioria das
funcionalidades.

Nem todo item tem esse formato. Se os organizadores de festivais assinam os contratos da temporada
numa data conhecida, os mapas de assentos são um item de data fixa: nada se perde até a data, e tudo
depois dela. Um item assim não é ordenado pelo método abaixo; ele é agendado para chegar antes da
data, e o resto da fila se ordena em volta dele. **Pergunte pelo formato antes de rodar a conta**,
porque um item de data fixa passado por uma fórmula de ritmo constante sai no lugar errado.

## O tamanho sozinho não decide

Olhando só o custo de atraso, o Pix parcelado é o primeiro item óbvio: R$ 48.000 por semana é o
maior número da tabela, e a correção das reservas, com R$ 18.000, é a terceira. Júlia faz exatamente
esse argumento, e é um argumento razoável.

**Ele deixa a duração de fora.** O Pix leva 12 semanas; a correção das reservas leva 3. Enquanto o
Pix é construído, todos os outros itens esperam doze semanas; enquanto a correção das reservas é
construída, os outros esperam três. A próxima seção junta os dois fatos num número por item, e nesse
número a correção das reservas vem primeiro.
