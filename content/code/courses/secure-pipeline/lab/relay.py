"""A TCP relay: LISTEN_HOST LISTEN_PORT TARGET_HOST TARGET_PORT.

The lab's containers cannot reach the recording machine's loopback, where its
proxy listens; this carries their connections there. Only addresses in the
private ranges Docker uses are let in.
"""
import ipaddress
import socket
import sys
import threading

lh, lp, th, tp = sys.argv[1], int(sys.argv[2]), sys.argv[3], int(sys.argv[4])
private = ipaddress.ip_network("172.16.0.0/12")


def pipe(a, b):
    try:
        while data := a.recv(65536):
            b.sendall(data)
    except OSError:
        pass
    finally:
        for s in (a, b):
            try:
                s.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass


srv = socket.socket()
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind((lh, lp))
srv.listen(64)
while True:
    c, addr = srv.accept()
    if ipaddress.ip_address(addr[0]) not in private:
        c.close()
        continue
    u = socket.create_connection((th, tp))
    threading.Thread(target=pipe, args=(c, u), daemon=True).start()
    threading.Thread(target=pipe, args=(u, c), daemon=True).start()
