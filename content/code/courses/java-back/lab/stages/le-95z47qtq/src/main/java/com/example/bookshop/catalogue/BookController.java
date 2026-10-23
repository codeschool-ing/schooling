package com.example.bookshop.catalogue;

import java.net.URI;
import java.util.List;

import jakarta.validation.Valid;

import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.data.web.PagedModel;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/books")
public class BookController {

    private final BookService books;

    public BookController(BookService books) {
        this.books = books;
    }

    @GetMapping
    public PagedModel<BookResponse> list(@PageableDefault(size = 20, sort = "id") Pageable pageable) {
        return new PagedModel<>(books.list(pageable));
    }

    @GetMapping("/search")
    public List<BookResponse> search(@RequestParam String q) {
        return books.search(q);
    }

    @GetMapping("/by-author")
    public List<TitleAndPrice> byAuthor(@RequestParam String name) {
        return books.titlesBy(name);
    }

    @GetMapping("/{id}")
    public BookResponse get(@PathVariable long id) {
        return books.get(id);
    }

    @PostMapping
    public ResponseEntity<BookResponse> add(@Valid @RequestBody BookRequest request) {
        BookResponse book = books.add(request);
        return ResponseEntity.created(URI.create("/books/" + book.id())).body(book);
    }
}
