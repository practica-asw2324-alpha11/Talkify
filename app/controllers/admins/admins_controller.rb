# app/controllers/admins/admins_controller.rb
class Admins::AdminsController < ApplicationController
  before_action :authenticate_admin!

  def show
    @admin = Admin.find(params[:id])
    params[:view] ||= 'threads'
    @posts = @admin.posts.order(created_at: :desc)
    @comments = @admin.comments.includes(:post).order(created_at: :desc)

  end

  def edit
    @admin = Admin.find(params[:id])
  end

  def update
    @admin = Admin.find(params[:id])
    if @admin.update(admin_params)
      redirect_to admin_path(@admin), notice: 'Perfil actualizado con éxito.'
    else
      render :edit
    end
  end

  private
    def set_admin
       @admin = Admin.find(params[:id])
    end
    def admin_params
        params.require(:admin).permit(:email, :full_name, :description, :avatar_url, :background_image, :uid)

    end

end
