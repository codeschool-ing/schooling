---
title: Estágios 1 a 3, o negócio e o sistema
version: 1
---

Os três primeiros estágios constroem o contexto contra o qual todo o resto é julgado. Na Vereda
levaram uma manhã, com o daniel na sala para o primeiro.

### Estágio 1: definir os objetivos

**Para que serve o sistema, e o que doeria se ele parasse de fazer isso?** A saída é uma lista
curta de objetivos de negócio, os requisitos de segurança e de conformidade que vêm com eles, e uma
primeira declaração de impacto: quanto custa falhar em cada objetivo.

| objetivo | por que importa | conformidade |
|---|---|---|
| pacientes agendam e pagam online | cerca de 60% dos agendamentos passam pelo portal; o resto, por telefone | defesa do consumidor, regras de cartão por meio do gateway |
| dado clínico continua privado | pacientes contam o que não contariam a mais ninguém | a **LGPD**: dado de saúde é *dado pessoal sensível* (art. 5º, II, e art. 11) |
| lembretes chegam aos pacientes | uma sessão perdida é um horário vazio que ninguém paga | nenhuma própria |
| a Vereda cumpre a LGPD | a ANPD pode multar e mandar parar o tratamento | a própria lei |

A tabela é onde o daniel justifica a presença. Uma desenvolvedora não teria escrito que 60% dos
agendamentos passam pelo portal, e é esse número que torna T01 e T10 caras no estágio 7.

### Estágio 2: definir o escopo técnico

**O que exatamente está sendo modelado, e do que é feito?** Os componentes, a infraestrutura onde
rodam, os terceiros e as dependências que vêm com cada um. Na Vereda: o portal, o console da
equipe e o worker, a conta de nuvem onde rodam, o banco gerenciado, o armazenamento de objetos, o
provedor de SMS e o gateway de pagamento, e as bibliotecas que cada processo importa. A biblioteca
de PDF que o console usa para mostrar exames está nessa lista, e foi assim que a T14 ganhou nome.

O estágio 2 também anota **o que está fora do escopo**: o Wi-Fi e os notebooks das próprias
clínicas, de que o bruno cuida à parte. Fora do escopo é uma decisão, e anotá-la impede que o
modelo seja culpado depois por algo que ele nunca cobriu.

### Estágio 3: decompor a aplicação

**Como o dado se move, e onde a confiança muda?** Esta é a aula 2: o DFD de nível 1, as fronteiras
de confiança, os atores e os pontos de entrada. O PASTA acrescenta uma lista de **casos de uso**
ao lado do desenho, porque o estágio 6 vai precisar deles: "um paciente agenda e paga", "um
fisioterapeuta abre um exame", "o worker manda os lembretes de amanhã". Cada caso de uso é um
caminho pelo DFD, e cada um será lido de trás para a frente no estágio 6 como a rota que alguém
poderia abusar.

A Vereda já tinha o estágio 3 pronto quando começou o PASTA. É o caso comum: uma equipe que já
desenha DFDs adota o PASTA acrescentando estágios em volta do trabalho que já faz.
