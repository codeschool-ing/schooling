---
title: O que a homologação diz, e o que não diz
version: 1
---

A homologação é onde um release prova que é implantável antes de encontrar um cliente. Ela justifica o
custo quando pega o que nenhum estágio anterior pegaria, e engana quando uma equipe acredita que ela
pegou mais do que pegou.

## O que ela mostra

- **O deploy funciona**: o artefato desempacota, o processo sobe com uma configuração real, o smoke
  test passa. A porta digitada errado da aula 7 foi achada exatamente assim.
- **As integrações respondem**: a sandbox da transportadora aceita a requisição, uma mensagem chega à
  fila, a migração do banco roda.
- **O release se comporta de ponta a ponta**: os testes de aceitação da aula 1 rodam contra o programa
  implantado, pela interface real.
- **Pessoas conseguem olhar**: um dono de produto experimenta a tela nova antes dos clientes.

## O que ela raramente mostra

- **Carga.** A homologação recebe o tráfego da equipe, não o dos clientes. Uma consulta que leva 5 ms
  em mil linhas pode levar segundos em dez milhões.
- **Dados reais.** Dados semeados são arrumados. A produção guarda o CEP com um espaço no meio, o
  endereço de 300 caracteres e o pedido de 2019 num formato de que ninguém lembra. A aula 3 seção 11
  explicou por que a homologação não deveria guardar uma cópia disso.
- **As integrações reais.** Uma sandbox não é a API de verdade, como a seção 04 mostrou.
- **Tempo.** Um vazamento de memória que leva três dias para importar não aparece numa execução de uma
  hora na homologação.

## Então o que quer dizer uma homologação verde?

Quer dizer que **este release pode ser implantado e faz o que os testes dizem, em condições como as da
produção**. Não quer dizer que o release é seguro na escala da produção. Essa lacuna é o motivo de as
aulas 10 e 11 existirem: liberar primeiro para uma parte pequena do tráfego real, observar, e ter um
caminho rápido de volta. Equipes que entendem isso mantêm a homologação enxuta e barata, e gastam o
esforço em observar a produção e no rollback. Equipes que não entendem continuam acrescentando coisas à
homologação, tentando transformá-la na produção, e nunca chegam lá.

O repositório que publica este curso não tem homologação nenhuma, e o raciocínio é o mesmo, feito ao
contrário: para uma plataforma pequena, as verificações antes do release e um caminho de volta rápido e
ensaiado cobrem o que um ambiente de homologação cobriria.
