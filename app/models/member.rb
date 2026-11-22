class Member < ApplicationRecord
  has_many :loans, dependent: :restrict_with_error

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

  private

  def no_open_loans_when_deactivating
    errors.add(:base, :has_open_loans) if loans.open.exists?
  end
end
