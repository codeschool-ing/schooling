---
title: O que você assume
version: 1
---

A seção 06 comparou o aluguel de uma máquina com a conta de uma API. A comparação deixou de fora a
maior linha da conta de um modelo auto-hospedado, que é **o tempo das pessoas que o mantêm
funcionando**. Um provedor de API divide esse tempo entre todos os clientes; um modelo auto-hospedado
põe todo ele em você.

Aqui está no que esse tempo é gasto, mais ou menos na ordem em que chega:

- **Montar.** Escolher um runtime e um formato, fazer os drivers e o runtime se entenderem, achar a
  quantização que cabe, pôr um endpoint autenticado na frente. Dias, na primeira vez.
- **Vigiar.** Latência, memória, erros, tamanho da fila. Um servidor de modelo sem memória pode
  falhar com prompts longos enquanto responde aos curtos normalmente, que é o tipo de falha que uma
  checagem de saúde que manda "olá" nunca encontra.
- **Atualizar.** O runtime publica correções, algumas de segurança; o sistema operacional e os
  drivers precisam de patches; uma versão nova do modelo aparece e precisa passar pela avaliação da
  aula 5 antes de substituir a antiga.
- **Escalar.** Quando a carga dobra, uma segunda máquina, e algo na frente para dividir as
  requisições entre as duas.
- **Ser acordado por ele.** Se o atendimento depende dele, alguém responde quando ele para num
  domingo. Com uma API esse alguém é o provedor, e o seu trabalho é tentar de novo e esperar (aula
  21).

## Transformar tempo em comparação

Ponha um número nisso antes de decidir. Se manter o modelo funcionando toma **quatro horas do mês de
alguém**, essas horas entram na soma da seção 06 pelo que custam à Lantern Books, ao lado da máquina
de US$ 1.500. No volume da ana elas deixam uma comparação já desequilibrada ainda mais. Para uma
empresa que manda milhões de requisições por dia elas podem ser a linha pequena, e é por isso que
usuários grandes auto-hospedam e os pequenos raramente deveriam.

## O que uma API também faz e é fácil esquecer

Ela **absorve os picos**. A frota de um provedor atende milhares de clientes, e a segunda-feira de
manhã da Lantern Books é um erro de arredondamento ali. Uma máquina auto-hospedada tem exatamente a
capacidade que tem, e os quatrocentos e-mails por dia não chegam distribuídos: eles se amontoam
depois de uma newsletter, de uma greve da transportadora, de um feriado. **A máquina precisa ser
dimensionada para o amontoado**, e o equilíbrio da seção 06 supôs que ela ficaria ocupada o mês
inteiro.
