---
title: The unbuffered channel is a meeting
version: 1
---

Every channel in lesson 3 except one was made with `make(chan T)` and nothing else. That makes an
**unbuffered** channel: it has no room to keep a value in, not even one. The usual first guess is
that a send drops the value off and moves on, like posting a letter. **On an unbuffered channel a
send cannot complete until a receiver takes the value, and a receive cannot complete until a sender
offers one.** The two goroutines meet, the value crosses, and both carry on. That meeting is called
a rendezvous.

To watch one, a program has to print the time at each step. This one makes the receiver arrive
300 milliseconds late, saved as `meet.go`:

```schooling-example
{"language": "go", "file": "meet.go", "parts": [{"code": "// Command meet shows a send on an unbuffered channel waiting for its receiver.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"time\"\n)\n\nvar start = time.Now()\n\nfunc stamp(what string) {\n\tfmt.Printf(\"%4dms  %s\\n\", time.Since(start).Round(10*time.Millisecond).Milliseconds(), what)\n}\n\n", "note": "`stamp` prints how long after the start each step happened, rounded to ten milliseconds so the noise of a busy machine does not hide the shape."}, {"code": "func main() {\n\tch := make(chan string)\n\tdone := make(chan struct{})\n\n", "note": "**No size after the type, so no buffer.** `done` is a second channel used only to wait for the sender to finish; nothing is ever sent on it, it is closed."}, {"code": "\tgo func() {\n\t\tstamp(\"sender: about to send\")\n\t\tch <- \"ping\"\n\t\tstamp(\"sender: the send returned\")\n\t\tclose(done)\n\t}()\n\n", "note": "The sender goes straight to its send. **The line after the send prints only once the value has been taken**, so its time says when that was."}, {"code": "\ttime.Sleep(300 * time.Millisecond)\n\tstamp(\"receiver: about to receive\")\n\tv := <-ch\n\tstamp(\"receiver: got \" + v)\n\t<-done\n}\n", "note": "`main` is the receiver, and it dawdles for 300 milliseconds first. The final `<-done` waits until the sender has printed its last line, for the reason lesson 2 gave: `main` returning ends everything."}]}
```

```
ana@vm:~/buffers$ go run meet.go
   0ms  sender: about to send
 300ms  receiver: about to receive
 300ms  receiver: got ping
 300ms  sender: the send returned
```

The sender reached its send at 0 milliseconds and **the send did not return until 300**, the moment
the receiver arrived. For those 300 milliseconds the sending goroutine did nothing at all; it was
parked by the scheduler, using no processor, exactly like a goroutine in `time.Sleep`. Then the
value crossed and both went on.

Look at the last two lines. The receiver printed `got ping` before the sender printed that its send
had returned, and both say 300ms. **After a rendezvous the two goroutines are independent again**,
and which one reaches its next `Println` first is up to the scheduler; on another run the two lines
can swap. What is promised is narrower and more useful: nothing after the send in the sender, and
nothing after the receive in the receiver, happens before the value has crossed.

That is why an unbuffered channel synchronises as well as carries. **When a send on it returns, the
sender knows the receiver has the value**, not merely that it was posted somewhere. Programs use
that knowledge on purpose: a goroutine that sends "I am done" on an unbuffered channel knows, when
the send returns, that somebody heard it.
