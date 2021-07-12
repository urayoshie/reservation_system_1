class Seat < ApplicationRecord
  validates :name, presence: true
  validates :type, presence: true
  validates :number, presence: true
  has_many :reservation_seats, dependent: :destroy

  enum type: {
    counter: 0,
    table: 1,
  }
end
