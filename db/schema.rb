# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_06_10_010243) do

  create_table "admin_users", charset: "utf8mb4", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
  end

  create_table "day_conditions", charset: "utf8mb4", force: :cascade do |t|
    t.date "applicable_date", null: false
    t.integer "wday", null: false
    t.integer "start_min"
    t.integer "end_min"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["applicable_date", "wday"], name: "index_day_conditions_on_applicable_date_and_wday", unique: true
  end

  create_table "holidays", charset: "utf8mb4", force: :cascade do |t|
    t.date "date", null: false
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["date"], name: "index_holidays_on_date", unique: true
  end

  create_table "menus", charset: "utf8mb4", force: :cascade do |t|
    t.integer "position"
    t.integer "genre", null: false
    t.string "name", null: false
    t.string "price", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "notifications", charset: "utf8mb4", force: :cascade do |t|
    t.string "title", null: false
    t.text "content", null: false
    t.string "image"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "prevent_reservations", charset: "utf8mb4", force: :cascade do |t|
    t.date "date", null: false
    t.integer "start_min", null: false
    t.integer "end_min", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "reservation_seats", charset: "utf8mb4", force: :cascade do |t|
    t.bigint "reservation_id", null: false
    t.bigint "seat_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["reservation_id", "seat_id"], name: "index_reservation_seats_on_reservation_id_and_seat_id", unique: true
    t.index ["reservation_id"], name: "index_reservation_seats_on_reservation_id"
    t.index ["seat_id"], name: "index_reservation_seats_on_seat_id"
  end

  create_table "reservation_statuses", charset: "utf8mb4", force: :cascade do |t|
    t.integer "minimum_total_num", null: false
    t.date "date", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["date"], name: "index_reservation_statuses_on_date", unique: true
  end

  create_table "reservations", charset: "utf8mb4", force: :cascade do |t|
    t.integer "guest_number", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone_number", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "request"
    t.integer "start_min", null: false
    t.date "date", null: false
  end

  create_table "seats", charset: "utf8mb4", force: :cascade do |t|
    t.string "name", null: false
    t.integer "type", null: false
    t.integer "number", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "temporary_dates", charset: "utf8mb4", force: :cascade do |t|
    t.date "date", null: false
    t.integer "start_min"
    t.integer "end_min"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "holiday_id"
    t.index ["date"], name: "index_temporary_dates_on_date", unique: true
    t.index ["holiday_id"], name: "index_temporary_dates_on_holiday_id"
  end

  add_foreign_key "reservation_seats", "reservations"
  add_foreign_key "reservation_seats", "seats"
  add_foreign_key "temporary_dates", "holidays"
end
