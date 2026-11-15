require "test_helper"

class BookTest < ActiveSupport::TestCase
  setup do
    @book = books(:one)
  end

  test "normalizzazione del codice ISBN" do
    valid_isbn = "ISBN109781234567897"
    not_valid_isbn = " ISBN10 - 9781234567897 "
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
end
