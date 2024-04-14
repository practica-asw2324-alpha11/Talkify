# app/controllers/admins/admins_controller.rb
class Admins::AdminsController < ApplicationController
  before_action :authenticate_admin!

  def show
    @admin = current_admin
  end
end
