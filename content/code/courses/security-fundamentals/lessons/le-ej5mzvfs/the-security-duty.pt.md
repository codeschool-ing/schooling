---
title: O dever de proteger, e de comunicar
version: 1
---

A LGPD transforma boa parte deste curso em obrigação legal, em alguns artigos que vale saber pelo número.

**Artigo 46**: controladores e operadores devem adotar **medidas de segurança, técnicas e
administrativas**, aptas a proteger os dados pessoais de acessos não autorizados e de situações acidentais
ou ilícitas de destruição, perda, alteração, comunicação ou qualquer forma de tratamento inadequado ou
ilícito. Ele não lista controles. Ele enuncia a tríade da aula 1 em linguagem jurídica (acesso não
autorizado é confidencialidade, alteração é integridade, destruição e perda são disponibilidade) e deixa o
como para a organização, como o NIST CSF faz com os resultados.

O **artigo 46**, parágrafo 2º, acrescenta que essas medidas devem ser observadas **desde a fase de
concepção** do produto ou serviço até a sua execução: privacidade e segurança desde o projeto.

**Artigo 49**: os sistemas usados no tratamento de dados pessoais devem ser estruturados para atender aos
requisitos de segurança, aos padrões de boas práticas e governança e aos princípios da lei.

### Quando algo dá errado: o artigo 48

O **artigo 48** exige que o controlador comunique à **ANPD** e aos **titulares afetados** a ocorrência de
**incidente de segurança que possa acarretar risco ou dano relevante** a eles. O regulamento da ANPD sobre
comunicação de incidentes, a **Resolução CD/ANPD nº 15 de 2024**, define o prazo: **três dias úteis** a
partir de quando o controlador fica sabendo que o incidente afetou dados pessoais.

| | o que quer dizer na prática |
|---|---|
| **o que dispara** | um incidente com dados pessoais que possa causar risco ou dano relevante: dados sensíveis, dados de crianças, dados financeiros, dados que permitem fraude de identidade, grandes volumes, e assim por diante |
| **quem é avisado** | a ANPD, pelo formulário dela, e as pessoas afetadas, em linguagem clara |
| **o que se diz** | o que aconteceu, quais dados, quantas pessoas, os riscos, as medidas tomadas e previstas |
| **o que se guarda** | um registro de todo incidente com dados pessoais, inclusive os não comunicados, com o raciocínio |

A última linha importa tanto quanto o prazo. **Todo incidente é registrado**, e a decisão de não comunicar
um também é documentada, porque a ANPD pode perguntar por quê. É a aceitação de risco da aula 3 em outra
forma: uma decisão com um motivo e um nome.

Três dias úteis é pouco. Só dá para cumprir se a organização já sabe que dados pessoais guarda e onde (o
inventário da aula 16), consegue dizer o que um incidente atingiu (os logs das aulas 10 e 11), e decidiu de
antemão quem decide e quem escreve a comunicação (o exercício de mesa da aula 10). A aula 21 de
`soc-response` trata em detalhe da comunicação de incidentes pela LGPD.

### As sanções

O **artigo 52** lista as sanções administrativas que a ANPD pode aplicar, depois de um processo com direito
de defesa. Entre elas:

- **advertência**, com prazo para medidas corretivas;
- **multa simples de até 2% do faturamento** da empresa, grupo ou conglomerado no Brasil no último
  exercício, **limitada a R$ 50 milhões por infração**;
- **multa diária**, com o mesmo limite;
- **publicização** da infração depois de confirmada;
- **bloqueio** ou **eliminação** dos dados pessoais envolvidos;
- suspensão parcial do banco de dados, ou da atividade de tratamento, ou proibição de atividades
  relacionadas a tratamento.

Para uma loja pequena, a multa raramente é o maior custo. Publicizar a infração e perder a confiança dos
clientes é o impacto reputacional da aula 2, e uma ordem de eliminar o banco de clientes pararia o
negócio. A proteção mais barata contra tudo isso é a mesma que contra os incidentes em si.
