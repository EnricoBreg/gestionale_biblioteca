class Book < ApplicationRecord
  has_many :book_copies, dependent: :restrict_with_error
  has_many :loans, through: :book_copies

  scope :with_isbn_code, ->(isbn) { where(isbn: isbn) if isbn.present? }
  scope :title_like, ->(text) { where("title ILIKE ?", "%#{sanitize_sql_like(text)}%") if text.present? }
  scope :of_category, ->(category) { where(category: category) if category.present? }

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

  def self.search(filters)
    with_isbn_code(filters[:isbn_code])
      .title_like(filters[:title])
      .of_category(filters[:category])
  end

  def self.categories
    distinct.order(:category).pluck(:category)
  end
end
