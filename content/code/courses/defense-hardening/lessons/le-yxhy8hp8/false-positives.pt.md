---
title: Falsos positivos, e por que a conferência importa
version: 1
---

**Uma regra de DLP que dispara com coisas que não são dados pessoais acaba desligada.** Não por uma
política: pelas pessoas que ela vive barrando, que aprendem a renomear arquivos, compactá-los ou
mandá-los por outro caminho, e pelo administrador que para de ler os alertas dela. Então o primeiro
número a conhecer de qualquer regra é com que frequência ela erra.

Rode o scanner sem a conta, guardando toda ocorrência que os padrões acharem:

```
ana@desk:~$ python3 scan.py --no-check docs
docs/clientes.csv: 20 CPF, 20 card, 0 rejected, e.g. 881******41
docs/pedidos.txt: 3 CPF, 0 card, 0 rejected, e.g. 123******01
```

O arquivo de pedidos agora informa três CPFs onde antes havia um, e o exemplo que ele mostra é um
número de pedido. Num servidor de arquivos de verdade, cheio de notas fiscais, protocolos e ramais, a
distância entre as duas execuções é a diferença entre um relatório com que alguém consegue agir e um
que ninguém abre.

A conferência tira a maior parte dos falsos positivos e nunca todos, e o pedido `98765432100` é o que
sobra: um número válido que não é CPF de ninguém neste arquivo. Três coisas reduzem o que sobra, e
todo produto oferece alguma forma de cada uma:

- **Contexto.** Um número ao lado da palavra *CPF*, ou numa coluna chamada `cpf`, tem muito mais
  chance de ser um do que os mesmos dígitos depois de *Pedido*. Regras que olham as palavras em volta
  de uma ocorrência cortam muito os falsos positivos, e perdem o CPF que alguém digitou numa
  observação livre.
- **Limiares.** Um CPF num documento muitas vezes é legítimo: um contrato cita um cliente. Cinquenta
  numa planilha são uma lista de clientes. Muitas regras só disparam acima de uma contagem, e é também
  por isso que o scanner informa uma contagem.
- **Correspondência exata de dados**, da seção anterior: um número que está na lista real de
  clientes é de um cliente; qualquer outro não é.

## Monitore antes de bloquear

**Toda implantação de DLP começa observando e não barrando.** Por semanas as regras só registram o
que teriam bloqueado, e alguém lê o registro: que regras disparam, nos arquivos de quem, em que
trabalho. Só as regras cujas ocorrências eram reais passam a bloquear, e as outras são ajustadas ou
abandonadas. Ligar o bloqueio no primeiro dia para a folha de pagamento na primeira vez que ela roda,
e a regra que fez isso nunca mais volta a ser ligada.

Com o bloqueio ligado, um bom produto oferece também **justificativa**: a pessoa vê por que o arquivo
foi retido e pode enviá-lo assim mesmo com um motivo escrito, que fica registrado. Isso mantém
possível um envio legítimo a um auditor às três da tarde, e transforma o caso deliberado numa pessoa
assinando o próprio nome.
