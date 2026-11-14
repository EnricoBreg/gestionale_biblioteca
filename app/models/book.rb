class Book < ApplicationRecord
  has_many :book_copies, dependent: :restrict_with_error
  has_many :loans, through: :book_copies

  normalizes :isbn, with: ->(isbn) { isbn.strip.delete("-").delete(" ").upcase }

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: true
  validates :publication_year, numericality: {
    only_integer: true,
    greater_than: 0,
    less_than_or_equal_to: -> { Date.current.year }
  }
  validates :category, presence: true
  validates :author, presence: true
end
