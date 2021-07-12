class Reservation < ApplicationRecord
  include PerUnitMin

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  VALID_PHONE_NUMBER_REGEX = /\A0\d{1,3}-?\d{2,4}-?\d{3,4}\z/

  UNIT_MIN = ConvertTime::UNIT_MIN  # 15
  LIMITE_UNITS = 8
  LIMIT_MAX_MIN = 1680
  LIMIT_MIN_RANGE = { greater_than_or_equal_to: 0, less_than_or_equal_to: Reservation::LIMIT_MAX_MIN }

  MAXIMUM_GUEST_NUMBER = 12
  ACCEPTABLE_PRIVATE_NUMBER = 6
  RESERVED_MIN = UNIT_MIN * LIMITE_UNITS
  DEFAULT_START_MIN = 900
  DEFAULT_END_MIN = 1500
  DAYS = %w[日 月 火 水 木 金 土]

  # 予約できる期間
  PERIOD_MONTH = 3.months

  PAST_ERROR_MESSAGE = "は本日以降の日付を選択してください"
  PAST_MONTHS_ERROR_MESSAGE = "は本日より#{PERIOD_MONTH.in_months.round}ヶ月未満の日付を選択してください"
  CLOSED_MESSAGE = "は営業日を選択してください"
  CLOSED_HOURS_MESSAGE = "は営業時間内で選択してください"
  UNIT_MESSAGE = "は#{UNIT_MIN}分ごとの時間を選択してください"
  UNDER_LIMIT_UNITE_MESSAGE = "と終了時間は#{UNIT_MIN * LIMITE_UNITS}分以上の間隔を空けてください。"

  validates :guest_number, :date, presence: true
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX }
  validates :phone_number, presence: true, format: { with: VALID_PHONE_NUMBER_REGEX }
  validates :request, length: { maximum: 300 }
  validates :start_min, presence: true, numericality: LIMIT_MIN_RANGE

  has_many :reservation_seats, dependent: :destroy

  # 本日以前の日付は入らないようにする
  validate :date_before_start
  # 本日から3ヶ月目以降の日付は入らないようにする
  validate :past_date
  # start_min は15の倍数
  validate :per_unit_start_min
  # date が 営業日 かつ start_min が 開始時間〜終了時間(15×8 分前) かつ 15分区切り であること
  validate :within_business_hours

  def start_time
    ConvertTime.to_time(start_min)
  end

  def start_datetime
    date.in_time_zone + start_min.minutes
  end

  ###### バリデーション ######
  def date_before_start
    if date < Date.current
      errors.add(:date, PAST_ERROR_MESSAGE)
    end
  end

  def past_date
    if date > Date.current + PERIOD_MONTH
      errors.add(:date, PAST_MONTHS_ERROR_MESSAGE)
    end
  end

  def within_business_hours
    open_min, closed_min = Reservation.fetch_business_hours(date)
    if open_min.nil? || closed_min.nil?
      errors.add(:start_min, CLOSED_MESSAGE) and return
    end

    limit_min = closed_min - RESERVED_MIN
    chosen_min = self.start_min

    if open_min > chosen_min || chosen_min > limit_min
      errors.add(:start_min, CLOSED_HOURS_MESSAGE)
    end
  end

  ###### クラスメソッド ######
  class << self
    # 引数の日付の「営業時間」を取得するメソッド
    def fetch_business_hours(date)
      temporary_date = TemporaryDate.find_by(date: date)
      if temporary_date
        return [temporary_date[:start_min], temporary_date[:end_min]]
      end

      business_day = DayCondition.order(applicable_date: :desc).where(wday: date.wday).find_by("applicable_date <= ?", date)
      if business_day
        return [business_day[:start_min], business_day[:end_min]]
      end
      [nil, nil]
    end

    # start_date から end_date までの営業日の配列を取得
    def calc_business_dates(start_date, end_date)
      dates = (start_date..end_date).to_a
      # 規定営業日の配列
      default_business_dates = DayCondition.default_business_dates(start_date, end_date)
      # 臨時営業日の配列
      temporary_business_dates = TemporaryDate.business_dates(start_date, end_date)
      # 臨時休業日の配列
      temporary_closed_dates = TemporaryDate.closed_dates(start_date, end_date)

      ((default_business_dates + temporary_business_dates).uniq - temporary_closed_dates).sort
      # 営業日
      # DayCondition.where("applicable_date <= ?", end_date).order(applicable_date: :asc).group_by { |i| i.wday }.each do |wday, conditions|
      # end

      # closed_days = (DayCondition::DAY_LIST.to_a - DayCondition.distinct.pluck(:wday)) + DayCondition.where(start_min: nil).where("applicable_date <= ?", end_date).distinct.pluck(:wday)
      # closed_dates = dates.select { |date| date.wday.in?(closed_days) }
      # default_closed_dates = DayCondition.where(date: start_date..end_date, start_min: nil, wday: 3)
      # [start_date..end_date].to_a - temporary_closed_dates - default_closed_dates
    end

    # 予約人数と貸切予約かどうかの1日単位(15:00~24:45)の配列ハッシュデータ
    def reserve_list(date, exclude_reservation_id = nil)
      open_min, closed_min = fetch_business_hours(date)

      # 休業日の場合は空配列を返す
      if open_min.nil? || closed_min.nil?
        message = "休業日に対して、 reserve_list メソッドが動作しました。"
        OutputLog.error(
          date: date,
          open_min: open_min,
          closed_min: closed_min,
          message: message,
        )
        raise message
      end

      reservation_list = []
      total_units = ConvertTime.total_units(open_min, closed_min)
      total_units.times do
        reservation_list << { total_number: 0, private_reservation: false }
      end

      where(date: date).where.not(id: exclude_reservation_id).each do |reservation|
        diff_minutes = reservation.start_min - open_min
        start_unit = ConvertTime.min_to_unit(diff_minutes)
        if start_unit < 0 || start_unit > total_units - LIMITE_UNITS
          message = "予約可能ではない時間に予約が入っています。"
          OutputLog.error(
            reservation_id: reservation.id,
            date: date,
            start_min: reservation.start_min,
            open_min: open_min,
            closed_min: closed_min,
            message: message,
          )
          raise message
        end

        LIMITE_UNITS.times do |i|
          reservation_params = reservation_list[start_unit + i]
          if reservation.guest_number >= ACCEPTABLE_PRIVATE_NUMBER
            if reservation_params[:private_reservation]
              # 貸切の二重予約があったとき
              reservation_params[:error] = true
            elsif reservation_params[:total_number] > 0
              # 予約があるのに貸切しようとしたとき
              reservation_params[:error] = true
            else
              reservation_params[:private_reservation] = true
            end
          end

          reservation_params[:total_number] += reservation.guest_number

          # 予約人数がオーバーしているとき
          if reservation_params[:total_number] > MAXIMUM_GUEST_NUMBER
            reservation_params[:error] = true
          end
        end
      end

      reservation_list
    end

    # 1日(15:00~23:00)2時間単位での予約最大人数と貸切予約の有無の配列ハッシュデータ
    def biggest_num_list(datetime, exclude_reservation_id = nil)
      reservation_list = reserve_list(datetime, exclude_reservation_id)

      biggest_number_list = []

      (reservation_list.size - LIMITE_UNITS + 1).times do |i|
        list = reservation_list.slice(i..(i + LIMITE_UNITS - 1))

        biggest_number = list.max_by { |k| k[:total_number] }[:total_number]

        private_reservation = list.any? { |data| data[:private_reservation] }
        error = list.any? { |data| data[:error] }
        biggest_number_list << { biggest_number: biggest_number, private_reservation_exists: private_reservation, error: error }
      end
      biggest_number_list
    end

    # 1日あたりの15:00~23:00の15分単位での予約受付の真偽判定
    def display_available_time(datetime, guest_number, exclude_reservation_id = nil)
      # array = reservable_num_list(datetime)
      reservable_array = []
      # biggest_num_list(datetime)

      biggest_num_list(datetime, exclude_reservation_id).map do |data|
        reservable_number = MAXIMUM_GUEST_NUMBER - data[:biggest_number]
        reservable_array << (guest_number <= reservable_number && !data[:private_reservation_exists])
      end

      reservable_array
    end

    # ����切予約���出来るかどうかの真偽配列
    def choose_private_reservation(datetime, exclude_reservation_id = nil)
      reservable_private_reservation = []
      biggest_num_list(datetime, exclude_reservation_id).map do |data|
        reservable_private_reservation << data[:biggest_number].zero?
      end
      reservable_private_reservation
    end

    def reservable_list(datetime, guest_number, exclude_reservation_id = nil)
      # 6人以上なら貸切用の��ソッド, 6人未満�������ら人数用のメソッド
      if guest_number >= 6
        choose_private_reservation(datetime, exclude_reservation_id)
      else
        display_available_time(datetime, guest_number, exclude_reservation_id)
      end
    end

    # 本日日から3ヶ月までの期間、予約可能な日付を文字列で配列に格納
    def show_string_date(guest_number)
      start_date = Date.current
      end_date = start_date + PERIOD_MONTH

      # 営業日
      business_dates = calc_business_dates(start_date, end_date)

      # 予約出来ない日の配列
      not_available_date_list = if guest_number < ACCEPTABLE_PRIVATE_NUMBER
          # guest_number が５以下のとき、予約できない日付の配列
          # minimum_total_num がどの範囲なら予約できないか？ => minimum_total_num + guest_num > MAXIMUM_GUEST_NUMBER
          ReservationStatus.where("minimum_total_num > ?", MAXIMUM_GUEST_NUMBER - guest_number).where(date: business_dates).pluck(:date)
        else
          # 貸切（guest_number が6以上）のとき、予約できない日付の配列
          ReservationStatus.where(date: business_dates).pluck(:date)
        end

      business_dates - not_available_date_list
    end

    def calc_available_time(date, guest_number, exclude_reservation_id = nil)
      available_time = []

      # 人数を選択した場合(1日あたりの15:00~23:00の15分単位での予約受入の真偽判定)
      boolean_list = Reservation.reservable_list(date, guest_number, exclude_reservation_id)
      open_min, closed_min = Reservation.fetch_business_hours(date)
      time = date.beginning_of_day + open_min.minutes
      boolean_list.each do |boolean|
        if date == Date.today
          if boolean && time > Time.current
            available_time << time.strftime("%H:%M")
          end
        else
          available_time << time.strftime("%H:%M") if boolean
        end
        time += 15.minute
      end

      available_time
    end
  end
end
