class CreatePreventReservations < ActiveRecord::Migration[6.1]
  def change
    create_table :prevent_reservations do |t|
      t.date :date, null: false
      t.integer :start_min, null: false
      t.integer :end_min, null: false

      t.timestamps
    end
  end
end
