---
title: Tipos de controle
version: 1
---

As camadas dizem **onde** um controle fica. Duas outras classificações dizem **o que ele faz** e **de
que ele é feito**, e uma defesa que usa um tipo só é mais fina do que o número de camadas sugere.

### Pelo que faz

| função | o que faz | na livraria |
|---|---|---|
| **preventivo** | impede o incidente de acontecer | uma senha no portal, uma regra de firewall |
| **detectivo** | percebe que está acontecendo ou que aconteceu | o log do portal, um alerta de falhas repetidas |
| **corretivo** | limita o dano e restaura o normal | restaurar do backup, revogar uma senha vazada |
| **dissuasório** | desencoraja a tentativa | um aviso na tela de login, uma câmera visível |
| **compensatório** | faz as vezes de um controle que não dá para usar | log extra num sistema antigo que não aceita MFA |

Iniciantes projetam quase só com a primeira linha. **Só prevenção pressupõe que ela nunca falha**, o
que a seção 02 desta aula disse ser falso. Uma defesa sem controles detectivos falha em silêncio: o
atacante que passou pela senha nunca é notado. Uma defesa sem controles corretivos percebe e não
consegue se recuperar. O portal da loja tem um controle preventivo (o login), um detectivo (o log,
que a próxima seção mostra) e um corretivo (trocar uma senha vazada); tire qualquer um dos três e o
buraco fica evidente.

### Pelo que é feito

| natureza | também chamado | exemplos |
|---|---|---|
| **administrativo** | gerencial, procedimental | políticas, treinamento, checagem de antecedentes, o registro de riscos |
| **técnico** | lógico | senhas, criptografia, firewalls, permissões de arquivo |
| **físico** | | fechaduras, crachás, vigias, supressão de incêndio |

As duas tabelas se cruzam. Um livro de visitas é um controle físico e detectivo; uma política de uso
aceitável é administrativa e dissuasória; cifrar o disco é técnico e preventivo. Dispor os controles
da loja numa grade de função contra natureza é um jeito rápido de achar uma coluna ou linha inteira
vazia, que é de onde costuma vir o próximo incidente.

**Um controle compensatório merece uma palavra.** Às vezes o controle certo não dá para aplicar: uma
máquina antiga roda um software que não aceita MFA, e trocá-la é coisa para daqui a um ano. A
resposta não é desistir do risco, e sim acrescentar algo que cubra a mesma fraqueza de outro jeito,
como restringir quem alcança a máquina e vigiar de perto os logins dela. A compensação é escrita no
registro de riscos com o motivo e uma data, exatamente como seria uma aceitação, porque é um arranjo
temporário, e não um projeto.
