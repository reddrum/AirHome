class ReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reservation, only: [:approve, :decline]

  def create
    room = Room.find(params[:room_id])

    if current_user == room.user
      flash[:alert] = "You cannot book your own property!"
    else
      start_date = Date.parse(reservation_params[:start_date])
      end_date = Date.parse(reservation_params[:end_date])
      days = (end_date - start_date).to_i + 1

      @reservation = current_user.reservations.build(reservation_params)
      @reservation.room = room
      @reservation.price = room.price
      # @reservation.total = room.price * days
      # @reservation.save

      @reservation.total = room.price * (days - special_dates.count)
      special_dates.each do |date|
        @reservation.total += date.price
      end

      if @reservation.Waiting!
        if room.Request?
          flash[:notice] = "Request sent successfully!"
        else
          charge(room, @reservation)
        end
      else
        flash[:alert] = "Cannot make a reservation!"
      end

    end
    redirect_to room
  end

  def your_trips
    @trips = current_user.reservations.order(start_date: :asc)
  end

  def your_reservations
    @rooms = current_user.rooms
  end

  def approve
    charge(@reservation.room, @reservation)
    redirect_to your_reservations_path
  end

  def decline
    @reservation.Declined!
    redirect_to your_reservations_path
  end
  
  private

    def set_reservation
      @reservation = Reservation.find(params[:id])
    end

    def reservation_params
      params.require(:reservation).permit(:start_date, :end_date)
    end
end
