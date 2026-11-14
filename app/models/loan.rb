class Loan < ApplicationRecord
  belongs_to :book_copy
  belongs_to :member

  scope :ongoing, -> { where(returned_on: nil) }

  validates :started_on, :due_on, presence: true
  validates :book_copy_id, uniqueness: {
    conditions: -> { where(returned_on: nil) },
    message: "è già in prestito"
  }, unless: :returned_on?
  validate :due_on_not_before_started_on
  validate :returned_on_not_before_started_on
  validate :member_must_be_active, on: :create

  private

  def due_on_not_before_started_on
    return if started_on.blank? || due_on.blank?
    errors.add(:due_on, "non può precedere la data di inizio") if due_on < started_on
  end

  def returned_on_not_before_started_on
    return if returned_on.blank? || started_on.blank?
    errors.add(:returned_on, "non può precedere la data di inizio") if returned_on < started_on
  end

  def member_must_be_active
    return if member.nil?
    errors.add(:member, "non è attivo") unless member.active?
  end
end
