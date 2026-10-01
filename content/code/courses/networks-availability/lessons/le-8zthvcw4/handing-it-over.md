---
title: Handing the file over, and deleting it
version: 1
---

The server rarely has the tools to analyse a capture comfortably, and the person who will analyse it
is often somebody else. **The pcap file is the unit that travels**: taken on the server with
`tcpdump`, opened anywhere with Wireshark or `tshark`, byte for byte the same.

`tshark` happened to be installed on `web1`, so the analyst's first question could be asked in place:

```
ana@web1:~$ tshark -r web1.pcap -q -z http,tree

=======================================================================================================================================
HTTP/Packet Counter:
Topic / Item            Count         Average       Min Val       Max Val       Rate (ms)     Percent       Burst Rate    Burst Start  
---------------------------------------------------------------------------------------------------------------------------------------
Total HTTP Packets      8                                                       0.4302        100%          0.0800        0.000        
 HTTP Response Packets  4                                                       0.2151        50.00%        0.0400        0.000        
  2xx: Success          3                                                       0.1613        75.00%        0.0300        0.000        
   200 OK               3                                                       0.1613        100.00%       0.0300        0.000        
  4xx: Client Error     1                                                       0.0538        25.00%        0.0100        0.000        
   404 Not Found        1                                                       0.0538        100.00%       0.0100        0.000        
  ???: broken           0                                                       0.0000        0.00%         -             -            
  5xx: Server Error     0                                                       0.0000        0.00%         -             -            
  3xx: Redirection      0                                                       0.0000        0.00%         -             -            
  1xx: Informational    0                                                       0.0000        0.00%         -             -            
 HTTP Request Packets   4                                                       0.2151        50.00%        0.0400        0.000        
  GET                   4                                                       0.2151        100.00%       0.0400        0.000        
 Other HTTP Packets     0                                                       0.0000        0.00%         -             -            

---------------------------------------------------------------------------------------------------------------------------------------
```

Eight HTTP packets, four requests and four responses: three `200 OK` and one `404 Not Found`, the
same count the `grep` produced in the section before. **The statistics menu reads a file, so it
reads a file from anywhere**, and it needs no privilege to do it.

When the file does travel, it travels over something encrypted, `scp` or `sftp` from lesson 8 of
`networks`, and the receiver runs `capinfos` and compares the `SHA256` line with the one taken on the
server. None of that was run here.

## A capture is a copy of other people's data

**Everything that crossed the wire is in the file**, readable by anyone who can read the file. In
this lesson that was a test page. On a real server it is whatever the clients sent: form contents,
session cookies, e-mail addresses, anything a protocol without encryption carries. Capturing is
copying that data, and the obligations that come with personal data come with the file.

**Three habits keep it proportionate**, and none of them costs anything:

- Capture the least that answers the question: a capture filter for the one host and port, and a
  short snap length when only the headers matter.
- Keep it short: `-c`, or a ring of a few files, never a capture left running because nobody
  remembered to stop it.
- Delete it when the question is answered, on the server and on every copy, and say in the ticket
  that you did.

A capture file with mode `-rw-r--r--` in a home directory for six months is the opposite of all
three, and it is the default this lesson produced.
