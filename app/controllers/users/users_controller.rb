# app/controllers/users/users_controller.rb
class Users::UsersController < ApplicationController
  before_action :set_votes_hash
  before_action :set_user
  before_action :set_target_user, only: [:show, :user_comments, :user_posts, :user_boosts]

  def index
    @users = User.all
    render json: @users.as_json(except: [:uid, :api_key])
  end

  def show
    params[:view] ||= 'threads'
    @posts = @user_target.posts.order(created_at: :desc)
    @comments = @user_target.comments.order(created_at: :desc)

    # Calculate the counts
    comments_count = @user_target.comments.count
    posts_count = @user_target.posts.count

    # Only calculate boosts_count if the user is the same as @user
    boosts_count = @user == @user_target ? Boost.where(user: @user_target).count : nil

    @user = User.find(params[:id])

    set_votes_hash
    respond_to do |format|
      format.html
      format.json do
        user_json = @user.as_json(except: [:uid, :api_key]).merge({
          comments_count: comments_count,
          posts_count: posts_count
        })

        user_json[:boosts_count] = boosts_count unless boosts_count.nil?

        render json: user_json
      end
    end
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

    if request.content_type == "multipart/form-data" && @user == @user_target
      puts "User updating"
      puts request.content_type
      puts params
      @user.full_name = params[:full_name] if params[:full_name].present?
      @user.description = params[:description] if params[:description].present?
      if params[:avatar].present?
        @user.avatar.attach(params[:avatar])
      end
      if params[:background].present?
        @user.background.attach(params[:background])
      end
      if @user.save
        respond_to do |format|
          format.html { redirect_to @user }
          format.json { render json: @user, status: :ok }
        end
      else
        respond_to do |format|
          format.html { render :edit }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    elsif @user == @user_target
      if params[:user][:avatar].present?
        @user.avatar.attach(params[:user][:avatar])
      end
      if params[:user][:background].present?
        @user.background.attach(params[:user][:background])
      end
    end
  end

  def user_comments
    @user = User.find(params[:id])

    case params[:sort_by]
    when "top"
      @comments = @user.comments
                               .select('comments.*, (comments.upvote - comments.downvote) AS votes_difference')
                               .order('votes_difference DESC')
    when "newest"
      @comments = @user.comments.order(created_at: :desc)
    else
      @comments = @user.comments.order(created_at: :asc)
    end

    respond_to do |format|
      format.html { render 'user/show' }
      format.json { render json: @comments, include: :replies, status: :ok }
    end
  end

  def user_params
    params.require(:user).permit(:email, :full_name, :description, :uid)
  end

  def user_posts
    @user = User.find(params[:id])

    case params[:sort_by]
    when "top"
      @posts = @user.posts
                    .select('posts.*, (posts.upvotes - posts.downvotes) AS votes_difference')
                    .order('votes_difference DESC')
    when "newest"
      @posts = @user.posts.order(created_at: :desc)
    else
      @posts = @user.posts.order(created_at: :asc)
    end

    respond_to do |format|
      format.html { render 'user/show' }
      format.json { render json: @posts, status: :ok }
    end
  end

  def user_boosts

    if @user == @user_target
      @boosted_posts = Boost.where(user: @user).includes(:post).map(&:post)
      response = { "boosted_posts" => @boosted_posts }
      status = :ok
    else
      response = { "error" => "You can only see the boosts of your own user." }
      status = :forbidden
    end

    respond_to do |format|
      format.html { render 'user/show' }
      format.json { render json: response, status: status }
    end
  end

  private

  def set_user
    if request.headers[:Accept] == "application/json"
      api_key = request.headers[:HTTP_X_API_KEY]

      if api_key.nil?
        render :json => { "status" => "401", "error" => "No Api key provided." }, status: :unauthorized and return
      else
        @user = User.find_by_api_key(api_key)
        if @user.nil?
          render :json => { "status" => "403", "error" => "No User found with the Api key provided." }, status: :unauthorized and return
        end
      end
    else
      @user = current_user
    end
  end

  def set_target_user
    @user_target = User.find_by(id: params[:id])
    if @user_target.nil?
      render json: { "error" => "User not found" }, status: :not_found and return
    end
  end

end
