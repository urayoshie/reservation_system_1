class PreventReservation < ApplicationRecord
  include PerUnitMin

  validates :date, presence: true
  validates :start_min, presence: true, numericality: Reservation::LIMIT_MIN_RANGE
  validates :end_min, presence: true, numericality: Reservation::LIMIT_MIN_RANGE
  # start_min は15の倍数
  validate :per_unit_start_min, :per_unit_end_min

  validate :amount_of_time

  TIME_ERROR_MESSAGE = "は終了時間より早い時間となります"

  def amount_of_time
    if start_min && end_min && start_min >= end_min
      errors.add(:start_min, TIME_ERROR_MESSAGE)
    end
  end
end
