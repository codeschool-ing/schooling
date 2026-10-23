---
title: Generating the Go
version: 1
---

One `protoc` command runs both plugins over the contract. Each `_out` names where a plugin writes, and
`module=example.com/boxoffice` tells it to place the files by their `go_package` relative to this module,
so they land in `internal/seatspb`:

```
ana@vm:~/boxoffice$ protoc --go_out=. --go_opt=module=example.com/boxoffice --go-grpc_out=. --go-grpc_opt=module=example.com/boxoffice proto/seats.proto
ana@vm:~/boxoffice$ ls internal/seatspb; wc -l internal/seatspb/*.go
seats.pb.go
seats_grpc.pb.go
  414 internal/seatspb/seats.pb.go
  206 internal/seatspb/seats_grpc.pb.go
  620 total
```

**620 lines of Go from a 45-line contract**, in two files. Like sqlc's, they start with `Code generated
... DO NOT EDIT.` and are changed by editing the `.proto` and running the command again.

## The messages

```
ana@vm:~/boxoffice$ sed -n "/^type Event struct/,/^}/p" internal/seatspb/seats.pb.go
type Event struct {
	state         protoimpl.MessageState `protogen:"open.v1"`
	Id            int32                  `protobuf:"varint,1,opt,name=id,proto3" json:"id,omitempty"`
	Name          string                 `protobuf:"bytes,2,opt,name=name,proto3" json:"name,omitempty"`
	Seats         int32                  `protobuf:"varint,3,opt,name=seats,proto3" json:"seats,omitempty"`
	Sold          int32                  `protobuf:"varint,4,opt,name=sold,proto3" json:"sold,omitempty"`
	unknownFields protoimpl.UnknownFields
	sizeCache     protoimpl.SizeCache
}
```

A message becomes a struct with one exported field per field of the contract, named in Go's style,
`Id` for `id`, with its number in the tag. The three unexported fields are the library's bookkeeping,
among them `unknownFields`, which section 09 puts to use. **Always pass these structs by pointer** and
read them through their getters, `e.GetId()`: a getter on a nil message returns the zero value instead
of panicking, and copying the struct copies the library's internal state, which `go vet` reports.

## The two interfaces

```
ana@vm:~/boxoffice$ sed -n "/^type SeatsServer interface/,/^}/p;/^type SeatsClient interface/,/^}/p" internal/seatspb/seats_grpc.pb.go
type SeatsClient interface {
	// GetEvent answers one event.
	GetEvent(ctx context.Context, in *GetEventRequest, opts ...grpc.CallOption) (*Event, error)
	// Watch sends an event's availability now, and again whenever it changes.
	Watch(ctx context.Context, in *WatchRequest, opts ...grpc.CallOption) (grpc.ServerStreamingClient[Availability], error)
	// Scan reads the tickets presented at the door and answers once, at the end.
	Scan(ctx context.Context, opts ...grpc.CallOption) (grpc.ClientStreamingClient[ScanRequest, ScanSummary], error)
}
type SeatsServer interface {
	// GetEvent answers one event.
	GetEvent(context.Context, *GetEventRequest) (*Event, error)
	// Watch sends an event's availability now, and again whenever it changes.
	Watch(*WatchRequest, grpc.ServerStreamingServer[Availability]) error
	// Scan reads the tickets presented at the door and answers once, at the end.
	Scan(grpc.ClientStreamingServer[ScanRequest, ScanSummary]) error
	mustEmbedUnimplementedSeatsServer()
}
```

**`SeatsClient` is what a caller uses**: three methods, the unary one returning an `*Event`, the two
streaming ones returning a stream object to read from or write to. **`SeatsServer` is what boxoffice must
implement.** Its last method, `mustEmbedUnimplementedSeatsServer`, cannot be written by hand on purpose:
a server type satisfies it only by embedding `UnimplementedSeatsServer`, which also answers
`Unimplemented` for any method the server has not written yet. The point is that **adding a method to
the contract does not break the build of every server that has not caught up.**

The streams are generic types from the grpc package, `grpc.ServerStreamingServer[Availability]` and the
rest, so each one's `Send` and `Recv` are typed for exactly the messages of that call.
