---
title: Escolhendo por operação, para a Quitanda
version: 1
---

A pergunta que o CAP deixa, "recusar ou arriscar estar errado?", é respondida pelo custo de cada erro, e
**o custo muda de um tipo de dado para outro**, mesmo dentro de uma loja.

| dado da Quitanda | se uma resposta velha ou conflitante é dada | se a requisição é recusada | escolha |
| --- | --- | --- | --- |
| a cesta de um cliente | um item que ele tirou reaparece por um minuto | ele não consegue comprar nada | disponibilidade: continuar respondendo, juntar depois |
| as descrições e fotos do catálogo | a foto de ontem | a página não carrega | disponibilidade |
| as unidades de café na prateleira, mostradas na página do produto | "restam 12" quando há 11 | nenhum número mostrado | disponibilidade, marcada como aproximada |
| tirar unidades do estoque no checkout | dois clientes compram o último pacote | o checkout espera ou falha | consistência |
| cobrar um cartão | uma cobrança aplicada duas vezes, ou perdida | o pagamento falha, e o cliente tenta de novo | consistência |
| o preço cobrado de um cliente | um preço que já tinha mudado | o checkout espera | consistência, no momento da venda |

Dois padrões se destacam. **Leituras que informam em geral podem estar velhas; escritas que efetivam em
geral não.** A página do produto pode dizer "restam 12" a partir de um standby um segundo atrasado, desde
que o checkout tire a unidade da cópia que decide. E **"recusar" muitas vezes custa menos do que parece**:
um pagamento que falhou é tentado de novo por uma pessoa que vê um erro, enquanto uma cobrança dupla é
achada semanas depois por uma pessoa lendo o extrato do banco.

O resto do curso se apoia nessas escolhas. A aula 9 é o que o cliente vê do lado disponível, e como evitar
que isso confunda. A aula 10 é a replicação e o particionamento por baixo. E a aula 14 mostra como um
checkout que atravessa vários serviços mantém honesto o lado consistente sem uma transação em que se
apoiar.

Quando terminar a aula, pare os servidores dela:

```sh
docker compose down -v
```
