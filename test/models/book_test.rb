require "test_helper"

class BookTest < ActiveSupport::TestCase
  setup do
    @book = books(:one)
  end

  test "normalizzazione del titolo" do
    book = Book.create!(title: "  Harry Potter e la pietra filosofale  ",
                        author: "jk rowling", publication_year: 1999,
                        category: "Fantasy", isbn: "XXXXXXXXX")
    assert_equal "Harry Potter e la pietra filosofale", book.title
  end

  test "normalizzazione di autore" do
    book = Book.create!(title: "Harry Potter e la pietra filosofale",
                        author: "  jk rowling  ", publication_year: 1999,
                        category: "Fantasy", isbn: "XXXXXXXXX")
    assert_equal "jk rowling", book.author
  end

  test "normalizzazione della categoria" do
    book = Book.create!(title: "Il barone rampante",
                        author: "Italo Calvino", publication_year: 1954,
                        category: "  romanzo storico  ", isbn: "XXXXXXXXX")
    assert_equal "romanzo storico", book.category
  end

  test "normalizzazione del codice ISBN" do
    valid_isbn = "ISBN109781234567897"
    not_valid_isbn = " isbn10 - 9781234567897 "
    @book.isbn = not_valid_isbn
    assert_equal valid_isbn, @book.isbn
  end

  test "titolo deve essere presente" do
    @book.title = nil
    assert_not @book.valid?
    assert @book.errors.added?(:title, :blank)
  end

  test "titolo non deve essere vuoto" do
    @book.title = ""
    assert_not @book.valid?
    assert @book.errors.added?(:title, :blank)
  end

  test "codice ISBN deve essere presente" do
    @book.isbn = nil
    assert_not @book.valid?
    assert @book.errors.added?(:isbn, :blank)
  end

  test "codice ISBN non deve essere vuoto" do
    @book.isbn = ""
    assert_not @book.valid?
    assert @book.errors.added?(:isbn, :blank)
  end

  test "codice ISBN deve essere unico" do
    isbn_code = "978111111111"
    Book.create!(title: "Libro 1", author: "Autore 1", isbn: isbn_code, category: "Categoria 1", publication_year: Date.current.year)
    book = Book.new(title: "Libro 2", author: "Autore 2", isbn: isbn_code, category: "Categoria 2", publication_year: Date.current.year)
    assert_not book.valid?
    assert book.errors.of_kind?(:isbn, :taken)
  end

  test "categoria deve essere presente" do
    @book.category = nil
    assert_not @book.valid?
    assert @book.errors.added?(:category, :blank)
  end

  test "categoria non deve essere vuoto" do
    @book.category = ""
    assert_not @book.valid?
    assert @book.errors.added?(:category, :blank)
  end

  test "autore deve essere presente" do
    @book.author = nil
    assert_not @book.valid?
    assert @book.errors.added?(:author, :blank)
  end

  test "autore non deve essere vuoto" do
    @book.author = ""
    assert_not @book.valid?
    assert @book.errors.added?(:author, :blank)
  end

  test "anno di pubblicazione deve essere un numero" do
    # caso stringa vuota
    @book.publication_year = ""
    assert_not @book.valid?
    assert @book.errors.of_kind?(:publication_year, :not_a_number)

    # caso di valore nil
    @book.publication_year = nil
    assert_not @book.valid?
    assert @book.errors.of_kind?(:publication_year, :not_a_number)
  end

  test "anno di pubblicazione deve essere positivo" do
    @book.publication_year = 0
    assert_not @book.valid?
    assert @book.errors.of_kind?(:publication_year, :greater_than)
  end

  test "anno di pubblicazione non successivo dell'anno corrente" do
    @book.publication_year = Date.current.year + 1
    assert_not @book.valid?
    assert @book.errors.of_kind?(:publication_year, :less_than_or_equal_to)
  end

  test "anno di pubblicazione deve essere un intero" do
    @book.publication_year = 2026.50
    assert_not @book.valid?
    assert @book.errors.of_kind?(:publication_year, :not_an_integer)
  end

  test "l'eliminazione di un libro con copie viene bloccata" do
    assert_no_difference("Book.count") { @book.destroy }
    assert @book.errors.of_kind?(:base, "restrict_dependent_destroy.has_many".to_sym)
  end

  # Test sulla ricerca
  test "ricerca per titolo: parziale e senza maiuscole" do
    result = Book.search(title: "haRRy")
    assert_includes result, books(:one)
    assert_not_includes result, books(:two)
  end

  test "campo vuoto non filtra" do
    assert_equal Book.count, Book.search(title: "", category: "").count
  end

  test "titolo scritto con spazi e minuscole viene trovato" do
    assert_equal [ books(:one) ], Book.search(title: "  harry potter - L'ordine della Fenice  ").to_a
  end

  test "i filtri si combinano in AND" do
    assert_empty Book.search(title: "Harry", category: "Thriller")
  end

  test "il % è un carattere normale" do
    assert_empty Book.search(title: "%")
  end

  test "ricerca per autore: parziale e senza maiuscole" do
    result = Book.search(author: "rowling")
    assert_includes result, books(:one)
    assert_not_includes result, books(:two)
  end

  test "ricerca per ISBN: esatto con trattini e spazi" do
    result = Book.search(isbn: " 978-1234 567897 ")
    assert_includes result, books(:one)
    assert_not_includes result, books(:two)
  end

  test "ricerca per categoria: esatta" do
    result = Book.search(category: "Fantasy")
    assert_includes result, books(:one)
    assert_not_includes result, books(:two)
  end

  test "ricerca per campi con soli spazi" do
    assert_equal Book.all.size, Book.search(title: "    ").count
    assert_equal Book.all.size, Book.search(author: "    ").count
    assert_equal Book.all.size, Book.search(isbn: "    ").count
    assert_equal Book.all.size, Book.search(category: "    ").count
  end

  test "categoria: niente doppioni e in ordine alfabetico" do
    Book.create!(title: "Nvidaia e il genio di Jensen Huang",
                author: "Tae Kim", publication_year: 2025,
                category: "Autobiografie", isbn: "YYYYYYYY")
    Book.create!(title: "Il sistema operativo Linux",
                author: "Linus Torvalds", publication_year: 2010,
                category: "Informatica", isbn: "XXXXXXXX")
    Book.create!(title: "Harry Potter e il Principe Mezzosangue",
                author: "J.K. Rowling", publication_year: 2008,
                category: "Fantasy", isbn: "AAAAAAAAAA") # categoria doppione

    assert_equal [ "Attualità", "Autobiografie", "Fantasy", "Informatica", "Thriller" ], Book.categories
  end
end
