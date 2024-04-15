# app/controllers/admins/admins_controller.rb
class Admins::AdminsController < ApplicationController
  before_action :authenticate_admin!

  def show
    @admin = Admin.find(params[:id])
  end
end
