class Book < ApplicationRecord
  has_many :book_copies, dependent: :restrict_with_error
  has_many :loans, through: :book_copies

  scope :with_isbn_code,    ->(isbn) { where(isbn: isbn) if isbn.present? }
  scope :title_like,        ->(text) { where("books.title ILIKE ?", "%#{sanitize_sql_like(text.strip)}%") if text.present? }
  scope :of_category,       ->(category) { where(category: category) if category.present? }
  scope :author_like,       ->(author) { where("books.author ILIKE ?", "%#{sanitize_sql_like(author.strip)}%") if author.present? }
  scope :with_copies_count, -> { left_joins(:book_copies).group(:id)
                                  .select("books.*, COUNT(book_copies.id) AS copies_count") }

  normalizes :title, with: ->(title) { title.strip }
  normalizes :isbn, with: ->(isbn) { isbn.strip.delete("-").delete(" ").upcase }
  normalizes :author, with: ->(author) { author.strip }
  normalizes :category, with: ->(category) { category.strip }

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
    with_isbn_code(filters[:isbn])
      .title_like(filters[:title])
      .of_category(filters[:category])
      .author_like(filters[:author])
  end

  def self.categories
    distinct.order(:category).pluck(:category)
  end
end
