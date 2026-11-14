class Member < ApplicationRecord
  has_many :loans, dependent: :restrict_with_error

  normalizes :tax_code, with: ->(code) { code.strip.delete(" ").upcase }
  normalizes :email, with: ->(email) { email.strip.downcase.presence }
  normalizes :phone, with: ->(phone) { phone.strip.presence }

  validates :first_name, :last_name, presence: true
  validates :tax_code, presence: true, uniqueness: true, length: { is: 16 }
  validates :email, allow_blank: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :active, inclusion: { in: [ true, false ] }
  validate :no_ongoing_loans_when_deactivating, if: -> { will_save_change_to_active?(to: false) }

  private

  def no_ongoing_loans_when_deactivating
    errors.add(:active, "ha prestiti in corso") if loans.ongoing.exists?
  end
end
