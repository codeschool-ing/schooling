---
title: Escolhendo, uma operação de cada vez
version: 1
---

A aula vem defendendo uma coisa por várias direções: **consistência e disponibilidade são escolhidas
por operação, não por sistema**. A bilheteria já faz escolhas diferentes para os seus dois pedidos,
e um sistema de ingressos de verdade tem mais uma dúzia. Para cada um, a pergunta útil é a que a
seção 04 deixou: o que dá errado se esta resposta estiver desatualizada, ou se esta escrita cair dos
dois lados de uma partição?

| operação | se desatualizada, ou escrita dos dois lados | escolha | como, neste curso |
|---|---|---|---|
| vender um lugar | um lugar vendido duas vezes | **consistente**: recusar durante uma partição | um primário, a venda numa transação (aula 1), réplica síncrona se nenhuma venda pode se perder |
| mostrar a página de um show | uma contagem de alguns segundos atrás | **disponível** | réplica assíncrona (aula 2) |
| o ingresso do próprio comprador | "seu ingresso não existe" | ler as próprias escritas | primário para esse usuário, ou esperar o LSN (aula 2) |
| pôr no carrinho | um item perdido | **disponível, com junção** | um conjunto juntado por união (seção 09) |
| contar visitas a uma página | uma contagem um pouco baixa | **disponível** | um G-counter, ou só um número aproximado |
| o nome de exibição de um comprador | a mais velha de duas edições mantida | **disponível, a última escrita vence** | LWW, sabendo o que se faz |

Três hábitos tornam a tabela usável num sistema seu:

- **Comece pelo que uma resposta desatualizada custa a uma pessoa**, não pelo que o banco oferece.
  Um custo de "uma ligação para o suporte" e um custo de "dinheiro cobrado por um lugar que não
  existe" são linhas diferentes.
- **Procure invariantes.** "No máximo a capacidade de lugares", "um saldo nunca abaixo de zero", "uma
  conta por e-mail". Toda invariante precisa de coordenação no momento da escrita, e é onde a
  consistência não se negocia.
- **Espere misturar.** A venda da bilheteria é consistente e a página dela é disponível, sobre os
  mesmos dados, no mesmo programa. Isso é normal, e é a forma que a maioria dos sistemas de verdade
  acaba tendo.

As aulas 4 e 5 encontram bancos construídos em torno dessas escolhas: alguns consistentes por padrão,
alguns disponíveis por padrão, vários deixando cada consulta decidir. O vocabulário desta aula é como
ler a documentação deles, que descreve a mesma troca com as próprias palavras.
