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
staff = Actor("Clinic staff")
staff.inBoundary = clinic
sms = ExternalEntity("SMS provider")
sms.inBoundary = vendors
payments = ExternalEntity("Payment gateway")
payments.inBoundary = vendors

# Processes: code Vereda runs.
portal = Server("Portal")
portal.inBoundary = cloud
portal.usesSessionTokens = True
console = Server("Staff console")
console.inBoundary = cloud
console.usesSessionTokens = True
worker = Process("Reminder worker")
worker.inBoundary = private

# Data stores.
db = Datastore("Records database")
db.inBoundary = private
db.storesPII = True
db.storesSensitiveData = True
db.isSQL = True
files = Datastore("Exam files")
files.inBoundary = private
files.storesPII = True
files.storesSensitiveData = True

# Data flows, in the order a booking happens.
Dataflow(patient, portal, "Sign in and book").protocol = "HTTPS"
Dataflow(portal, patient, "Pages and booking status").protocol = "HTTPS"
Dataflow(patient, portal, "Upload exam PDF").protocol = "HTTPS"
Dataflow(portal, files, "Store exam PDF")
Dataflow(portal, db, "Read and write bookings").protocol = "PostgreSQL"
Dataflow(portal, payments, "Charge for a session").protocol = "HTTPS"
Dataflow(payments, portal, "Payment webhook").protocol = "HTTPS"
Dataflow(staff, console, "Manage the agenda").protocol = "HTTPS"
Dataflow(console, db, "Read and write records").protocol = "PostgreSQL"
Dataflow(console, files, "Open exam PDF")
Dataflow(worker, db, "Read tomorrow's bookings").protocol = "PostgreSQL"
Dataflow(worker, sms, "Send reminder").protocol = "HTTPS"

if __name__ == "__main__":
    tm.process()
