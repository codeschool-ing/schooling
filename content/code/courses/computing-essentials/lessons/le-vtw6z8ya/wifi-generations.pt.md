---
title: As gerações, e o único ajuste de segurança que importa
version: 1
---

O Wi-Fi teve dois conjuntos de nomes por vinte anos: o de engenharia, `802.11` seguido de letras,
e mais nada. Em 2018 alguém finalmente deu números a eles.

| nome de engenharia | vendido como | banda | mais ou menos |
|---|---|---|---|
| `802.11n` | **Wi-Fi 4** | 2,4 e 5 GHz | até `450 Mb/s` |
| `802.11ac` | **Wi-Fi 5** | só 5 GHz | até `1,3 Gb/s` |
| `802.11ax` | **Wi-Fi 6** | 2,4 e 5 GHz | mais rápido, e bem melhor na multidão |
| `802.11ax` | **Wi-Fi 6E** | acrescenta 6 GHz | o mesmo, numa banda vazia |
| `802.11be` | **Wi-Fi 7** | as três | mais rápido de novo |

**O Wi-Fi 6 é o interessante e não pela velocidade máxima.** A mudança de verdade nele é como ele
lida com muitos aparelhos ao mesmo tempo: ele consegue falar com vários clientes na mesma fatia
de tempo em vez de estritamente um depois do outro. Uma casa com trinta coisas conectadas ganha
muito mais com isso do que com um número maior.

Eles são sempre retrocompatíveis. Uma impressora Wi-Fi 4 funciona num roteador Wi-Fi 7 e conecta
na velocidade do Wi-Fi 4.

## Segurança, num parágrafo e uma recomendação

| | o que é |
|---|---|
| **aberta** | sem criptografia. Tudo que alguém manda é legível por todos ao alcance |
| `WEP` | quebrado desde 2001. Estourado em minutos. Trate como aberta |
| `WPA` | superado, e fraco |
| `WPA2` | o piso sensato. Ainda serve com uma senha longa |
| `WPA3` | o atual. Resiste ao chute de senha fora de linha que o WPA2 permite |

**Ponha `WPA2/WPA3` e uma senha longa, e acabou.** Não há mais nenhum ajuste que valha, e há uma
coisa a não fazer: uma senha curta em WPA2 pode ser capturada uma vez e depois chutada fora de
linha na velocidade que a máquina do atacante der. Comprimento ganha de esperteza — quatro
palavras comuns ganham de `P@ssw0rd!` por uma margem enorme.

## Três coisas vendidas como segurança que não são

- **Esconder o nome da rede.** Uma rede escondida continua se anunciando toda vez que um aparelho
  seu procura por ela, e esses aparelhos passam a anunciar o nome dela em todo lugar aonde vão. É
  pior que inútil e quebra alguns clientes.
- **Filtrar endereços MAC.** Os endereços viajam sem criptografia, então qualquer um que observe
  vê um permitido e copia. Isso é uma fechadura com a chave escrita na porta.
- **Baixar a potência.** Reduz o alcance dos seus próprios aparelhos primeiro; a antena
  direcional de um atacante não é afetada.

## A rede de convidados, que é real

Uma rede de convidados põe as visitas numa conexão que chega à internet e **não ao resto dos seus
aparelhos**. Isso importa menos para pessoas e mais para **coisas**: uma televisão inteligente,
uma campainha, uma tomada que era barata e nunca mais vai ser atualizada.

Essas pertencem à rede de convidados, para sempre. Não porque você desconfia das visitas, mas
porque um eletrodoméstico com um sistema de quatro anos e sem jeito de corrigir é a coisa mais
provável da sua rede de ser tomada.
