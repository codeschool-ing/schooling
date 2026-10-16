---
title: O Compute Optimizer, a mesma pergunta feita pela AWS
version: 1
---

O **Compute Optimizer** faz em escala o que o `rightsize.py` fez para quatro instâncias: lê métricas do
CloudWatch de instâncias EC2, auto scaling groups, volumes EBS, funções Lambda, serviços do ECS no Fargate
e bancos RDS, e recomenda uma configuração para cada um. É grátis no nível padrão, depois que a conta
**adere**:

```
ana@laptop:~/aws/rightsize$ aws compute-optimizer update-enrollment-status --status Active 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the UpdateEnrollmentStatus operation (reached max retries: 2): <!doctype html>
```

O moto não tem Compute Optimizer nenhum, então o que vem a seguir é da documentação da AWS, não executado.

## O que ele diz

Cada recurso recebe um **achado** e até três **recomendações**:

| achado | significado |
|---|---|
| over-provisioned | uma opção menor ou mais barata aguentaria a carga |
| under-provisioned | falta ao recurso pelo menos uma dimensão, como faltava ao `worker` |
| optimized | a configuração atual cabe |

Cada recomendação traz a utilização projetada no tamanho novo, um **risco de desempenho** de muito baixo a
muito alto, e a economia mensal estimada a preços sob demanda. **O risco de desempenho é a coluna a ler
primeiro**: uma recomendação que economiza 40% com risco alto é uma recomendação para testar, não para
aplicar.

## Do que ele precisa

- **Tempo.** Precisa de pelo menos 30 horas de métricas antes de dizer qualquer coisa, e olha catorze dias
  para trás por padrão. As **enhanced infrastructure metrics**, uma opção paga por hora de recurso,
  estendem o período para três meses, o que importa para uma carga com pico mensal, como relatórios de
  fim de mês.
- **Memória.** Como no `rightsize.py`, a memória só entra na análise quando o agente do CloudWatch a
  publica. Sem ele, uma recomendação de EC2 é sobre CPU e rede, e diz isso.
- **Outra família está no escopo.** Ele recomenda entre famílias, Graviton inclusive, que é onde está boa
  parte da economia: na oferta de EC2 de São Paulo uma `m7g.large` custa 0,1301 USD por hora e uma
  `m7i.large` 0,16065, cerca de 19% a mais pelo mesmo tamanho.

Uma recomendação é um conselho calculado do histórico. A mudança ainda é feita pela equipe, testada em
staging com a carga de um dia real, e implantada como qualquer outra mudança, pelas lições 1 a 3.
