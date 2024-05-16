# app/controllers/users/users_controller.rb
class Users::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_votes_hash


  def show
    @user = User.find(params[:id])
    params[:view] ||= 'threads'
    @posts = @user.posts.order(created_at: :desc)
    @comments = @user.comments.order(created_at: :desc)
    set_votes_hash

  end

  def set_votes_hash
    if user_signed_in?
      @votes_hash = current_user.votes.index_by(&:post_id).transform_values(&:vote_type)
      @boosted_posts_ids = current_user.boosts.pluck(:post_id)
      @boosted_posts = Post.where(id: @boosted_posts_ids)
      @comment_votes_hash = current_user.comment_votes.index_by(&:comment_id).transform_values(&:vote_type)

    else
      @votes_hash = {}
      @boosted_posts = {}
      @comment_votes_hash = {}

    end
  end


  def boosted_posts
    @boosted_posts = Boost.where(user: current_user).includes(:post).map(&:post)
  end


  def sort
    @posts = Post.order_by(params[:sort_by])

    case params[:from]
    when "user_show"
      # Asegúrate de definir todas las variables necesarias para esta vista.
      @user = User.find(params[:user_id]) # Asegúrate de pasar el user_id de alguna manera.
      @comments = @user.comments.includes(:post).order(created_at: :desc)
      render 'users/users/show'
    else
      render 'index'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id]) # Asegúrate de cargar @user primero.

    if params[:user][:avatar].present?
      @user.avatar.attach(params[:user][:avatar])
    end

    if params[:user][:background].present?
      @user.background.attach(params[:user][:background])
    end
  end


  def user_params
    params.require(:user).permit(:email, :full_name, :description, :uid)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

end
