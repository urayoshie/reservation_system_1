require "date"
require "csv"

%w[reservations reservation_statuses menus day_conditions temporary_dates].each do |table_name|
  ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table_name}")
end

# 座席の種類
seats_params = [
  { name: "counter-1", type: 0, number: 3 },
  { name: "counter-2", type: 0, number: 3 },
  { name: "counter-2", type: 0, number: 3 },
  { name: "table-1", type: 1, number: 4 },
  { name: "table-2", type: 1, number: 4 },
  { name: "table-3", type: 1, number: 4 },
]


# 規定の営業・休業
# date4 = Date.new(2021, 5, 10)
# DayCondition.create!(applicable_date: date4, wday: 3, start_min: nil, end_min: nil)

date = Date.new(2021, 6, 4)
DayCondition.create!(applicable_date: date, wday: 0, start_min: 690, end_min: 1500)
DayCondition.create!(applicable_date: date, wday: 1, start_min: 900, end_min: 1500)
DayCondition.create!(applicable_date: date, wday: 2, start_min: nil, end_min: nil)
DayCondition.create!(applicable_date: date, wday: 3, start_min: 900, end_min: 1500)
DayCondition.create!(applicable_date: date, wday: 4, start_min: 900, end_min: 1500)
DayCondition.create!(applicable_date: date, wday: 5, start_min: 900, end_min: 1500)
DayCondition.create!(applicable_date: date, wday: 6, start_min: 690, end_min: 1500)

date2 = Date.new(2021, 7, 10)
DayCondition.create!(applicable_date: date2, wday: 0, start_min: 900, end_min: 1200)
DayCondition.create!(applicable_date: date2, wday: 3, start_min: nil, end_min: nil)

date3 = Date.new(2021, 8, 1)
DayCondition.create!(applicable_date: date3, wday: 3, start_min: 900, end_min: 1500)

# date4 = Date.new(2021, 7, 1)
# DayCondition.create!(applicable_date: date4, wday: 3, start_min: 900, end_min: 1200)

# temporary_dates
# 臨時営業日
TemporaryDate.create!(date: Date.new(2021, 7, 23), start_min: 660, end_min: 1500)
TemporaryDate.create!(date: Date.new(2021, 8, 10), start_min: 690, end_min: 1500)
# 臨時休業日
TemporaryDate.create!(date: Date.new(2021, 8, 13), start_min: nil, end_min: nil)
TemporaryDate.create!(date: Date.new(2021, 8, 14), start_min: nil, end_min: nil)
TemporaryDate.create!(date: Date.new(2021, 8, 15), start_min: nil, end_min: nil)

puts "デフォルトの営業日データを投入しました。"

reservation_params = [
  # 一般予約のみ(7月2日金曜)
  { date: "2021-07-02", start_min: 900, guest_number: 1 }, # 15:00:00
  { date: "2021-07-02", start_min: 915, guest_number: 2 }, # 15:15:00
  { date: "2021-07-02", start_min: 930, guest_number: 3 }, # 15:30:00
  { date: "2021-07-02", start_min: 945, guest_number: 4 }, # 15:45:00
  { date: "2021-07-02", start_min: 960, guest_number: 2 }, # 16:00:00
  { date: "2021-07-02", start_min: 1035, guest_number: 3 }, # 17:15:00
  { date: "2021-07-02", start_min: 1065, guest_number: 2 }, # 17:45:00
  { date: "2021-07-02", start_min: 1080, guest_number: 4 }, # 18:00:00
  { date: "2021-07-02", start_min: 1155, guest_number: 1 }, # 19:15:00
  { date: "2021-07-02", start_min: 1170, guest_number: 2 }, # 19:30:00
  { date: "2021-07-02", start_min: 1185, guest_number: 2 }, # 19:45:00
  { date: "2021-07-02", start_min: 1200, guest_number: 4 }, # 20:00:00
  { date: "2021-07-02", start_min: 1290, guest_number: 3 }, # 21:30:00
  { date: "2021-07-02", start_min: 1305, guest_number: 1 }, # 21:45:00
  { date: "2021-07-02", start_min: 1320, guest_number: 1 }, # 22:00:00
  { date: "2021-07-02", start_min: 1380, guest_number: 4 }, # 23:00:00
  # 貸切予約がある場合(7月3日土曜)
  { date: "2021-07-03", start_min: 1020, guest_number: 4 }, # 17:00:00
  { date: "2021-07-03", start_min: 1050, guest_number: 4 }, # 17:30:00
  { date: "2021-07-03", start_min: 1080, guest_number: 4 }, # 18:00:00
  { date: "2021-07-03", start_min: 1200, guest_number: 1 }, # 20:00:00
  { date: "2021-07-03", start_min: 1230, guest_number: 4 }, # 20:30:00
  { date: "2021-07-03", start_min: 1260, guest_number: 2 }, # 21:00:00
  { date: "2021-07-03", start_min: 1380, guest_number: 6 }, # 23:00:00
  # 予約多くて予約日として選択できないケース(7月4日日曜)
  { date: "2021-07-04", start_min: 900, guest_number: 6 }, # 15:00:00
  { date: "2021-07-04", start_min: 1020, guest_number: 4 }, # 17:00:00
  { date: "2021-07-04", start_min: 1050, guest_number: 4 }, # 17:30:00
  { date: "2021-07-04", start_min: 1080, guest_number: 4 }, # 18:00:00
  { date: "2021-07-04", start_min: 1140, guest_number: 2 }, # 19:00:00
  { date: "2021-07-04", start_min: 1170, guest_number: 3 }, # 19:30:00
  { date: "2021-07-04", start_min: 1200, guest_number: 1 }, # 20:00:00
  { date: "2021-07-04", start_min: 1215, guest_number: 2 }, # 20:15:00
  { date: "2021-07-04", start_min: 1230, guest_number: 4 }, # 20:30:00
  { date: "2021-07-04", start_min: 1260, guest_number: 2 }, # 21:00:00
  { date: "2021-07-04", start_min: 1380, guest_number: 8 }, # 23:00:00
  # # 予約人数選択後、予約日を選択し、予約人数を変更した時に選べる人数と選べない人数が出るケース(7月5日月曜)
  { date: "2021-07-05", start_min: 900, guest_number: 4 }, # 15:00:00
  { date: "2021-07-05", start_min: 930, guest_number: 4 }, # 15:30:00
  { date: "2021-07-05", start_min: 1020, guest_number: 5 }, # 17:00:00
  { date: "2021-07-05", start_min: 1170, guest_number: 1 }, # 19:30:00
  { date: "2021-07-05", start_min: 1260, guest_number: 2 }, # 21:00:00
  { date: "2021-07-05", start_min: 1290, guest_number: 5 }, # 21:30:00
  { date: "2021-07-05", start_min: 1320, guest_number: 2 }, # 22:00:00
  { date: "2021-07-05", start_min: 1380, guest_number: 2 }, # 23:00:00
  # 貸切予約がある場合(8月4日水曜)
  { date: "2021-08-04", start_min: 1020, guest_number: 4 }, # 17:00:00
  { date: "2021-08-04", start_min: 1050, guest_number: 4 }, # 17:30:00
  { date: "2021-08-04", start_min: 1080, guest_number: 4 }, # 18:00:00
  { date: "2021-08-04", start_min: 1200, guest_number: 1 }, # 20:00:00
  { date: "2021-08-04", start_min: 1230, guest_number: 4 }, # 20:30:00
  { date: "2021-08-04", start_min: 1260, guest_number: 2 }, # 21:00:00
  { date: "2021-08-04", start_min: 1380, guest_number: 6 }, # 23:00:00
  # 予約多くて予約日として選択できないケース(8月5日木曜)
  { date: "2021-08-05", start_min: 900, guest_number: 6 }, # 15:00:00
  { date: "2021-08-05", start_min: 1020, guest_number: 4 }, # 17:00:00
  { date: "2021-08-05", start_min: 1050, guest_number: 4 }, # 17:30:00
  { date: "2021-08-05", start_min: 1080, guest_number: 4 }, # 18:00:00
  { date: "2021-08-05", start_min: 1140, guest_number: 2 }, # 19:00:00
  { date: "2021-08-05", start_min: 1170, guest_number: 3 }, # 19:30:00
  { date: "2021-08-05", start_min: 1200, guest_number: 1 }, # 20:00:00
  { date: "2021-08-05", start_min: 1215, guest_number: 2 }, # 20:15:00
  { date: "2021-08-05", start_min: 1230, guest_number: 4 }, # 20:30:00
  { date: "2021-08-05", start_min: 1260, guest_number: 2 }, # 21:00:00
  { date: "2021-08-05", start_min: 1380, guest_number: 8 }, # 23:00:00
  # 予約人数選択後、予約日を選択し、予約人数を変更した時に選べる人数と選べない人数が出るケース(8月7日土曜)
  { date: "2021-08-07", start_min: 900, guest_number: 4 }, # 15:00:00
  { date: "2021-08-07", start_min: 930, guest_number: 4 }, # 15:30:00
  { date: "2021-08-07", start_min: 1020, guest_number: 5 }, # 17:00:00
  { date: "2021-08-07", start_min: 1170, guest_number: 1 }, # 19:30:00
  { date: "2021-08-07", start_min: 1260, guest_number: 2 }, # 21:00:00
  { date: "2021-08-07", start_min: 1290, guest_number: 5 }, # 21:30:00
  { date: "2021-08-07", start_min: 1320, guest_number: 2 }, # 22:00:00
  { date: "2021-08-07", start_min: 1380, guest_number: 2 }, # 23:00:00
  # 臨時営業日
  { date: "2021-08-10", start_min: 1020, guest_number: 6 }, # 23:00:00
]

reservation_params.map! do |reservation|
  reservation.merge(
    name: "tarou yamada",
    email: "hoge@example.com",
    phone_number: "09099999999",
  )
end

Reservation.create!(reservation_params)

puts "予約のインポートに成功しました！"

ADMIN_EMAIL = "admin@example.com"
PASSWORD = "password"

AdminUser.find_or_create_by!(email: ADMIN_EMAIL) do |admin_user|
  admin_user.password = PASSWORD
  puts "管理者ユーザーの初期データインポートに成功しました。"
end

CSV.foreach("db/csv_data/menu.csv", headers: true) do |row|
  Menu.create!(row)
end
puts "メニューのインポートに成功しました！"

# reservation_statuses テーブルを最新の状態に更新
system("rails reservation:update_reservation_status")
