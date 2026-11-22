require "test_helper"

class BookCopiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "senza login si viene mandati al login" do
    sign_out
    get edit_book_copy_url(book_copies(:one))
    assert_redirected_to new_session_url
  end

  test "crea una copia nel libro dell'URL" do
    book = books(:one)
    assert_difference("book.book_copies.count") do
      post book_book_copies_url(book), params: {
        book_copy: {
          inventory_code: "INV-0001-A",
          location: "Scaffale 1 - Sala A"
        }
      }
    end
    assert_redirected_to book_url(book)
  end

  test "book_id nel form viene ignorato" do
    book = books(:one)
    post book_book_copies_url(book), params: {
      book_copy: {
        inventory_code: "INV-0001-A",
        location: "Scaffale 1 - Sala A",
        book_id: books(:two).id
      }
    }
    assert_equal book, BookCopy.find_by(inventory_code: "INV-0001-A").book
  end

  test "elimina una copia senza prestiti" do
    book_copy = book_copies(:no_lent)
    assert_difference("BookCopy.count", -1) do
      delete book_copy_url(book_copy)
    end
    assert_redirected_to book_url(book_copy.book)
  end

  test "non elimina una copia con prestiti attivi" do
    book_copy = book_copies(:two) # ha un prestito attivo nelle fixture
    assert_no_difference("BookCopy.count") do
      delete book_copy_url(book_copy)
    end
    assert_redirected_to book_url(book_copy.book)
    assert_match "prestiti", flash[:alert]
  end

  test "non elimina una copia con prestiti chiusi" do
    book_copy = book_copies(:one) # ha un prestito chiuso nelle fixture
    assert_no_difference("BookCopy.count") do
      delete book_copy_url(book_copy)
    end
    assert_redirected_to book_url(book_copy.book)
    assert_match "prestiti", flash[:alert]
  end

  test "chiamata a edit della copia" do
    get edit_book_copy_url(book_copies(:one))
    assert_response :success
  end

  test "aggiorna le informazioni della copia del libro" do
    book_copy = book_copies(:one)
    assert_changes -> { book_copy.reload.inventory_code }, to: "INV-0002" do
      patch book_copy_url(book_copy), params: { book_copy: { inventory_code: "INV-0002" } }
    end
    assert_redirected_to book_url(book_copy.book)
  end

  test "errore nell'aggiunta di una nuova copia con inventory_code duplicato" do
    book = books(:one)
    assert_no_difference("book.book_copies.count") do
      post book_book_copies_url(book), params: {
        book_copy: {
          inventory_code: "4PPRMHHB",
          location: "Scaffale 1 - Sala A"
        }
      }
    end
    assert_response :unprocessable_content
    assert_select "div.alert.error li"
  end

  test "errore nell'aggiornamento del copia" do
    book_copy = book_copies(:one)
    assert_no_changes -> { book_copy.reload.inventory_code } do
      patch book_copy_url(book_copy), params: { book_copy: { inventory_code: "4PPRMHHB" } }
    end
    assert_response :unprocessable_content
    assert_select "div.alert.error li"
  end

  test "la pagina del libro mostra lo stato di ogni copia" do
    loan = loans(:two) # prestito aperto di book_copies(:two)
    get book_url(books(:two))
    assert_response :success

    assert_select "tbody tr", text: /#{book_copies(:two).inventory_code}/  do
      assert_select "span.badge", "In prestito"
      assert_select "td", /#{members(:two).full_name}/
      assert_select "td", /#{Regexp.escape(I18n.l(loan.due_on))}/
    end

    assert_select "tbody tr", text: /#{book_copies(:no_lent).inventory_code}/ do
      assert_select "span.badge.info", "Disponibile"
      assert_select "td", text: /#{members(:two).full_name}/, count: 0
    end
  end
end
