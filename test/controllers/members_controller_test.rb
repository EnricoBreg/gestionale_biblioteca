require "test_helper"

class MembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = members(:one)
    sign_in_as(users(:one))
  end

  test "senza login si viene mandati al login" do
    sign_out
    get members_url
    assert_redirected_to new_session_url
  end

  test "richiesta della pagina di index" do
    get members_url
    assert_response :success
  end

  test "richiesta pagina nuovo lettore" do
    get new_member_url
    assert_response :success
  end

  test "un nuovo lettore viene creato" do
    assert_difference("Member.count") do
      post members_url, params: {
        member: {
          email: "vale.rossi@example.com",
          first_name: "Valentino",
          last_name: "Rossi",
          tax_code: "AAABBB11C22D333E"
        }
      }
    end
    assert_redirected_to member_url(Member.last)
  end

  test "un lettore viene mostrato" do
    get member_url(@member)
    assert_response :success
  end

  test "richiesta modifica lettore" do
    get edit_member_url(@member)
    assert_response :success
  end

  test "un lettore viene aggiornato" do
    patch member_url(@member), params: {
      member: {
        email: "emailsempio@example.com",
        first_name: @member.first_name,
        last_name: @member.last_name,
        phone: @member.phone,
        tax_code: @member.tax_code
        }
      }
    assert_redirected_to member_url(@member)
  end

  test "elimina un lettore senza prestiti" do
    assert_difference("Member.count", -1) do
      delete member_url(members(:no_loans))
    end
    assert_redirected_to members_url
  end

  test "non elimina un lettore con prestiti" do
    assert_no_difference("Member.count") do
      delete member_url(members(:one))
    end
    assert_redirected_to member_url(members(:one))
    follow_redirect!
    assert_select "div.alert.error", text: "Impossibile eliminare: esistono prestiti collegati"
  end

  test "disattiva un lettore senza prestiti attivi" do
    assert_changes -> { members(:one).reload.active }, to: false do
      patch deactivate_member_url(members(:one))
    end
    assert_redirected_to member_url(members(:one))
  end

  test "non disattiva un lettore che ha prestiti attivi" do
    assert_no_changes -> { members(:two).reload.active } do
      patch deactivate_member_url(members(:two))
    end
    assert_redirected_to member_url(members(:two))
    follow_redirect!
    assert_select "div.alert.error", text: "Il lettore non può essere disattivato: ha prestiti in corso"
  end

  test "attivazione di un lettore disattivato" do
    assert_changes -> { members(:inactive).reload.active }, to: true do
      patch activate_member_url(members(:inactive))
    end
    assert_redirected_to member_url(members(:inactive))
    follow_redirect!
    assert_select "button.outline[type=submit]", text: "Disattiva"
  end

  test "disattivazione di un lettore attivo" do
    assert_changes -> { members(:no_loans).reload.active }, to: false do
      patch deactivate_member_url(members(:no_loans))
    end
    assert_redirected_to member_url(members(:no_loans))
    follow_redirect!
    assert_select "button.outline[type=submit]", text: "Riattiva"
  end

  test "active da form viene ignorato" do
    params = {
      member: {
        first_name: "Marco",
        active: true
      }
    }
    assert_no_changes -> { members(:inactive).reload.active } do
      put member_url(members(:inactive)), params: params
    end
    assert_redirected_to member_path(members(:inactive))
  end

  test "non viene creato un lettore non valido" do
    assert_no_difference("Member.count") do
      post members_url, params: {
        member: {
          first_name: "",
          last_name: "",
          tax_code: ""
        }
      }
    end
    assert_response :unprocessable_content
    assert_select "div.alert.error"
    assert_select "small.error"
  end

  test "la ricerca mostra solo i risultati e mostra il campo" do
    get members_url, params: { q: "bianchi" }
    assert_response :success
    assert_select "tbody tr", 1
    assert_select "input[name=q][value=?]", "bianchi"
  end

  test "ricerca senza risultati" do
    get members_url, params: { q: "XXXXXXXX" }
    assert_select "table", 0
    assert_select "p", "Nessun lettore trovato."
  end

  test "filtro sui soli lettori attivi" do
    get members_path, params: { status: "active" }
    assert_select "table"
    assert_select "tbody tr", text: /#{members(:inactive).full_name}/, count: 0
  end
end
