class Admin::DayConditionsController < Admin::AdminController
  def index
    @day_conditions = DayCondition.order(:applicable_date, :wday)
    @days = Reservation::DAYS
    @initial_date = DayCondition.initial_date
  end

  def new
    @days = Reservation::DAYS
    if DayCondition.exists?
      # 2回目以降
      today = Date.current
      @day_conditions = DayCondition.order(applicable_date: :asc).group_by { |i| i.wday }
      @day_conditions.each do |wday, day_conditions|
        diff = (wday - today.wday) % 7
        next_occurring_date = today + diff.days
        index = (day_conditions.size - 1) - day_conditions.reverse.find_index { |day_condition| next_occurring_date >= day_condition.applicable_date }
        @day_conditions[wday] = day_conditions[index..]
      end
      @initial_date = DayCondition.initial_date
      render :new
    else
      # 初回
      render :first
    end
  end

  def create
    if DayCondition.exists?
      # 2回目以降
      DayCondition.transaction do
        new_day_condition_params.each do |new_day_condition_param|
          day_condition = DayCondition.find_or_initialize_by(new_day_condition_param.slice(:applicable_date, :wday))
          day_condition.assign_attributes(new_day_condition_param)
          day_condition.save!
        end

        affected_wdays = new_day_condition_params.map { |param| param["wday"].to_i }
        # 変更された曜日の内、applicable_date 以降で、予約が入っている日付の配列
        applicable_date = params[:applicable_date].to_date
        affected_dates = Reservation.where("date >= ?", applicable_date).distinct.pluck(:date).select do |date|
          date.wday.in?(affected_wdays)
        end

        affected_dates.each do |date|
          ReservationStatus.update_reservation_status!(date)
        end
      end
    else
      # 初回
      DayCondition.create!(first_day_condition_params)
    end
    redirect_to admin_day_conditions_path
  end

  def update
  end

  def destroy
    @day_condition = DayCondition.find(params[:id])
    if @day_condition.applicable_date == DayCondition.initial_date
      flash[:alert] = "初期設定の削除はできません。"
    else
      DayCondition.transaction do
        applicable_date = @day_condition.applicable_date
        @day_condition.destroy!
        affected_dates = Reservation.where("date >= ?", applicable_date).distinct.pluck(:date).select do |date|
          date.wday == applicable_date.wday
        end
        affected_dates.each do |date|
          ReservationStatus.update_reservation_status!(date)
        end
      end
    end
    redirect_to admin_day_conditions_path
  end

  private

  def first_day_condition_params
    add_param = params.permit(:applicable_date)
    params.require(:day_conditions).map do |param|
      param[:start_min] = param[:end_min] = nil if param[:open].nil?
      param.permit(:wday, :start_min, :end_min).merge add_param
    end
  end

  def new_day_condition_params
    add_param = params.permit(:applicable_date)
    edit_params = params.require(:day_conditions).select { |param| param[:edit].present? }
    edit_params.map do |param|
      param[:start_min] = param[:end_min] = nil if param[:open].nil?
      param.permit(:wday, :start_min, :end_min).merge add_param
    end
  end
end
