---
title: From a model to something an engine runs
version: 1
---

Lesson 6 described the suites and engines that run processes. This section is about the file they
run, and about the gap between the diagram Denise can read and the model an engine can execute.
The usual picture is that the business draws, the engine runs, and nobody writes code. **A diagram
says what happens in what order; an executable model also says, for every shape, exactly how.** The
second half is most of the work, and it is engineering.

## What a shape needs before it can run

Take the happy path drawn earlier in this lesson and ask, shape by shape, what an engine would need
to know:

| in the diagram | what the engine needs |
|---|---|
| the whole process | process variables: the application number, the farm's tax id, the visit result, the account id, with types |
| "Check documents", a user task | a form to show, and an assignment: which group's task list it appears in |
| "Register bank account", a service task | an implementation: which service to call, with which variables, and what to do with the reply |
| "approved?", a gateway | a condition on each outgoing flow, in an expression language the engine reads |
| the 10-day timer | a timer definition, `P10D` |
| "signed contract received" | a message name and a correlation key, so the right instance gets the message |
| the error on the bank task | an error code the service's response is mapped to |
| the model itself | a version, because instances already running keep the version they started on |

None of those is visible in the picture, and each of them is a place where the model and the
systems around it have to agree. The last row is the one lesson 6 dwelt on: change the model while
two hundred farms are halfway through it and two versions run side by side until the old instances
finish or are migrated.

## The file

BPMN 2.0 defines an XML format for all of this. Here is the first part of onboarding, cut down to
the document check and its gateway, for reading:

```xml
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                  id="Definitions_Onboarding"
                  targetNamespace="http://serraalta.example/bpmn/onboarding">
  <bpmn:process id="FarmOnboarding" name="Farm onboarding" isExecutable="true">
    <bpmn:startEvent id="Start_Application" name="Application received"/>
    <bpmn:sequenceFlow id="Flow_1" sourceRef="Start_Application" targetRef="Task_CheckDocuments"/>
    <bpmn:userTask id="Task_CheckDocuments" name="Check documents"/>
    <bpmn:sequenceFlow id="Flow_2" sourceRef="Task_CheckDocuments" targetRef="Gateway_Complete"/>
    <bpmn:exclusiveGateway id="Gateway_Complete" name="Documents complete?" default="Flow_Missing"/>
    <bpmn:sequenceFlow id="Flow_Complete" name="yes" sourceRef="Gateway_Complete" targetRef="End_Ready">
      <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression">${documentsComplete}</bpmn:conditionExpression>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="Flow_Missing" name="no" sourceRef="Gateway_Complete" targetRef="Task_AskForDocuments"/>
    <bpmn:sendTask id="Task_AskForDocuments" name="Ask for missing documents"/>
    <bpmn:sequenceFlow id="Flow_3" sourceRef="Task_AskForDocuments" targetRef="End_Returned"/>
    <bpmn:endEvent id="End_Ready" name="Documents accepted"/>
    <bpmn:endEvent id="End_Returned" name="Application returned"/>
  </bpmn:process>
</bpmn:definitions>
```

Four things in it are worth noticing. **Every element has an id, and the flows join elements by id,
never by name**: rename "Check documents" and nothing detaches. The gateway names its default flow
in the `default` attribute, which is the slash you saw on the diagram. The condition is text in an
expression language: the specification's default is XPath, and `${documentsComplete}` is the JUEL
style that the Camunda and Flowable engines read, which already makes this line less portable than
the rest. And **there is no picture in it**. Positions and sizes live in a separate part of the same
file, the diagram interchange section under `bpmndi:BPMNDiagram`, left out here; an engine ignores
it, and a modeller needs it to draw the diagram again.

What is not in it is the half of the table above that the standard leaves open. Which form a user
task shows, which group it is assigned to, which class or URL a service task calls: engines put
these in **extension attributes in their own namespace**, prefixed `camunda:` or `flowable:` or
something else. The core of the file moves between tools; the bindings do not. A model "in BPMN"
is portable in the way a SQL schema with vendor-specific types is portable: the structure survives
and the parts that make it run have to be redone.

## The round trip

Here the problem that hurt BPEL comes back in a smaller form. Denise draws in one tool, an engineer
opens the file and adds the bindings, Denise later moves two tasks in her tool, and the bindings
either vanish or keep pointing at the old structure. The same process now exists twice, and the two
copies diverge with every change.

There are two honest ways to live with it:

- **One model, owned by the engineers and reviewed by the business.** The executable file is the
  only one; it sits in version control next to the code it calls, and every change to it goes
  through a pull request that Denise reviews as a rendered diagram. The business never edits the
  file directly, and the model can never be out of date, because it is what runs.
- **Two models, and an agreement that they differ.** A descriptive model for people, kept simple and
  owned by the process office, and an implementation, in an engine or in code, owned by IT. The
  descriptive model is reviewed against the implementation on a schedule, and nobody pretends one is
  generated from the other.

What fails is the middle: one file that both groups edit in different tools. The BPMN 2.0
specification itself acknowledges the split, in its conformance classes: a **descriptive** subclass
with the handful of shapes people need to document a process, an **analytic** one with more, and a
**common executable** one for models an engine runs. A model can be correct in the first and
unusable in the third.

## When to execute and when to document

Not every process should run on an engine. An engine earns its keep when **the process is long,
waits for people and outside parties, has deadlines, and you need to see where every instance is**;
onboarding is all four. It also earns its keep when the order of steps changes more often than the
steps themselves, because then the model is the part that moves.

It does not earn its keep when the process is really one system's internal logic: a loop over
order lines belongs in code, where a test can reach it. Nor when the state already lives in a system
that tracks it: the order-to-cash chain from lesson 1 is a process, and SAP's document flow already
records where every order is, so a second engine following it would be a second record that could
disagree. And it does not earn its keep while the process is still being discovered, because a
model that will change shape every week is cheaper on paper.

Joana's first instinct, from eight years of building everything as services, was to make the whole
model executable, down to the steps inside the quality visit. Denise talked her out of the visit:
it is one technician at one farm with a checklist, and the process only needs to know that a report
came back, what it said and when. **Execute the coordination, not the craft.** The visit stays a
single user task with a form; what the technician does in the cowshed is the quality team's
procedure, kept in Documentum where lesson 5 left it.

They ended with a decision Joana recorded as an ADR. The BPMN model, with the timers, the error and
the compensation, is the specification of onboarding from now on. It is kept in the architecture
repository, Denise owns its content, and whatever runs onboarding next, IBM BPM, an open engine or
code, has to answer "where is farm 4471?" in terms of that model. Which of the three it will be
waits for the integration map Joana draws in lessons 9 to 11, because the cost of every call to the
bank, Coleta and SAP depends on how those systems can be reached.
