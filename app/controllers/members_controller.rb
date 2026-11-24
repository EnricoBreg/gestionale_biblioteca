class MembersController < ApplicationController
  before_action :set_member, only: %i[ edit update destroy activate deactivate ]

  # GET /members
  def index
    @members = Member.with_loans_count.search(params).order(:last_name, :first_name)
  end

  # GET /members/1
  def show
    @member = Member.includes(open_loans: { book_copy: :book }).find(params.expect(:id))
  end

  # GET /members/new
  def new
    @member = Member.new
  end

  # GET /members/1/edit
  def edit
  end

  # POST /members
  def create
    @member = Member.new(member_params)

    if @member.save
      redirect_to @member, notice: "Lettore creato con successo."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /members/1
  def update
    if @member.update(member_params)
      redirect_to @member, notice: "Lettore aggiornato con successo.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def activate
    if @member.update(active: true)
      redirect_to @member, notice: "Il lettore è stato attivato.", status: :see_other
    else
      redirect_to @member, alert: @member.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def deactivate
    if @member.update(active: false)
      redirect_to @member, notice: "Il lettore è stato disattivato.", status: :see_other
    else
      redirect_to @member, alert: @member.errors.full_messages.to_sentence, status: :see_other
    end
  end

  # DELETE /members/1
  def destroy
    if @member.destroy
      redirect_to members_path, notice: "Il lettore è stato eliminato con successo.", status: :see_other
    else
      redirect_to @member, alert: @member.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_member
      @member = Member.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def member_params
      params.expect(member: [ :first_name, :last_name, :tax_code, :email, :phone ])
    end
end
