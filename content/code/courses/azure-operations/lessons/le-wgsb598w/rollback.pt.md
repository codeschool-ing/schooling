---
title: Revertendo, e a única coisa que a troca não desfaz
version: 1
---

**Reverter um deploy em slot é a mesma troca de novo.** Depois da troca, o slot staging guarda a versão
anterior, já aquecida. Se a produção se comporta mal, trocar de volta a restaura no tempo de uma troca, sem
reconstruir nada. É esse o motivo de manter a versão antiga em staging até a nova rodar por um tempo, em vez de
implantar o próximo build por cima dela na mesma hora.

O que decide a velocidade disso não é a troca; é perceber. A regra da loja está escrita nos termos do que a
lição 14 vai medir: se a taxa de erro de `POST /checkout` nos quinze minutos depois de uma troca passar do
objetivo, troque de volta primeiro e investigue depois. Um rollback que espera um diagnóstico é um rollback que
espera enquanto os clientes falham.

## O que ela não desfaz

**Uma troca permuta código e configuração. Ela não toca nos dados.** Se a versão 42 renomeou uma coluna, a 41,
trocada de volta, consulta uma coluna que não existe mais, e o rollback que levou trinta segundos vira uma
queda por conta própria. O mesmo vale para um formato de mensagem, uma chave de cache, um arquivo gravado no
armazenamento num formato novo: qualquer coisa que a versão nova escreveu e a antiga não consegue ler.

A resposta não é um rollback melhor; são mudanças que tornam o rollback seguro. **Expandir, depois contrair.**
Cada mudança em dado compartilhado é dividida de modo que cada versão rode sobre os dados que a versão anterior
deixou:

```sql
-- release 42: expand. Old code ignores the column; new code writes both.
ALTER TABLE orders ADD delivery_window varchar(20) NULL;

-- release 43, a week later: contract. Only after nothing reads delivery_slot.
ALTER TABLE orders DROP COLUMN delivery_slot;
```

A versão 42 acrescenta a coluna nova e escreve nas duas. Trocar de volta para a 41 é seguro, porque a 41 nunca
soube de `delivery_window` e ainda encontra `delivery_slot`. Só quando a 42 tiver rodado o bastante para
ninguém mais trocar de volta é que a versão 43 remove a coluna antiga. O custo é uma segunda versão e uma
semana escrevendo duas colunas. O benefício é que **toda troca, nas duas direções, é segura**, e é isso que faz
o botão valer a pena.

Nada disto rodou no laboratório: não há App Service nem banco aqui. O SQL é SQL padrão, e `azure-data` trata do
Azure SQL em si.
