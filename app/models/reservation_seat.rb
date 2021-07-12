class ReservationSeat < ApplicationRecord
  belongs_to :reservation
  belongs_to :seat

  validates :reservstion_id, uniqueness: {
                               scope: :seat_id,
                               message: "は同じテーブルに2つ以上の予約はできません",
                             }

  def update_reservation_seat!(reservation)
    if reservation.guest_num <= 3
      reservation.status_min
      reservation.reservation_seats.create!(seat_id: seat_id)
    end
    # reservation_seat を作成すれば良い
    # seat_id の決め方が問題
    # guest_num が 3名以下なら, counter, table の順序で 決定
    # guest_num が 4名, 5名なら, table を２箇所確保,
    # reservation.reservation_seats.create!(seat_id: seat_id)
  end
end
