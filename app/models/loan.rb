class Loan < ApplicationRecord
  belongs_to :book_copy
  belongs_to :member

  scope :open, -> { where(returned_on: nil) }
  scope :closed, -> { where.not(returned_on: nil) }
  scope :overdue, -> { open.where(due_on: ...Date.current) }
  scope :ongoing, -> { open.where(due_on: Date.current..) }

  validates :started_on, :due_on, presence: true
  validates :book_copy_id, uniqueness: {
    conditions: -> { open },
    message: :already_lent
  }, unless: :returned_on?
  validate :due_on_not_before_started_on
  validate :returned_on_not_before_started_on
  validate :member_must_be_active, on: :create

  STATUSES = %i[ ongoing closed overdue ].freeze

  def status
    return :closed if returned_on.present?
    due_on < Date.current ? :overdue : :ongoing
  end

  STATUSES.each do |s|
    define_method(:"#{s}?") { status == s }
  end

  def human_status
    self.class.human_status(status)
  end

  def self.human_status(value)
    I18n.t(value, scope: "activerecord.attributes.loan.statuses")
  end

  private

  def due_on_not_before_started_on
    return if started_on.blank? || due_on.blank?
    errors.add(:due_on, :cannot_precede_started_on) if due_on < started_on
  end

  def returned_on_not_before_started_on
    return if returned_on.blank? || started_on.blank?
    errors.add(:returned_on, :cannot_precede_started_on) if returned_on < started_on
  end

  def member_must_be_active
    return if member.nil?
    errors.add(:member, :inactive) unless member.active?
  end
end
