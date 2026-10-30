"""Lesson 17: routes, Cloud NAT and Private Google Access."""
from figures import Fig, T, figure


@figure('l17-ways-out', 17)
def ways_out():
    f = Fig('l17-ways-out', 720, 280, T(
        'A machine in the São Paulo subnet with only an internal address, 10.10.0.5. All its traffic out '
        'leaves by the default internet gateway route. Towards the internet, it passes through Cloud NAT, '
        'configured on a Cloud Router in the region, which lets the machine start connections and gives '
        'the replies back. Towards Google\'s APIs, such as Cloud Storage, Private Google Access on the '
        'subnet lets it through without NAT. A connection started from the internet towards the machine '
        'is drawn crossed out: there is no path in.',
        'Uma máquina na sub-rede de São Paulo só com endereço interno, 10.10.0.5. Todo o tráfego de saída '
        'dela sai pela rota do gateway padrão de internet. Para a internet, passa pelo Cloud NAT, '
        'configurado num Cloud Router na região, que deixa a máquina iniciar conexões e devolve as '
        'respostas. Para as APIs do Google, como o Cloud Storage, o Private Google Access na sub-rede a '
        'deixa passar sem NAT. Uma conexão iniciada da internet para a máquina está desenhada riscada: não '
        'há caminho de entrada.'))
    f.rect(20, 40, 230, 190, stroke='--phosphor', fill='--ink', width=1.4)
    f.text(135, 58, 'planner-sao-paulo', size=10, mono=True)
    f.text(135, 74, T('Private Google Access: on', 'Private Google Access: ligado'), size=9, fill='--paper-dim')
    f.rect(55, 110, 160, 56, stroke='--wire', fill='--panel', width=1.2)
    f.text(135, 130, T('a machine', 'uma máquina'), size=10)
    f.text(135, 148, '10.10.0.5', size=9.5, mono=True, fill='--paper-dim')
    f.text(135, 210, T('no external address', 'sem endereço externo'), size=9, fill='--paper-dim')
    f.rect(320, 40, 150, 60, stroke='--amber', fill='--panel', width=1.4)
    f.text(395, 62, 'Cloud NAT', size=10.5)
    f.text(395, 80, T('on a Cloud Router', 'num Cloud Router'), size=9, fill='--paper-dim')
    f.rect(540, 40, 160, 60, stroke='--wire', fill='--panel', width=1.2)
    f.text(620, 70, T('the internet', 'a internet'), size=10.5)
    f.rect(540, 150, 160, 60, stroke='--phosphor', fill='--panel', width=1.4)
    f.text(620, 172, T("Google's APIs", 'APIs do Google'), size=10.5)
    f.text(620, 190, 'storage.googleapis.com', size=8.5, mono=True, fill='--paper-dim')
    f.arrow([(252, 112), (316, 74)], stroke='--amber', width=1.6)
    f.arrow([(472, 70), (536, 70)], stroke='--amber', width=1.6)
    f.text(505, 118, T('out, and replies back', 'saída, e respostas'), size=9, fill='--amber')
    f.arrow([(252, 160), (536, 180)], stroke='--phosphor', width=1.6)
    f.text(380, 182, T('no NAT needed', 'sem NAT'), size=9, fill='--phosphor')
    f.path('M620 102 L620 112', stroke='--paper-dim')
    f.text(620, 130, T('in: no path', 'entrada: nenhum caminho'), size=9.5, fill='--paper-dim')
    f.text(360, 262, T('every way out leaves by the default internet gateway route',
                       'toda saída sai pela rota do gateway padrão de internet'), size=10)
    return f, T('NAT for the internet, Private Google Access for Google; nothing comes in.',
                'NAT para a internet, Private Google Access para o Google; nada entra.')
