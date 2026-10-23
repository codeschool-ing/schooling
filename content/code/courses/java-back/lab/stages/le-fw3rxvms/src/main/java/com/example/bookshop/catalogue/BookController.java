package com.example.bookshop.catalogue;

import java.net.URI;
import java.util.List;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

import org.springdoc.core.annotations.ParameterObject;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.data.web.PagedModel;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * The catalogue over HTTP: reading it is open to anyone, adding to it needs
 * the {@code catalogue:write} scope.
 */
@Tag(name = "Catalogue")
@RestController
@RequestMapping("/books")
public class BookController {

    private final BookService books;

    public BookController(BookService books) {
        this.books = books;
    }

    /**
     * One page of the catalogue, in the order the {@code sort} parameter asks for.
     *
     * @param pageable page number, page size and sort, from the query string
     * @return the page, with the total count in its metadata
     */
    @Operation(summary = "List the catalogue, a page at a time")
    @GetMapping
    public PagedModel<BookResponse> list(@ParameterObject @PageableDefault(size = 20, sort = "id") Pageable pageable) {
        return new PagedModel<>(books.list(pageable));
    }

    /**
     * Books whose title contains the text, ignoring case.
     *
     * @param q the text to look for
     * @return the matching books, by title
     */
    @Operation(summary = "Search titles")
    @GetMapping("/search")
    public List<BookResponse> search(@RequestParam String q) {
        return books.search(q);
    }

    /**
     * Titles and prices of one author's books.
     *
     * @param name the author's name, exactly as stored
     * @return title and price of each book, by title
     */
    @Operation(summary = "Titles and prices by one author")
    @GetMapping("/by-author")
    public List<TitleAndPrice> byAuthor(@RequestParam String name) {
        return books.titlesBy(name);
    }

    /**
     * One book.
     *
     * @param id the book's id
     * @return the book
     * @throws BookNotFoundException when no book has that id
     */
    @Operation(summary = "Get one book")
    @ApiResponse(responseCode = "200", description = "The book")
    @ApiResponse(responseCode = "404", description = "No book has that id",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @GetMapping("/{id}")
    public BookResponse get(@Parameter(description = "the book's id") @PathVariable long id) {
        return books.get(id);
    }

    /**
     * Adds a book to the catalogue, creating its author if the name is new.
     *
     * @param request the book, validated before this method runs
     * @return 201 with the new book and its address in {@code Location}
     * @throws DuplicateIsbnException when the ISBN is already in the catalogue
     */
    @Operation(summary = "Add a book", security = @SecurityRequirement(name = "bearer"))
    @ApiResponse(responseCode = "201", description = "Added")
    @ApiResponse(responseCode = "400", description = "The request failed validation",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @ApiResponse(responseCode = "409", description = "The ISBN is already in the catalogue",
            content = @Content(mediaType = "application/problem+json", schema = @Schema(implementation = ProblemDetail.class)))
    @PostMapping
    public ResponseEntity<BookResponse> add(@Valid @RequestBody BookRequest request) {
        BookResponse book = books.add(request);
        return ResponseEntity.created(URI.create("/books/" + book.id())).body(book);
    }
}
