class BookCopy < ApplicationRecord
  belongs_to :book
  has_many :loans, dependent: :restrict_with_error
  has_one :current_loan, -> { open }, class_name: "Loan"

  normalizes :inventory_code, with: ->(inventory_code) { inventory_code.strip.delete(" ").upcase }
  normalizes :location, with: ->(location) { location.strip }

  validates :inventory_code, presence: true, uniqueness: true
  validates :location, presence: true
end
