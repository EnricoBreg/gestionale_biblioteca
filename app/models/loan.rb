class Loan < ApplicationRecord
  belongs_to :book_copy
  belongs_to :member
end
