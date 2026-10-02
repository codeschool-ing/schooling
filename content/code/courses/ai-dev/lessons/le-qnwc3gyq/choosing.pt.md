---
title: Escolhendo um modelo
version: 1
---

O preço é o número mais fácil de comparar e o último a decidir. **Um modelo é bom o bastante para
uma tarefa ou não é**, e só a sua própria avaliação diz qual, rodada nos seus próprios casos, como a
aula 5 montou. Um ranking mede a tarefa de outra pessoa.

## A ordem para decidir

1. **Ele faz a tarefa?** Rode a avaliação da aula 5 contra cada candidato. Fique com os que passam
   na régua que a tarefa exige, e descarte o resto, custe o que custar.
2. **Ele comporta?** A janela de contexto precisa caber o seu maior prompt real com espaço para a
   resposta, e o limite de resposta precisa caber a sua resposta real mais longa. Os dois estão na
   tabela de preços da aula 2.
3. **Ele é rápido o bastante?** Meça o tempo até o primeiro token e o tempo total, como a aula 9
   fez, de onde ficam os seus servidores, nos horários em que os seus usuários perguntam.
4. **Os dados podem ir para lá?** Os termos do provedor, a região onde a requisição é processada e o
   que fica guardado depois, como a aula 10 seção 09 lista. Um modelo que falha aqui está fora, por
   melhor que seja.
5. **Depois o preço**, entre os modelos que sobraram, na sua carga, como a aula 10 seção 06 calculou.

## Mantenha a escolha reversível

Modelos são substituídos a cada poucos meses, e preços mudam. **A decisão que dá para tomar uma vez
é quão fácil vai ser a próxima**:

- **Ponha o nome do modelo na configuração**, não no código, como o adaptador da aula 10 seção 08
  faz. Trocar de modelo vira um deploy, não um pull request pelo código inteiro.
- **Mantenha a avaliação rodável.** Um modelo novo vira uma pergunta que a avaliação responde em
  minutos, em vez de uma opinião discutida numa reunião.
- **Fixe a versão completa do modelo** onde o provedor oferecer uma. Um apelido que passa a apontar
  para um modelo mais novo muda o seu produto no calendário do provedor, não no seu.
