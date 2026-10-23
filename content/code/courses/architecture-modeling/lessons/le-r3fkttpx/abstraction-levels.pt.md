---
title: Quatro níveis, perguntados em ordem
version: 1
---

**Os níveis de abstração do IAF separam os motivos de uma mudança dos seus requisitos, do seu desenho
e da sua realização, e exigem que sejam resolvidos nessa ordem.** Cada nível responde a uma pergunta,
e cada resposta é a entrada do nível seguinte.

| nível | a pergunta | o que ele produz |
| --- | --- | --- |
| **contextual** | *por quê?* | os direcionadores, os objetivos, os princípios e o escopo da mudança |
| **conceitual** | *o quê?* | os requisitos: os serviços e a informação necessários, sem depender de como são fornecidos |
| **lógico** | *como?* | um desenho de solução em componentes lógicos, sem depender de produtos |
| **físico** | *com o quê?* | os produtos, as plataformas e os padrões reais que implementam o desenho lógico |

## O embarque digital da Carcará, descendo uma coluna

Pegue a área de sistemas de informação e desça os quatro níveis para o programa da aula 8:

1. **Contextual, por quê.** O objetivo da diretoria: todo passageiro embarca com passagem digital até
   o fim de 2027. O princípio *o embarque funciona sem rede*. A restrição *o Frota fica*.
2. **Conceitual, o quê.** Um serviço de validação de passagens que responde em até um segundo, com
   rede ou sem; um serviço de emissão de passagens para os balcões; uma lista de passagens por viagem
   disponível antes da partida. Nenhum produto tem nome.
3. **Lógico, como.** Um componente de validação no aparelho do motorista, com uma lista por viagem; um
   componente de sincronização que publica as listas e recolhe as leituras; o ticketing como único
   emissor de passagens, com um canal de balcão. Ainda nenhum produto.
4. **Físico, com o quê.** O app de embarque em celulares Android com SQLite; o serviço de
   sincronização do embarque em Go, na região de nuvem que já existe; o modo balcão do app web do
   passageiro em tablets nas rodoviárias.

Cada elemento de um nível mais baixo responde a um de cima. **O store em SQLite existe por causa do
componente lógico de validação, que existe por causa do serviço conceitual, que existe por causa do
princípio e do objetivo.** Tire o objetivo e a coluna inteira pode ser questionada; troque o produto e
nada acima dele se mexe.

## O lógico é o nível que as pessoas pulam

A tentação é ir direto do *o quê* para o *com o quê*: de *precisamos de validação off-line* para
*SQLite no Android*. O nível lógico parece um passo redundante. Ele se paga em duas situações:

- **quando há mais de uma opção física**: os motoristas da Carcará têm celulares Android hoje, e o
  desenho lógico é o que continua verdadeiro se os celulares forem trocados por validadores portáteis
  em 2028;
- **quando o mesmo desenho lógico é implementado em vários lugares**: o modo balcão e o app do
  passageiro são duas realizações físicas de um mesmo canal lógico de emissão.

É a mesma distinção dos blocos de construção de arquitetura e de solução da aula 8. **Lógico é o
quê; físico é qual produto.** Um framework que dá nome à fronteira torna mais difícil atravessá-la sem
perceber.
