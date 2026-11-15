require "test_helper"

class BookCopyTest < ActiveSupport::TestCase
  setup do
    @book = books(:one)
    @book_copy = @book.book_copies.first
    @member = members(:one)
  end

  test "normalizzazione codice inventario" do
    not_valid_inventory_code = " FASX sds"
    valid_inventory_code = "FASXSDS"
    @book_copy.inventory_code = not_valid_inventory_code
    assert_equal valid_inventory_code, @book_copy.inventory_code
  end

  test "normalizzazione collocazione della copia" do
    not_valid_location = " Collocazione 1 "
    valid_location = "Collocazione 1"
    @book_copy.location = not_valid_location
    assert_equal valid_location, @book_copy.location
  end

  test "libro non può essere vuoto" do
    book_copy = BookCopy.new(inventory_code: "FASFRAWE", location: "Location 1")
    assert_not book_copy.valid?
    assert book_copy.errors.added?(:book, :blank)
  end

  test "eliminazione di un copia con prestiti (anche chiusi) viene bloccata" do
    Loan.create!(book_copy: @book_copy, member: @member, started_on: Date.current, due_on: Date.current + 30)
    assert_no_difference("BookCopy.count") { @book_copy.destroy }
    assert @book_copy.errors.of_kind?(:base, "restrict_dependent_destroy.has_many".to_sym)
  end
end
