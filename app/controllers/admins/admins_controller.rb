# app/controllers/admins/admins_controller.rb
class Admins::AdminsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_votes_hash

  def show
    @admin = Admin.find(params[:id])
    params[:view] ||= 'threads'
    @posts = @admin.posts.order(created_at: :desc)
    @comments = @admin.comments.includes(:post).order(created_at: :desc)
    set_votes_hash
  end

  def set_votes_hash
    if admin_signed_in?
      @votes_hash = current_admin.votes.index_by(&:post_id).transform_values(&:vote_type)
      @boosted_posts_ids = current_admin.boosts.pluck(:post_id)
      @boosted_posts = Post.where(id: @boosted_posts_ids)

    else
      @votes_hash = {}
      @boosted_posts = {}

    end
  end


  def boosted_posts
    @boosted_posts = Boost.where(admin: current_admin).includes(:post).map(&:post)
  end


  def sort
    @posts = Post.order_by(params[:sort_by])

    case params[:from]
    when "admin_show"
      # Asegúrate de definir todas las variables necesarias para esta vista.
      @admin = Admin.find(params[:admin_id]) # Asegúrate de pasar el admin_id de alguna manera.
      @comments = @admin.comments.includes(:post).order(created_at: :desc)
      render 'admins/admins/show'
    else
      render 'index'
    end
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
