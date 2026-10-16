---
title: Quatro leituras erradas do CAP
version: 1
---

O CAP é citado mais vezes do que é lido, e quatro leituras erradas explicam a maior parte do que dá errado
quando ele é usado para defender um projeto.

**"Escolha dois de três."** Como a seção sobre partições mostrou, o P não está no cardápio para um sistema
distribuído. A afirmação real é mais estreita: com partição, escolha C ou A. O próprio Brewer escreveu em
2012, doze anos depois da conjectura, que "dois de três" era enganoso.

**"O nosso banco é CP" ou "AP", como propriedade do produto.** A escolha é feita por configuração e muitas
vezes por requisição. O PostgreSQL do laboratório foi CP e AP em dez minutos, por uma configuração.
DynamoDB e Cassandra deixam cada leitura ou escrita dizer quantas réplicas precisam responder, o assunto da
próxima seção. **A posição de um sistema no CAP é uma propriedade de como ele é usado**, e duas tabelas num
banco podem ficar em lados opostos.

**"C" quer dizer o C do ACID.** A consistência do ACID quer dizer que uma transação deixa o banco
obedecendo às suas restrições, uma chave estrangeira, um `CHECK`. A do CAP quer dizer que toda leitura vê
a última escrita, entre cópias. Um banco de nó único é consistente no sentido ACID sem réplica nenhuma;
um replicado pode ser consistente no sentido ACID em cada nó e ainda devolver um valor velho do standby.

**"Disponibilidade" quer dizer tempo no ar.** O A do CAP pede que todo nó que não falhou responda a toda
requisição. Um sistema que recusa escritas durante uma partição não é "A" no sentido do CAP e ainda pode
ter um tempo no ar excelente no sentido operacional, porque partições são raras. E um sistema "A" pode ser
lento a ponto de ser inútil. Disponibilidade como número de noves é outra ideia, operacional, de que trata
a aula 11 de `scale`.

## Para que o CAP serve

Sem essas leituras, o teorema deixa uma pergunta útil para qualquer dado que mora em mais de uma máquina:
**quando as cópias não conseguem conversar, o sistema deve recusar, ou responder e arriscar estar errado?**
Feita por dado, por pessoas que sabem quanto custa uma resposta errada, ela produz bons projetos. Feita
sobre um sistema inteiro, ou sobre um produto, produz discussões.
