class Member < ApplicationRecord
  has_many :loans, dependent: :restrict_with_error
  has_many :open_loans, -> { open }, class_name: "Loan"

  scope :matching, ->(text) {
    if text.present?
      q = "%#{sanitize_sql_like(text.strip)}%"
      where(<<~SQL, q: q)
        (first_name || ' ' || last_name) ILIKE :q
        OR (last_name || ' ' || first_name) ILIKE :q
        OR tax_code ILIKE :q
        OR email ILIKE :q
        OR phone ILIKE :q
      SQL
    end
  }
  scope :with_status, ->(status) {
    case status
    when "all"      then all
    when "inactive" then where(active: false)
    when "active"   then where(active: true)
    else                 all
    end
  }
  scope :with_loans_count, -> { left_joins(:open_loans).group(:id)
                                  .select("members.*, COUNT(loans.id) AS loans_count") }

  normalizes :tax_code, with: ->(code) { code.strip.delete(" ").upcase }
  normalizes :email, with: ->(email) { email.strip.downcase.presence }
  normalizes :phone, with: ->(phone) { phone.strip.presence }

  validates :first_name, :last_name, presence: true
  validates :tax_code, presence: true, uniqueness: true, length: { is: 16 }
  validates :email, allow_blank: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :active, inclusion: { in: [ true, false ] }
  validate :no_open_loans_when_deactivating, if: -> { will_save_change_to_active?(to: false) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def self.search(filters)
    matching(filters[:q]).with_status(filters[:status])
  end

  private

  def no_open_loans_when_deactivating
    errors.add(:base, :has_open_loans) if loans.open.exists?
  end
end
