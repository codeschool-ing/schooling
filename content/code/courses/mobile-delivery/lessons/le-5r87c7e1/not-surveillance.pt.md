---
title: Medição que não é vigilância
version: 1
---

**Medir o produto quer dizer contar o que as pessoas fazem com ele; vigilância quer dizer montar um
retrato da pessoa.** A linha entre as duas não é a tecnologia, que é a mesma, e sim o que é guardado,
a que está ligado e quem mais vê. O analytics do planner fica do lado certo dela por decisões tomadas
de antemão, e cada uma pode ser conferida no código da seção anterior.

## As decisões

- **Nenhum conteúdo.** O esquema permite números e escolhas fixas. O nome de um curso, uma anotação,
  o texto de uma busca: nada disso pode ser mandado, e o esquema recusa, como a simulação mostrou.
- **Nenhuma identidade.** O identificador da instalação é aleatório e mora no aparelho. Ele não é o id
  da conta, nem o e-mail, nem o identificador de publicidade. O rótulo da lição 5 chama isso de *Data
  Not Linked to You*, e isso só continua verdade enquanto nada liga os dois.
- **Nenhum terceiro que transforme isso em rastreamento.** A Apple define **rastreamento** como ligar
  dados do seu app a dados de apps ou sites de outras empresas para publicidade, ou compartilhá-los com
  um corretor de dados. Desde o iOS 14.5, um app que rastreia precisa pedir pelo **App Tracking
  Transparency**, e a maioria das pessoas diz não. O planner não rastreia, então nunca pergunta.
- **Guarda curta.** Linhas de evento mais antigas do que o funil e a retenção da lição 17 precisam
  são apagadas. Um ano de linhas individuais não responde nenhuma pergunta que uma semana de agregados
  não responda.
- **Agregados para ler.** As pessoas olham contagens e taxas, nunca a linha do tempo de uma
  instalação. Uma tela que mostra "a instalação i042 fez isto, depois isto, depois isto" é a
  ferramenta que transforma medição em vigiar, seja qual for o propósito dela.

## A lei, em resumo

No Brasil a **LGPD** vale para dados pessoais, e um identificador de instalação aleatório ligado a
comportamento pode ser dado pessoal por ela. Na União Europeia, o **RGPD** e as regras sobre guardar
identificadores num aparelho pedem consentimento para analytics em muitos casos. O desenho seguro é o
de cima, mais **perguntar**: uma chave de analytics nas configurações do planner, desligada por padrão
onde a lei espera isso, e a fila de eventos esvaziada quando ela é desligada. *Isto não é orientação
jurídica; é o desenho que deixa curta a conversa com o encarregado de dados.*

## O mesmo nas três plataformas

Toda regra acima é sobre o que o app manda, então é a mesma em Kotlin, Swift e React Native. O lugar
de impô-la é uma função, `track`, que toda tela chama e que guarda o esquema, em qualquer plataforma;
a próxima seção mostra os produtos que uma função dessas embrulha.
