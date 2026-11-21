require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @book = books(:one)
    sign_in_as(users(:one))
  end

  test "should get index" do
    get books_url
    assert_response :success
  end

  test "should get new" do
    get new_book_url
    assert_response :success
  end

  test "should create book" do
    assert_difference("Book.count") do
      # ISBN ha valore unique => ISBN diverso da quelli delle fixture
      book_params = {
        book: {
          author: "Author 1",
          category: "Category 1",
          isbn: "ISBNCODE",
          publication_year: Date.current.year,
          title: "Title 1"
        }
      }
      post books_url, params: book_params
    end

    assert_redirected_to book_url(Book.last)
  end

  test "should show book" do
    get book_url(@book)
    assert_response :success
  end

  test "should get edit" do
    get edit_book_url(@book)
    assert_response :success
  end

  test "should update book" do
    assert_changes -> { @book.reload.title }, to: "Titolo 1" do
      patch book_url(@book), params: { book: { title: "Titolo 1" } }
    end
    assert_redirected_to book_url(@book)
  end

  test "elimina un libro senza copie" do
    book = Book.create!(title: "Title 1", isbn: "ISBNCODE", author: "Author 1", publication_year: Date.current.year, category: "Category 1")
    assert_difference("Book.count", -1) do
      delete book_url(book)
    end

    assert_redirected_to books_url
  end

  test "non elimina un libro con copie" do
    assert_no_difference("Book.count") do
      delete book_url(@book)
    end

    assert_redirected_to book_url(@book)
    assert_match "copie", flash[:alert]
  end

  test "senza login si viene mandati al login" do
    sign_out
    get books_url
    assert_redirected_to new_session_url
  end

  test "non viene creato un libro non valido" do
    assert_no_difference("Book.count") do
      post books_url, params: { book: { author: "", title: "", publication_year: 0, category: nil } }
    end
    assert_response :unprocessable_content
  end

  test "non viene aggiornato il libro se titolo vuoto" do
    assert_no_changes -> { @book.reload.title } do
      patch book_url(@book), params: { book: { title: "" } }
    end
    assert_response :unprocessable_content
  end

  test "la ricerca mostra solo i risultati e ricorda il campo" do
    get books_url, params: { title: "harry" }
    assert_response :success
    assert_select "tbody tr", 1
    assert_select "input[name=title][value=?]", "harry"
  end

  test "ricerca senza risultati" do
    get books_url, params: { title: "xxxxxxx" }
    assert_select "table", 0
    assert_select "p", "Nessun libro trovato."
  end

  test "ricerca di un libro senza copie" do
    get books_url, params: { isbn: "9781234567802" }
    assert_response :success
    assert_select "tbody tr", 1
  end

  test "Azzera toglie i filtri e svuota i campi" do
    # Si parte con una ricerca filtrata
    get books_url, params: { title: "Harry" }
    assert_select "tbody tr", 1

    # Verifico che il link esista e punta all'elenco senza parametri
    assert_select "a[href=?]", books_path, text: "Azzera"

    # Seguo il link
    link = css_select("a").find { |a| a.text == "Azzera" }
    get link["href"]

    # Elenco completo, campo di ricerca precedente deve essere vuoto
    assert_select "tbody tr", Book.count
    assert_select "input[name=title][value]", 0
  end
end
