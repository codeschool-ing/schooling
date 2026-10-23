"""Lesson 4: access control by MAC and by NAC."""
from figures import Fig, T, figure


@figure('l04-three-parties', 4)
def three_parties():
    f = Fig('l04-three-parties', 720, 280, T(
        'The three parties of 802.1X. On the left the supplicant, desk, running wpa_supplicant. In '
        'the middle the authenticator, the switch port port-desk, with two paths through it: one '
        'that carries only EAPOL frames and is always open, and one for all other traffic that stays '
        'closed until the login succeeds. On the right the authentication server, normally RADIUS. '
        'EAP travels in EAPOL between desk and the port, and inside RADIUS between the port and the '
        'server. The server answers accept or reject, and only then does the port open.',
        'As três partes do 802.1X. À esquerda o suplicante, o desk, rodando wpa_supplicant. No meio o '
        'autenticador, a porta port-desk do switch, com dois caminhos: um que só leva quadros EAPOL e '
        'está sempre aberto, e um para todo o resto do tráfego, que fica fechado até o login dar '
        'certo. À direita o servidor de autenticação, normalmente RADIUS. O EAP vai em EAPOL entre o '
        'desk e a porta, e dentro de RADIUS entre a porta e o servidor. O servidor responde aceita '
        'ou recusa, e só então a porta abre.'))
    f.rect(20, 80, 150, 90, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(95, 102, T('supplicant', 'suplicante'), size=11, weight='600')
    f.text(95, 124, 'desk', size=10.5, mono=True)
    f.text(95, 144, 'wpa_supplicant', size=9.5, mono=True, fill='--paper-dim')
    f.rect(280, 50, 170, 170, stroke='--phosphor', fill='--panel', width=1.5, rx=3)
    f.text(365, 70, T('authenticator', 'autenticador'), size=11, weight='600')
    f.text(365, 90, 'port-desk', size=10.5, mono=True)
    f.rect(295, 110, 140, 30, stroke='--phosphor', fill='--scan', width=1.2, rx=2)
    f.text(365, 125, T('EAPOL: always open', 'EAPOL: sempre aberto'), size=9.5)
    f.rect(295, 160, 140, 30, stroke='--amber', fill='--scan', width=1.2, rx=2, dash='5 3')
    f.text(365, 175, T('the rest: closed', 'o resto: fechado'), size=9.5, fill='--amber')
    f.text(365, 207, T('until the server accepts', 'até o servidor aceitar'), size=9.5, fill='--paper-dim')
    f.rect(560, 80, 140, 90, stroke='--wire', fill='--panel', width=1.5, rx=3)
    f.text(630, 102, T('authentication', 'servidor de'), size=11, weight='600')
    f.text(630, 120, T('server', 'autenticação'), size=11, weight='600')
    f.text(630, 144, 'RADIUS', size=10, mono=True, fill='--paper-dim')
    f.line(170, 120, 295, 125, stroke='--phosphor', width=1.4, arrow=True, start=True)
    f.text(232, 108, T('EAP in EAPOL', 'EAP em EAPOL'), size=9.5, fill='--phosphor')
    f.line(450, 120, 560, 120, stroke='--paper-dim', width=1.4, arrow=True, start=True)
    f.text(505, 108, T('EAP in RADIUS', 'EAP em RADIUS'), size=9.5, fill='--paper-dim')
    f.text(630, 192, T('accept or reject', 'aceita ou recusa'), size=9.5, fill='--paper-dim')
    f.text(360, 258, T('in the lab, hostapd plays both the port and the server', 'no laboratório, o hostapd faz o papel da porta e do servidor'),
           size=10, fill='--paper-dim')
    return f, T('The port carries the login and nothing else until the server says yes.',
                'A porta leva o login e mais nada até o servidor dizer sim.')


@figure('l04-assertion', 4)
def assertion():
    f = Fig('l04-assertion', 720, 250, T(
        'Why a MAC filter believes whatever it is told. Two frames arrive at port-desk. The first comes '
        'from the reception printer and carries its address, 52:54:00:a8:3c:63. The second comes from '
        'desk after desk set its own card to the same address. The port compares the source address '
        'with its list, finds it in both cases and lets both through: the address is written by the '
        'device that sends the frame.',
        'Por que um filtro de MAC acredita no que lhe dizem. Dois quadros chegam à port-desk. O '
        'primeiro vem da impressora da recepção e traz o endereço dela, 52:54:00:a8:3c:63. O segundo '
        'vem do desk depois que o desk pôs a própria placa no mesmo endereço. A porta compara o '
        'endereço de origem com a lista, acha nos dois casos e deixa os dois passarem: o endereço é '
        'escrito pelo dispositivo que envia o quadro.'))
    for y, who, note in [(40, T('the printer', 'a impressora'), T('its own address', 'o próprio endereço')),
                         (140, 'desk', T('address set by its owner', 'endereço posto pelo dono'))]:
        f.rect(20, y, 160, 70, stroke='--wire', fill='--panel', width=1.5, rx=3)
        f.text(100, y + 22, who, size=11, weight='600')
        f.text(100, y + 46, note, size=9.5, fill='--paper-dim')
        f.rect(220, y + 15, 210, 40, stroke='--wire', fill='--scan', width=1.2, rx=2)
        f.text(232, y + 29, T('source', 'origem'), size=9.5, anchor='start', fill='--paper-dim')
        f.text(232, y + 44, '52:54:00:a8:3c:63', size=10, anchor='start', mono=True)
        f.line(180, y + 35, 220, y + 35, stroke='--paper-dim', width=1.2, arrow=True)
        f.line(430, y + 35, 490, 125, stroke='--paper-dim', width=1.2, arrow=True)
    f.rect(490, 85, 210, 80, stroke='--phosphor', fill='--panel', width=1.5, rx=3)
    f.text(595, 105, 'port-desk', size=11, mono=True, weight='600')
    f.text(595, 127, T('is the source on the list?', 'a origem está na lista?'), size=9.5)
    f.text(595, 149, T('yes, both times', 'sim, das duas vezes'), size=10, weight='600', fill='--amber')
    return f, T('The filter checks a value the device writes itself.',
                'O filtro confere um valor que o próprio dispositivo escreve.')
