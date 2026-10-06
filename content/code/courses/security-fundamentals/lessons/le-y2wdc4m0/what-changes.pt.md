---
title: O que muda, e o que não muda
version: 1
---

Adotar Zero Trust não é um projeto que termina. É uma direção em que a organização anda, recurso por
recurso, e as mudanças que ele traz ficam mais fáceis de ver como antes e depois:

| | confiança pela localização | Zero Trust |
|---|---|---|
| o que decide o acesso | a rede de onde o pedido vem | identidade, dispositivo e contexto, por pedido |
| o perímetro | o controle principal | uma camada entre várias |
| trabalho remoto | uma VPN para dentro da rede confiável | o mesmo caminho de acesso que do escritório |
| um notebook comprometido lá dentro | herda a confiança da rede | recebe o que a identidade do usuário permite, daquele aparelho, se o aparelho passar |
| tráfego interno | muitas vezes sem cifra | cifrado, como o externo |
| logs | qual endereço fez o quê | qual identidade, em qual aparelho, fez o quê |

### A identidade vira o perímetro

Quando a localização deixa de decidir, quem decide é a identidade, o que faz dela a parte mais atacada
do sistema. É por isso que todo projeto sério de Zero Trust começa com autenticação forte, MFA para
todo mundo (aula 9) e um processo limpo para criar e remover contas (as entradas, mudanças e saídas da
aula 6). Uma arquitetura Zero Trust com senhas fracas mudou a muralha do castelo para a porta da frente
e deixou a porta destrancada.

### Microssegmentação

A aula 5 terminou com a microssegmentação: cada carga de trabalho com a própria fronteira. Ela é a
metade de rede do Zero Trust. Enquanto o PEP na frente de uma aplicação confere quem pede, a
microssegmentação garante que mesmo um servidor comprometido só abra as conexões que o trabalho dele
exige, então o princípio de presumir a invasão tem algo que o aplique também no nível da rede.

### Não é um produto

Fornecedores vendem "Zero Trust" como uma caixa, e nenhuma caixa o entrega. Os princípios descrevem
como as decisões são tomadas, e um produto pode ajudar a tomar algumas: um provedor de identidade, um
gateway que funciona como PEP, um serviço de gestão de dispositivos. **Comprar os três e deixar a velha
rede plana confiável por baixo deles não consegue nada.** O teste de uma mudança Zero Trust é o do
laboratório: rode o mesmo pedido de dentro e de fora, e confira que a resposta depende de quem pede.

Uma ordem sensata para uma organização como a loja: autenticação forte e MFA em tudo primeiro; depois
pôr a aplicação mais sensível, a folha de pagamento, atrás de uma decisão que confira identidade e
aparelho; depois o resto, um recurso de cada vez. As aulas 20 e 21 de `networks-security` aprofundam o
lado de rede para quem está numa trilha que o inclui, e a aula 6 de `cloud-security`, o lado de
identidade na nuvem.
