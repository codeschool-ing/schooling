---
title: Gerando o Go
version: 1
---

Um comando `protoc` roda os dois plugins sobre o contrato. Cada `_out` diz onde um plugin escreve, e
`module=example.com/boxoffice` manda colocar os arquivos conforme o `go_package` deles, relativo a este
módulo, então eles caem em `internal/seatspb`:

```
ana@vm:~/boxoffice$ protoc --go_out=. --go_opt=module=example.com/boxoffice --go-grpc_out=. --go-grpc_opt=module=example.com/boxoffice proto/seats.proto
ana@vm:~/boxoffice$ ls internal/seatspb; wc -l internal/seatspb/*.go
seats.pb.go
seats_grpc.pb.go
  414 internal/seatspb/seats.pb.go
  206 internal/seatspb/seats_grpc.pb.go
  620 total
```

**620 linhas de Go a partir de um contrato de 45 linhas**, em dois arquivos. Como os do sqlc, eles
começam com `Code generated ... DO NOT EDIT.` e são mudados editando o `.proto` e rodando o comando de
novo.

## As mensagens

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

Uma mensagem vira uma struct com um campo exportado para cada campo do contrato, nomeado no estilo do
Go, `Id` para `id`, com o número dele na tag. Os três campos não exportados são a contabilidade da
biblioteca, entre eles `unknownFields`, que a seção 09 põe para trabalhar. **Passe sempre essas structs
por ponteiro** e leia-as pelos getters, `e.GetId()`: um getter numa mensagem nil devolve o valor zero em
vez de entrar em pânico, e copiar a struct copia o estado interno da biblioteca, o que o `go vet`
aponta.

## As duas interfaces

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

**`SeatsClient` é o que quem chama usa**: três métodos, o unário devolvendo um `*Event`, os dois de
streaming devolvendo um objeto de fluxo para ler ou escrever. **`SeatsServer` é o que o boxoffice
precisa implementar.** O último método dela, `mustEmbedUnimplementedSeatsServer`, não pode ser escrito
à mão, de propósito: um tipo servidor só o satisfaz embutindo `UnimplementedSeatsServer`, que também
responde `Unimplemented` para qualquer método que o servidor ainda não escreveu. A ideia é que
**acrescentar um método ao contrato não quebra o build de todo servidor que ainda não acompanhou.**

Os fluxos são tipos genéricos do pacote grpc, `grpc.ServerStreamingServer[Availability]` e os outros,
então o `Send` e o `Recv` de cada um são tipados exatamente para as mensagens daquela chamada.
