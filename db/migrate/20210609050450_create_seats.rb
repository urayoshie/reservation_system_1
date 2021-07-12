class CreateSeats < ActiveRecord::Migration[6.1]
  def change
    create_table :seats do |t|
      t.string :name, null: false
      t.integer :type, null: false
      t.integer :number, null: false

      t.timestamps
    end
  end
end
