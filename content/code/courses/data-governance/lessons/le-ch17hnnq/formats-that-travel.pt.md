---
title: Formatos que viajam
version: 1
---

O feed sai da Ipê como um arquivo. O formato é a parte da interoperabilidade que está em grande parte
resolvida, e os poucos jeitos como ela ainda dá errado valem ser sabidos de cor:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "\copy (SELECT * FROM share.delivery_feed ORDER BY order_id LIMIT 3) TO STDOUT WITH (FORMAT csv, HEADER)"
SET
order_id,ordered_on,cep,city,state,items
100467,2026-06-30,01613-005,São Paulo,SP,3
100867,2026-06-30,20183-954,Rio de Janeiro,RJ,6
101189,2026-06-30,01279-281,São Paulo,SP,1
```

Esse CSV é um bom CSV, e cada propriedade dele é uma escolha:

- **uma linha de cabeçalho**, para uma coluna ser achada pelo nome e não pela posição;
- **datas em ISO 8601** — `2026-06-30` — e nunca `30/06/2026`, que um sistema configurado para os
  Estados Unidos lê como uma data impossível, ou `06/07/2026`, que ele lê como outro dia sem reclamar;
- **UTF-8**, para `São Paulo` chegar como `São Paulo`. Um arquivo escrito numa codificação antiga do
  Windows e lido como UTF-8 vira caracteres embaralhados, e um endereço que nenhum entregador acha;
- **nenhum número decimal** neste feed — mas, onde houver, ponto decimal e nenhum separador de
  milhar. No Brasil uma planilha escreve `1.234,56`, e a vírgula também é o separador do CSV;
- **CEPs como texto.** `01613-005` lido como número perde o zero da frente e o hífen, e uma planilha
  vai fazer exatamente isso se ninguém disser o contrário a ela.

## Além do CSV

CSV não tem tipos: todo valor é texto até alguém decidir outra coisa, e é daí que vem a lista acima.
**JSON** carrega tipos para números, booleanos e nulos, e o JSON Schema consegue descrevê-lo. **Parquet**
guarda um esquema tipado dentro do arquivo e comprime bem, e é o formato de costume para grandes
conjuntos de dados entre plataformas. O contrato nomeia o formato e, para CSV, nomeia a codificação, o
separador e o formato de data, porque o CSV sozinho não nomeia.

## Portabilidade é interoperabilidade para uma pessoa

O direito à **portabilidade** da aula 7 (artigo 18, V da LGPD) e o artigo 20 do GDPR — dados num
*formato estruturado, de uso corrente e de leitura automática* — são o mesmo problema com uma pessoa
como consumidora. A exportação em JSON da aula 7 o atende pelos mesmos motivos que este CSV: campos com
nome, valores com tipo, uma codificação padrão. Um PDF dos pedidos de um cliente é legível por uma
pessoa e por nenhum outro sistema, e não é um formato portável.
