---
title: A lei, e os dados que a própria DLP coleta
version: 1
---

**No Brasil, o motivo para saber onde estão os dados pessoais é uma lei, a LGPD** (Lei Geral de
Proteção de Dados, Lei 13.709 de 2018), e a autoridade que a fiscaliza é a ANPD. Dois dos princípios
dela mudam para que serve um projeto de DLP.

**Necessidade**: um escritório só pode guardar os dados pessoais de que a sua finalidade precisa.
Isso transforma o scanner desta aula de guarda em pergunta. Vinte cartões de clientes numa planilha
numa estação de trabalho são um achado antes de alguém tentar mandá-los para qualquer lugar: por que
um escritório de contabilidade guarda números de cartão num arquivo? Os dados mais baratos de
proteger são os apagados no dia em que ninguém mais precisou deles, que é o argumento da aula 1 sobre
serviços, aplicado a registros.

**Segurança**: o escritório deve adotar medidas técnicas e administrativas para proteger os dados de
acessos não autorizados e de perda acidental ou ilícita. A DLP é uma dessas medidas, e a lei também
exige que um incidente de segurança que possa acarretar risco ou dano relevante aos titulares seja
comunicado à ANPD e a eles. Saber que arquivos guardavam o quê é como um escritório responde à
primeira pergunta que a autoridade faz depois que um notebook some: de quem eram os dados que
estavam nele.

## Vigiar a equipe é tratar os dados dela

**Uma ferramenta de DLP lê o que os funcionários enviam.** Os logs dela dizem quem copiou que
arquivo, quando e para onde, e esse registro é dado pessoal sobre os funcionários, pela mesma lei.
Isso não torna a DLP ilegal; torna-a algo com regras próprias:

- **Avise as pessoas.** Um monitoramento de que a equipe não sabe é difícil de justificar por
  qualquer princípio da lei, e perde também o principal efeito da DLP, que é o de que pessoas que
  sabem que uma regra existe param de cometer o engano.
- **Seja proporcional.** O guarda desta aula lê uma pasta e guarda uma contagem e um exemplo
  mascarado. Uma ferramenta que guardasse uma cópia de cada arquivo que cada funcionário enviou teria
  uma segunda cópia de tudo o que o escritório quer proteger, e todo o e-mail pessoal deles de quebra.
- **Limite quem lê os logs, e por quanto tempo são guardados.** Um log de DLP é uma lista dos
  arquivos mais sensíveis do escritório e de quem os tocou, o que faz dele um dos arquivos que mais
  valem proteção.

Nada disto é aconselhamento jurídico, e o texto da lei e as orientações da ANPD são onde uma
implantação de verdade começa. O que a aula consegue mostrar é o lado de engenharia da mesma ideia, e
já mostrou: o scanner conta e mascara, o guarda retém em vez de apagar, e a regra de rede conhece
destinos e não conteúdos. Cada um é o mínimo de que o trabalho precisa.
