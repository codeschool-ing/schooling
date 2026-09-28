---
title: "FaaS, CaaS, DBaaS: mais pontos na mesma linha"
version: 1
---

Leia sobre serviços de nuvem por uma hora e você vai encontrar mais uma dúzia de nomes terminados em
*as a service*. A conclusão errada é que cada um é uma categoria nova para aprender. **Cada um é um
ponto na linha que você já tem**, e o nome diz onde fica o ponto: ele diz o que você entrega.

**Contêineres como serviço**, o CaaS, recebe uma imagem de contêiner: a sua aplicação empacotada junto
com o runtime e as bibliotecas de que precisa, um formato que o curso `docker` constrói. A plataforma
roda a imagem em máquinas que ela administra. Isso põe a linha *abaixo* de onde o PaaS a colocou. O
sistema operacional do host é do provedor, mas o runtime está dentro da sua imagem, então, quando a
linguagem recebe uma correção de segurança, reconstruir a imagem com ela volta a ser trabalho seu.
Serviços de Kubernetes gerenciado e serviços que rodam um único contêiner sob demanda ficam aqui.

**Funções como serviço**, o FaaS, recebe uma única função: um trecho de código que recebe um evento, uma
requisição ou um arquivo chegando, e retorna. A plataforma a inicia quando um evento chega, roda tantas
cópias quantos forem os eventos, e não roda nenhuma quando nada está acontecendo. Você paga por
invocação e por GB-segundo, as duas linhas do Lambda na captura do começo desta aula. A linha fica um
pouco acima do PaaS, porque não existe nem um processo seu rodando para administrar. A aula 8 trata
disso, com o nome pelo qual costuma ser vendido, *serverless*.

**Banco de dados como serviço**, o DBaaS, é um motor de banco de dados que o provedor instala, corrige,
replica e copia num horário que você define. O Amazon RDS, o Google Cloud SQL e o Azure SQL Database são
exemplos. A linha passa no meio do banco: o motor é deles, e **o esquema, as consultas, os índices, os
usuários e os dados são seus**. Uma consulta lenta continua lenta num banco gerenciado, e continua sendo
você quem precisa descobrir por quê.

## Duas perguntas para qualquer nome

Nomes novos não param de chegar: armazenamento como serviço, identidade como serviço, backend como
serviço, desktop como serviço. Você não precisa de uma lista deles. Faça duas perguntas a qualquer
serviço, e as respostas o situam:

1. O que eu entrego? Uma imagem de máquina, um contêiner, código, uma função, um esquema, ou nada além
   dos meus dados.
2. O que continua meu depois? Tudo acima do que eu entreguei, e sempre as duas fileiras de cima.

Um banco de dados gerenciado respondido assim: eu entrego um esquema e os meus dados; o motor, os
patches dele e os discos são deles; as minhas consultas, os meus usuários e os meus dados continuam
meus. Essa é uma descrição completa do serviço, no único vocabulário que este curso usa, e seria a
mesma em qualquer um dos três grandes provedores.
