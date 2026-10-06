---
title: Esquecer
version: 1
---

Tudo na tabela de memória foi digitado por um cliente num chat de atendimento, e clientes digitam
aquilo com que precisam de ajuda: o nome, o pedido, o endereço, às vezes um número de cartão. **Uma
memória de um cliente é dado pessoal**, mantido pela Marginalia sobre uma pessoa identificável, e no
Brasil a LGPD dá a essa pessoa o direito de saber o que é mantido e de pedir que seja apagado, como o
aviso de privacidade do acervo promete.

A tabela torna os dois direitos baratos, porque toda linha nomeia a conta:

```
ana@lab:~/rag$ psql -Atc "SELECT account, count(*) FROM memories GROUP BY account ORDER BY account"
A-1001|12
A-1002|4
ana@lab:~/rag$ python remembered.py A-1002
 1  Hello, this is Rafael Lima. My order MG-31770254 has not arrived.
 2  It was sent by standard delivery and the tracking has not changed for twelve working days.
 3  I would prefer a refund rather than waiting for a new parcel.
 4  Could you remind me of my order number?
```

O que a Marginalia lembra sobre o Rafael são quatro frases, nas palavras dele, legíveis por ele e por
um auditor sem interpretar nada. E quando ele pede para ser esquecido:

```schooling-example
{
  "language": "python",
  "file": "memory.py",
  "parts": [
    {
      "code": "def forget(account):\n    return conn.execute(\"DELETE FROM memories WHERE account = %s\", (account,)).rowcount",
      "note": "Apagar a memória de um cliente é um comando, porque toda linha leva a conta. Uma tabela que não levasse precisaria de uma busca no texto para achar o que apagar."
    }
  ]
}
```

```
ana@lab:~/rag$ python -c "import memory; print(memory.forget(\"A-1002\"), \"rows deleted\")"
4 rows deleted
ana@lab:~/rag$ psql -Atc "SELECT account, count(*) FROM memories GROUP BY account ORDER BY account"
A-1001|12
```

**Quatro linhas apagadas, e só as dele.** As doze da Beatriz continuam lá.

## Decidir o que guardar, antes de guardar

Apagar a pedido é o mínimo. Acima disso, uma memória precisa das decisões que uma equipe toma para
qualquer dado pessoal:

- **Um motivo para cada coisa guardada**, e um prazo depois do qual ela sai. Os turnos de um chat
  ajudam a responder os próximos turnos daquele chat e talvez o próximo chat; não precisam viver anos.
  Uma coluna `expires` e uma exclusão noturna fazem do prazo de retenção um fato, e não uma política.
- **Coisas que nunca se guardam.** Um número de cartão digitado num chat não deveria chegar à tabela,
  nem ao registro, nem a um prompt. O programa pode mascarar um padrão assim antes de o `remember`
  gravar a linha, do mesmo jeito que achou os números de pedido.
- **Tudo o que é derivado vai junto com a origem.** Se os turnos forem resumidos (aula 15) ou os fatos
  deles copiados para um estado ou um perfil, a exclusão precisa chegar lá também. Uma linha calculada
  a partir de uma linha apagada é o mesmo dado em outra forma.

A pergunta a fazer a toda função de memória é a que a próxima aula faz aos documentos: de quem é isto,
e quem mais pode ver.
