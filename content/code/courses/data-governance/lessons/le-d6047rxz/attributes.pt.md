---
title: Regras que leem um atributo
version: 1
---

A política da Carla já lê algo que não é um papel: os estados que ela atende, de uma tabela. Essa
é a ideia do **controle de acesso baseado em atributos** (ABAC) — uma regra que compara atributos
da pessoa, do dado e do momento, em vez de perguntar só o cargo de alguém. "Um atendente vê
chamados de clientes dos estados que atende." "Um farmacêutico vê uma receita só enquanto o
pedido está aberto." "Ninguém exporta dado de saúde fora do horário comercial."

A força disso é que uma regra cobre todo caso que seus atributos descrevem. O perigo está numa
pergunta que ninguém faz sobre os próprios atributos: **quem os define?**

## Um primeiro rascunho, e por que está errado

A tabela de chamados precisa da mesma regra dos clientes. O primeiro rascunho da Ana pega a região
de uma **configuração da sessão**, que é rápido de escrever e tentador, porque muitas aplicações
já definem uma:

```sql
-- A FIRST DRAFT, AND WRONG: the region comes from a setting of the session.
SET ROLE ipe_owner;
CREATE POLICY agent_sees_session_region ON support.tickets
  FOR SELECT TO support_agent
  USING (customer_id IN (SELECT c.customer_id FROM sales.customers c
                         WHERE c.state = current_setting('ipe.region', true)));
ALTER TABLE support.tickets ENABLE ROW LEVEL SECURITY;
```

```
ana@lab:~/gov$ psql -f setting.sql
SET
CREATE POLICY
ALTER TABLE
ana@lab:~/gov$ psql service=carla -c "SET ipe.region = 'SP'" -c "SELECT count(*) FROM support.tickets"
SET
 count 
-------
   586
(1 row)

ana@lab:~/gov$ psql service=carla -c "SET ipe.region = 'MG'" -c "SELECT count(*) FROM support.tickets"
SET
 count 
-------
     0
(1 row)
```

Filtra exatamente como pretendido. A Carla diz que está trabalhando com São Paulo e vê 586
chamados.

E aí o problema: **a Carla escolheu o valor.** Qualquer um pode dar `SET` numa configuração
própria na sua sessão — é para isso que elas existem — então o "atributo" que decide o que ela vê
é um que ela muda digitando outro estado. Aqui ele calhou de estreitar a visão dela. Uma regra
escrita ao contrário, ou uma configuração com um nível de autorização, a alargaria.

**Um atributo que decide acesso precisa vir de algum lugar onde a pessoa não escreve.** As
configurações da sessão, um cabeçalho que o cliente envia, um campo de formulário, uma
informação num token que a aplicação não verificou — cada um é o usuário descrevendo a si mesmo.

## O atributo vindo de uma tabela

```sql
-- The attribute comes from a table Carla can read and cannot write.
SET ROLE ipe_owner;
DROP POLICY agent_sees_session_region ON support.tickets;
CREATE POLICY agent_sees_own_states ON support.tickets
  FOR ALL TO support_agent
  USING (customer_id IN (SELECT c.customer_id FROM sales.customers c))
  WITH CHECK (status IN ('open', 'closed'));
```

```
ana@lab:~/gov$ psql -f attribute.sql
SET
DROP POLICY
CREATE POLICY
ana@lab:~/gov$ psql service=carla -c "SET ipe.region = 'MG'" -c "SELECT count(*) FROM support.tickets"
SET
 count 
-------
   854
(1 row)

ana@lab:~/gov$ psql service=carla -c "INSERT INTO support.agent_regions VALUES ('carla', 'MG')"
ERROR:  permission denied for table agent_regions
ana@lab:~/gov$ psql service=carla -c "UPDATE support.tickets SET status = 'escalated' WHERE ticket_id = 2"
ERROR:  new row violates row-level security policy for table "tickets"
ana@lab:~/gov$ psql service=carla -c "UPDATE support.tickets SET status = 'closed' WHERE ticket_id = 2"
UPDATE 1
```

A política de chamados não lê mais configuração nenhuma. Ela permite um chamado quando o cliente
dele é um que a Carla consegue ver — e quais clientes ela vê já é decidido pela política de
`sales.customers`, que lê `support.agent_regions`. **A subconsulta de uma política roda com os
privilégios e políticas de quem lê**, então uma regra sobre regiões agora governa as duas tabelas.

O que a Carla tenta em seguida é recusado pelos motivos certos:

- **Mudar `ipe.region` para `MG` não muda nada.** Ela vê 854 chamados: os de São Paulo e do Rio.
- **Acrescentar-se a Minas Gerais é recusado**, porque a tabela de atributos é legível pelos
  atendentes e gravável só pelo dono.
- **Uma atualização precisa deixar a linha dentro da política.** A cláusula `WITH CHECK` permite
  status `open` ou `closed` e mais nada, então `escalated` é recusado e `closed` é aceito.

Essa última linha é outro uso do mesmo mecanismo. `USING` decide quais linhas existentes um papel
pode ver, atualizar ou apagar; `WITH CHECK` decide quais linhas ele pode *escrever*. Um
atendente que pudesse pôr qualquer status inventaria estados que o resto do sistema não entende.

## Onde os atributos moram na prática

Num warehouse ou num lakehouse os atributos são tags: uma coluna marcada `pii`, um conjunto de
dados marcado `health`, uma pessoa cujo grupo no provedor de identidade diz `region:south`. A
plataforma avalia regras sobre as tags. A pergunta é a mesma, e a resposta também: **as tags do
dado são definidas por quem governa o dado, e os atributos de uma pessoa por quem governa a
identidade** — nunca pela pessoa de quem a regra trata.
