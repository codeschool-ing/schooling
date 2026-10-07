#!/usr/bin/env python3
"""The data flow diagram of Vereda's patient portal, written as code."""
from pytm import TM, Actor, Boundary, Dataflow, Datastore, ExternalEntity, Process, Server

tm = TM("Vereda patient portal")
tm.description = "Booking, records and reminders for a chain of physiotherapy clinics."
tm.isOrdered = True

# Trust boundaries: where the level of trust changes.
internet = Boundary("Internet")
cloud = Boundary("Vereda cloud")
private = Boundary("Private network")
private.inBoundary = cloud
clinic = Boundary("Clinic network")
vendors = Boundary("Vendors")

# External entities: people and systems outside Vereda's control.
patient = Actor("Patient")
patient.inBoundary = internet
patient.protocol = "HTTPS"
staff = Actor("Clinic staff")
staff.inBoundary = clinic
sms = ExternalEntity("SMS provider")
sms.inBoundary = vendors
sms.protocol = "HTTPS"
payments = ExternalEntity("Payment gateway")
payments.inBoundary = vendors
payments.protocol = "HTTPS"

# Processes: code Vereda runs.
portal = Server("Portal")
portal.inBoundary = cloud
portal.protocol = "HTTPS"
portal.usesSessionTokens = True
console = Server("Staff console")
console.inBoundary = cloud
console.protocol = "HTTPS"
console.usesSessionTokens = True
worker = Process("Reminder worker")
worker.inBoundary = private

# Data stores.
db = Datastore("Records database")
db.inBoundary = private
db.storesPII = True
db.storesSensitiveData = True
db.isSQL = True
db.protocol = "PostgreSQL"
files = Datastore("Exam files")
files.inBoundary = private
files.storesPII = True
files.storesSensitiveData = True
files.protocol = "HTTPS"

# Data flows, in the order a booking happens. A flow takes its protocol
# from the element it arrives at.
Dataflow(patient, portal, "Sign in and book")
Dataflow(portal, patient, "Pages and booking status")
Dataflow(patient, portal, "Upload exam PDF")
Dataflow(portal, files, "Store exam PDF")
Dataflow(portal, db, "Read and write bookings")
Dataflow(portal, payments, "Charge for a session")
Dataflow(payments, portal, "Payment webhook")
Dataflow(staff, console, "Manage the agenda")
Dataflow(console, db, "Read and write records")
Dataflow(console, files, "Open exam PDF")
Dataflow(worker, db, "Read tomorrow's bookings")
Dataflow(worker, sms, "Send reminder")

if __name__ == "__main__":
    tm.process()
