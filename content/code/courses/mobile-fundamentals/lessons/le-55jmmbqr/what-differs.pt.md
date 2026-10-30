---
title: O que é de fato diferente, e o que só parece diferente
version: 1
---

**Quase tudo o que separa um app Android de um app iOS é convenção, e algumas poucas coisas são
restrições reais.** Separar uma coisa da outra cedo poupa muita discussão depois, porque uma
convenção pode ser seguida ou quebrada por quem desenha, e uma restrição é imposta pelo sistema, não
importa o que alguém decida.

## As diferenças reais

- **Voltar.** Todo celular Android tem uma ação de *voltar* do sistema, um gesto a partir da borda da
  tela ou um botão, e o app precisa responder a ela. Um iPhone não tem: voltar é um botão que o app
  desenha, ou um deslizar que a navegação oferece. A aula 10 trata do que isso faz com as telas de um
  app.
- **Quanto o sistema deixa um app rodar em segundo plano.** Os dois param um app que não está na
  tela, e o iOS é mais rígido: lá o app recebe alguns tipos nomeados de trabalho em segundo plano e
  nada além disso. O Android permite mais, com regras que apertaram em quase toda versão. A aula 15
  compara os dois.
- **Distribuição.** Um app Android pode ser instalado a partir de um arquivo, e testar no celular de
  um amigo vira questão de mandar o arquivo para ele. Um iPhone só roda apps assinados por meio da
  Apple, e quem testa recebe o app pelo TestFlight, da Apple. A aula 20 mostra o que cada loja pede.
- **Revisão.** Todo app e toda atualização passam pela revisão da Apple antes de chegar à App Store,
  e o Google também revisa os apps do Play. Os dois rejeitam, por motivos diferentes e com
  velocidades diferentes.

## As convenções

No iOS as abas ficam numa barra na parte de baixo da tela; o Material Design oferece abas no topo e
também uma barra de navegação embaixo. O Material desenha um botão flutuante para a ação principal, e
o iOS põe essa ação na barra de navegação, no topo. Listas, chaves e diálogos têm outra cara. **Isso
são os guias de design das duas empresas**, o Material Design e as Human Interface Guidelines, e a
aula 18 lê os dois lado a lado. O usuário percebe quando um app os ignora, e um app ainda pode
ignorá-los e funcionar.

## E o que é igual

Esta é a parte de que trata o curso inteiro. Nas duas plataformas:

- o **sistema é dono do ciclo de vida do app**: ele inicia, pausa e mata o processo quando decide
  (aulas 4 e 5);
- a **tela** é pequena, muda de forma quando o celular gira e tem recortes e barras (aulas 7 a 9);
- **permissões** são pedidas ao usuário, num momento que o app escolhe, e podem ser recusadas de vez
  (aula 12);
- a **rede** vai e volta, e uma requisição pode simplesmente nunca voltar (aula 14);
- a **bateria** é do usuário, e o sistema garante isso (aula 15);
- todo app vive numa **caixa de areia**, com um armazenamento que mais ninguém lê (aula 16).

Essas regras valem qualquer que seja a plataforma, a linguagem e o kit que você escolher depois da
bifurcação. É por isso que este curso vem primeiro e não precisa de celular para ensiná-las.
