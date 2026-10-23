---
title: BPEL, the language that ran processes before BPMN could
version: 1
---

Before BPMN 2.0 gave its diagrams a meaning an engine could execute, the language for running a
process was a different one: **WS-BPEL, the Web Services Business Process Execution Language**. If
you work in a company with an integration estate from the 2000s you will meet it, usually inside an
ESB product, usually running a process nobody has opened in years. It is worth knowing what it was,
because the reasons it faded are the same reasons a process model and the code that runs it still
drift apart today.

The common belief is that BPEL was simply BPMN's XML format. **It was a separate language with a
separate model of the world: a process was a web service that calls other web services, and nothing
else.** BPMN was a notation for people that later learned to run; BPEL was a programming language
for machines that people were expected to draw pictures of.

## Where it came from

IBM and Microsoft each had a language for composing web services, IBM's WSFL and Microsoft's XLANG.
In 2002 they merged the two into BPEL4WS, joined by BEA, and version 1.1 followed in 2003 with SAP
and Siebel among the authors. The specification moved to OASIS, which published **WS-BPEL 2.0 as an
OASIS Standard in 2007**. Oracle's BPEL Process Manager, part of its SOA Suite, and IBM's WebSphere
Process Server were among the engines that ran it, and both were the kind of product that came
alongside an enterprise service bus.

## What a BPEL process looks like

A BPEL process is an XML document, and every interaction in it is a web service operation described
in WSDL, the interface language of SOAP services that lesson 8 opens up. The process declares its
**partner links**, the services it talks to and the role it plays with each; its **variables**,
which are WSDL messages; and then its activities. Here is the start of onboarding as BPEL would have
expressed it, for reading:

```xml
<process name="FarmOnboarding"
         targetNamespace="http://serraalta.example/bpel/onboarding"
         xmlns="http://docs.oasis-open.org/wsbpel/2.0/process/executable"
         xmlns:on="http://serraalta.example/wsdl/onboarding">
  <partnerLinks>
    <partnerLink name="field" partnerLinkType="on:FieldLT" myRole="onboarding"/>
    <partnerLink name="bank" partnerLinkType="on:BankLT" partnerRole="registry"/>
  </partnerLinks>
  <variables>
    <variable name="application" messageType="on:ApplicationMsg"/>
    <variable name="account" messageType="on:AccountMsg"/>
    <variable name="accountId" messageType="on:AccountIdMsg"/>
  </variables>
  <sequence>
    <receive name="ReceiveApplication" partnerLink="field" operation="apply"
             variable="application" createInstance="yes"/>
    <assign name="PrepareAccount">
      <copy>
        <from variable="application" part="bankDetails"/>
        <to variable="account" part="details"/>
      </copy>
    </assign>
    <invoke name="RegisterAccount" partnerLink="bank" operation="registerAccount"
            inputVariable="account" outputVariable="accountId"/>
  </sequence>
</process>
```

Read it from the `<sequence>` down. The `<receive>` waits for a call to the `apply` operation on the
`field` partner link, where this process plays the role `onboarding`; `createInstance="yes"` says
that a call there starts a new instance, the way a start event does in BPMN. The `<assign>` copies
the bank details from the incoming message into the message the bank expects. The `<invoke>` calls
the bank's `registerAccount` operation and keeps the reply in `accountId`. The `on:` names point
into a WSDL file that this fragment does not show; without it, the process means nothing.

A later `<receive>` for the signed contract would need one more idea, **correlation**: a value in
the message, such as the farm's application number, that tells the engine which of the running
instances the message belongs to. BPMN engines need the same thing for a message event in the
middle of a process, and BPEL was the first place most engineers met it.

The rest of the language will look familiar after the previous sections. `<flow>` runs activities
in parallel, like a parallel split and join. `<if>` and `<while>` branch and loop. `<pick>` waits
for whichever of several messages or alarms comes first, which is BPMN's event-based gateway.
`<scope>` groups activities with their own **fault handlers** and **compensation handlers**, the same
ideas as an error boundary event and a compensation activity. The concepts carried over; the
notation did not.

## Why it faded

**It spoke only SOAP.** A BPEL process could call a partner only through a WSDL operation. When
services moved to REST and JSON over the 2010s, every call to something new needed a SOAP wrapper
first, and the language aged with the protocol it was built on.

**It had no people in it.** Every BPEL activity is a message exchange with a service. Onboarding is
mostly people: a document check, a visit, a manager deciding. IBM and SAP proposed BPEL4People and
WS-HumanTask in 2005 to add human tasks, and OASIS later took them on, but by then each vendor had
its own extension, and a process with people in it was no longer portable between engines.

**Nobody outside IT could read it.** The business drew its process in a diagram tool, and IT
translated the drawing into BPEL. The translation was lossy: a BPMN diagram is a graph, where any
element can connect to almost any other, and BPEL is mostly built from nested blocks, so a diagram
with arrows that jumped between branches had no direct translation. Once IT had changed the BPEL,
the drawing was out of date, and nothing carried the change back. **Two artefacts describing one
process, edited by two groups in two languages, will disagree**, and in most companies they did
within a release or two.

**BPMN 2.0 took its job.** Once BPMN had an execution semantics and an XML format of its own, the
model the business could read was also the file an engine could run, and the translation step had
no reason to exist. The engines most teams pick today, the open ones from Camunda and Flowable among
them, execute BPMN directly and call services of any kind.

## Orchestration and choreography

BPEL made one distinction lastingly clear. **In orchestration, one process is the conductor: it
knows the whole sequence, calls each participant in turn and holds the state.** A BPEL process is an
orchestration, and so is a single BPMN process in one pool. You can ask the conductor where any
instance is.

**In choreography, there is no conductor.** Each participant knows its own part and reacts to the
messages it receives, and the process exists only as the sum of what they all do. W3C started a
language for describing choreographies, WS-CDL, in the same years as BPEL; it never became widely
used. BPMN 2.0 has choreography diagrams, and few tools execute them.

The trade is real in both directions. An orchestration gives you one place to see the state of every
farm's application and one place to change the order of steps; it also gives every participant a
dependency on the conductor. A choreography spreads the knowledge so that no single component has
to know everything, and leaves nobody who can answer "where is farm 4471?" without asking all of
them. Lessons 10 and 11 come back to choreography built from events and messages. For onboarding,
Joana and Denise want the answer to that question more than anything else, which points towards an
orchestrator; the farm and the bank stay outside it, as pools exchanging messages.
