require "test_helper"

class MemberTest < ActiveSupport::TestCase
  setup do
    @member = members(:two)
  end

  test "normalizzazione tax code" do
    valid_tax_code = "BRGNRC98A18D058V"
    not_valid_tax_code = "  Brg NRC 98A18D058V  "
    @member.tax_code = not_valid_tax_code
    assert_equal valid_tax_code, @member.tax_code
  end

  test "normalizzazione indirizzo email" do
    valid_email_address = "esempiomail@email.com"
    not_valid_email_address = "  ESEMPIOMAIL@EMAIL.COM  "
    @member.email = not_valid_email_address
    assert_equal valid_email_address, @member.email
  end

  test "normalizzazione numero di telefono" do
    valid_phone_number = "3338087889"
    not_valid_phone_number = "  3338087889  "
    @member.phone = not_valid_phone_number
    assert_equal valid_phone_number, @member.phone
  end

  test "nome deve essere presente" do
    @member.first_name = nil
    assert_not @member.valid?
    assert @member.errors.added?(:first_name, :blank)
  end

  test "nome non deve essere vuoto" do
    @member.first_name = ""
    assert_not @member.valid?
    assert @member.errors.added?(:first_name, :blank)
  end

  test "cognome deve essere presente" do
    @member.last_name = nil
    assert_not @member.valid?
    assert @member.errors.added?(:last_name, :blank)
  end

  test "cognome non deve essere vuoto" do
    @member.last_name = ""
    assert_not @member.valid?
    assert @member.errors.added?(:last_name, :blank)
  end

  test "tax code deve essere presente" do
    @member.tax_code = nil
    assert_not @member.valid?
    assert @member.errors.added?(:tax_code, :blank)
  end

  test "tax code non deve essere vuoto" do
    @member.tax_code = ""
    assert_not @member.valid?
    assert @member.errors.added?(:tax_code, :blank)
  end

  test "tax code deve essere unico" do
    tax_code = "YGNMGJ13P48D049O"
    Member.create!(first_name: "Mario", last_name: "Rossi", tax_code: tax_code, email: "mario.rossi@email.com", active: true)
    member = Member.new(first_name: "Mario", last_name: "Verdi", tax_code: tax_code, email: "mario.verdi@email.com", active: true)
    assert_not member.valid?
    assert member.errors.of_kind?(:tax_code, :taken)
  end

  test "tax code deve essere esatttamente 16 caratteri" do
    too_long_tax_code = "YGNMGJ13P48D049OZ" # 17 caratteri
    member = Member.new(first_name: "Mario", last_name: "Verdi", tax_code: too_long_tax_code, email: "mario.verdi@email.com", active: true)
    assert_not member.valid?
    assert member.errors.of_kind?(:tax_code, :wrong_length)

    too_short_tax_code = "YGNMGJ13P48D04" # 14 caratteri
    member = Member.new(first_name: "Mario", last_name: "Verdi", tax_code: too_short_tax_code, email: "mario.verdi@email.com", active: true)
    assert_not member.valid?
    assert member.errors.of_kind?(:tax_code, :wrong_length)
   end

  test "email deve essere unica" do
    email_address = "esempio@email.com"
    Member.create!(first_name: "Mario", last_name: "Rossi", tax_code: "YGNMGJ13P48D049O", email: email_address, active: true)
    member = Member.new(first_name: "Mario", last_name: "Verdi", tax_code: "YGNMGJ13P48D0491", email: email_address, active: true)
    assert_not member.valid?
    assert member.errors.of_kind?(:email, :taken)
  end

  test "email deve essere del formato giusto" do
    not_valid_email_address = "esempioemail.com"
    member = Member.new(first_name: "Mario", last_name: "Verdi", tax_code: "YGNMGJ13P48D0491", email: not_valid_email_address, active: true)
    assert_not member.valid?
    assert member.errors.of_kind?(:email, :invalid)
  end

  test "active deve valere solo true o false" do
    @member.active = nil
    assert_not @member.valid?
    assert @member.errors.of_kind?(:active, :inclusion)
  end

  test "disattivazione permessa con prestiti chiusi" do
    member = members(:one)
    assert member.update(active: false)
    assert_not member.reload.active?
  end

  test "disattivazione bloccata con prestiti attivi" do
    assert_not @member.update(active: false)
    assert @member.errors.added?(:base, :has_open_loans)
    assert @member.reload.active?
  end

  test "il % è un carattere normale" do
    assert_empty Member.search(q: "%")
  end

  test "basta un campo per trovare il lettore" do
    sarah = members(:two) # Sarah Smith SMTSRH26M45D095W s.smith@email.com +39 3524849665
    [ "sarah", "sarah smith", "smith sarah", "  smtsrh  ", "smith@email", "3524849665" ].each do |text|
      assert_includes Member.search(q: text), sarah, "non trovata cercando #{text.inspect}"
    end
  end

  test "concatenazione nome e cognome vale solo per lo stesso" do
    # Sarah Smith SMTSRH26M45D095W s.smith@email.com +39 3524849665
    [ "sarah doe", "doe sarah" ].each do |text|
      assert_empty Member.search(q: text), "trovato cercando #{text.inspect}"
    end
  end

  test "ricerca per q vuoto restituisce tutti" do
    assert_equal Member.all.count, Member.search(q: "   ").count
  end

  test "ricerca per status non valido fallback su default" do
    assert_equal Member.all.count, Member.search(status: "not_valid").count
  end

  test "disattivazione bloccata con prestiti scaduti" do
    member = members(:one)
    member.loans.create!(book_copy: book_copies(:one),
                          started_on: Date.current - 10,
                          due_on: Date.current - 3) # prestito scaduto

    assert_not member.update(active: false)
    assert member.errors.added?(:base, :has_open_loans)
    assert member.reload.active?
  end

  test "filtro di ricerca per stato all trova tutti" do
    assert_includes Member.search(status: "all"), members(:one)
    assert_includes Member.search(status: "all"), members(:inactive)
  end

  test "ricerca con filtro di stato attivi" do
    assert_includes Member.search(status: "active"), members(:one)
    assert_not_includes Member.search(status: "active"), members(:inactive)
  end

  test "ricerca con filtro di stato non attivi" do
    assert_includes Member.search(status: "inactive"), members(:inactive)
    assert_not_includes Member.search(status: "inactive"), members(:one)
  end

  test "il filtro di stato vale anche sui risultati trovati per nome" do
    assert_not_includes Member.search(q: "bianchi", status: "active"), members(:inactive)
    assert_includes Member.search(q: "bianchi"), members(:inactive)
  end

  test "senza stato compaiono anche i disattivati" do
    assert_includes Member.search({}), members(:inactive)
  end
end
