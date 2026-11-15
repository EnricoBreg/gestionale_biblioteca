require "test_helper"

class LoanTest < ActiveSupport::TestCase
  setup do
    @book = books(:one)
    @book_copy = @book.book_copies.first
    @member = members(:one)
  end

  test "data inizio deve essere presente" do
    loan = Loan.new(book_copy: @book_copy, member: @member, due_on: Date.current)
    assert_not loan.valid?
    # Riga lasciata per conoscenza, in caso dovesse servire in futuro
    # puts loan.errors.details.inspect
    assert loan.errors.added?(:started_on, :blank)
  end

  test "data scadenza deve essere presente" do
    loan = Loan.new(book_copy: @book_copy, member: @member, started_on: Date.current)
    assert_not loan.valid?
    assert loan.errors.added?(:due_on, :blank)
  end

  test "lettore deve essere presente" do
    loan = Loan.new(book_copy: @book_copy, started_on: Date.current, due_on: Date.current + 30)
    assert_not loan.valid?
    assert loan.errors.added?(:member, :blank)
  end

test "copia del libro deve essere presente" do
    loan = Loan.new(member: @member, started_on: Date.current, due_on: Date.current)
    assert_not loan.valid?
    assert loan.errors.added?(:book_copy, :blank)
  end

  test "data scadenza non precedente a data inizio prestito" do
    loan = Loan.new(book_copy: @book_copy, member: @member, started_on: Date.current, due_on: Date.current - 1)
    assert_not loan.valid?
    assert loan.errors.added?(:due_on, :cannot_precede_started_on)
  end

  test "data scadenza uguale a data inizio prestito" do
    loan = Loan.new(book_copy: @book_copy, member: @member, started_on: Date.current, due_on: Date.current)
    assert loan.valid?
    assert_not loan.errors.added?(:due_on, :cannot_precede_started_on)
  end

  test "data restituzione non precedente a data inizio" do
    loan = Loan.new(book_copy: @book_copy, member: @member, started_on: Date.current, due_on: Date.current + 30, returned_on: Date.current - 1)
    assert_not loan.valid?
    assert loan.errors.added?(:returned_on, :cannot_precede_started_on)
  end

  test "data restituzione uguale a data inizio prestito" do
    loan = Loan.new(book_copy: @book_copy, member: @member, started_on: Date.current, due_on: Date.current + 30, returned_on: Date.current)
    assert loan.valid?
    assert_not loan.errors.added?(:returned_on, :cannot_precede_started_on)
  end

  test "il lettore deve essere attivo al momento del prestito" do
    @member.update!(active: false) # aggiornamento del flag prima della creazione del prestito
    loan = Loan.new(book_copy: @book_copy, member: @member, started_on: Date.current, due_on: Date.current + 30)
    assert_not loan.valid?
    assert loan.errors.added?(:member, :inactive)
  end

  test "dopo la restituzione la copia può essere prestata di nuovo" do
    first_loan = Loan.create!(book_copy: @book_copy, member: @member, started_on: Date.current, due_on: Date.current + 30)
    first_loan.update!(returned_on: Date.current)

    second_loan = Loan.new(book_copy: @book_copy, member: @member, started_on: Date.current, due_on: Date.current + 30)
    assert second_loan.valid?
  end

  test "una copia non può avere due prestiti in corso" do
    Loan.create!(book_copy: @book_copy, member: @member, started_on: Date.current, due_on: Date.current + 30)
    second_loan = Loan.new(book_copy: @book_copy, member: @member, started_on: Date.current, due_on: Date.current + 30)

    assert_not second_loan.valid?
    assert second_loan.errors.of_kind?(:book_copy_id, :taken)
  end

  test "una copia non può avere due prestiti in corso (validazioni saltate)" do
    Loan.create!(book_copy: @book_copy, member: @member, started_on: Date.current, due_on: Date.current + 30)
    second_loan = Loan.new(book_copy: @book_copy, member: @member, started_on: Date.current, due_on: Date.current + 30)

    assert_raises(ActiveRecord::RecordNotUnique) do
      second_loan.save(validate: false)
    end
  end
end
