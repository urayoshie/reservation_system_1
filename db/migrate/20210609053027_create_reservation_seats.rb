class CreateReservationSeats < ActiveRecord::Migration[6.1]
  def change
    create_table :reservation_seats do |t|
      t.references :reservation, null: false, foreign_key: true
      t.references :seat, null: false, foreign_key: true

      t.timestamps
    end
    add_index :reservation_seats, [:reservation_id, :seat_id], unique: true
  end
end
