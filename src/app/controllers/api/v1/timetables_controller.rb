require 'time'
require 'date'

class Api::V1::TimetablesController < ApplicationController

  def index(datetime=DateTime.now.to_s)
    @date = params[:datetime] ? Date.parse(params[:datetime]) : Date.parse(datetime)
    @time = params[:datetime] ? Time.parse(params[:datetime]) : Time.parse(datetime)
    @limit = params[:limit] ? params[:limit] : 3

    if !params[:to].blank?
      @course = Course.find_by(arrival_id: params[:to])
    elsif  !params[:from].blank?
      @course = Course.find_by(departure_id: params[:from])
    else
      return render json: { success: false, errors: '' }, status: :unprocessable_entity
    end
    
    begin
      @timetables = DateSet.find_by(date: @date).timetable_set.timetables.where("course_id = ? AND departure_time >= ?", @course.id, @time ).limit(@limit)
      render json: { success: true, timetables: @timetables, course: JSON.parse(@course.to_json(:include => [:arrival, :departure]) ) }, status: :ok
    rescue => exception
      render json: { success: false, errors: '416 Range Not Satisfiable. Perhaps bus timetable is not defined in this date.' }, status: :requested_range_not_satisfiable  
    end
  rescue => e
    render json: { success: false, errors: '500 internal error. Please contact the administrator.' }, status: :internal
  end

  def internal(datetime = DateTime.now.to_s)
    expires_now
    @date =  params[:datetime] ? Date.parse(params[:datetime]) : Date.parse(datetime)
    @time = params[:datetime] ? Time.parse(params[:datetime]) : Time.parse(datetime)
    @limit = params[:limit] ? params[:limit] : 2

    course_ids = DateSet.find_by(date: @date).timetable_set.timetables.group(:course_id).select(:course_id)
    
    @timetables = []
    for c in course_ids do
      @timetables << {
        departure: Course.find(c.course_id).departure,
        arrival: Course.find(c.course_id).arrival,
        timetables: DateSet.find_by(date: @date).timetable_set.timetables.where("course_id = ? AND departure_time >= ?", c.course_id, @time ).limit(2)
      }
    end
    @timetables = @timetables.uniq

    render json: { success: true, data: @timetables }, status: :ok
  end

  private

  def get_timetable_params(params)
    params.permit(:key, :from, :to, :datetime, :limit)
  end

end
