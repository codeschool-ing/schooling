---
title: Cisco Packet Tracer: uma simulação
version: 1
---

O Packet Tracer é o simulador de redes da própria Cisco, feito para o ensino. O download é gratuito na
Cisco Networking Academy depois que você cria uma conta lá, e ele roda em Windows, Linux e macOS. **Ele
não foi executado para esta aula**: precisa de um ambiente gráfico e de login, e nada nesta página é
saída dele.

Você monta a rede arrastando dispositivos para uma área de trabalho e ligando-os com cabos —
roteadores e switches Cisco, PCs e servidores genéricos, dispositivos sem fio — e depois os configura.
Clicar num roteador abre uma linha de comando que parece o IOS, o sistema operacional dos roteadores da
Cisco, e aceita comandos do IOS como `enable`, `configure terminal` e `show ip route`.

Essa aparência é o que é preciso entender sobre ele. **A linha de comando é uma imitação do IOS, escrita
para os cursos, e não o IOS.** O Packet Tracer implementa os comandos e protocolos que os cursos da
Cisco ensinam e para aí. Um comando que um roteador real aceita pode faltar, um padrão pode ser
diferente, e um protocolo pode estar modelado com menos detalhe que o real. Para quem está aprendendo
o que é uma VLAN ou uma rota estática, isso não custa nada. Para quem quer saber como um roteador
específico, numa versão específica de software, vai se comportar, a resposta não está ali.

O melhor recurso dele é um que equipamento real não oferece. Ao lado do modo normal, em tempo real, há
um **modo de simulação**, em que o tempo para: você avança os eventos um a um, vê cada pacote viajar
como um envelope de dispositivo em dispositivo e o abre para ver os cabeçalhos camada por camada. Um
pedido ARP inundando um switch, um quadro sendo marcado num tronco, um TTL acabando num roteador: cada
um vira uma imagem que você pode pausar e examinar. É parecido com os desenhos destas aulas, só que
interativo.

Onde ele serve:

- num primeiro curso de redes, principalmente um que segue o material da Cisco, como o CCNA;
- para praticar a forma da linha de comando do IOS antes de ter um dispositivo real para digitar;
- para ver a ordem dos eventos de um protocolo devagar o bastante para acompanhar.

Onde não serve: qualquer dispositivo que não seja da Cisco, qualquer recurso que os cursos não cobrem e
qualquer pergunta sobre o que um dispositivo real faz exatamente. Para isso, os emuladores da próxima
seção rodam o software de verdade.
