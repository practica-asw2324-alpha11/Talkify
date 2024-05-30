class PostsController < ApplicationController
  before_action :set_user
  before_action :set_votes_hash
  before_action :set_post, only: [:show, :edit, :update, :destroy, :upvote, :downvote, :boost], except: [:search]

  def set_votes_hash
    if @user.present?
      @comment_votes_hash = @user.comment_votes.index_by(&:comment_id).transform_values(&:vote_type)
      @votes_hash = @user.votes.index_by(&:post_id).transform_values(&:vote_type)
      @boosted_posts = @user.boosts.pluck(:post_id)
    elsif user_signed_in?
      @comment_votes_hash = current_user.comment_votes.index_by(&:comment_id).transform_values(&:vote_type)
      @votes_hash = current_user.votes.index_by(&:post_id).transform_values(&:vote_type)
      @boosted_posts = current_user.boosts.pluck(:post_id)
    else
      @votes_hash = {}
      @comment_votes_hash = {}
      @boosted_posts = {}
    end
  end


 def boost
  @post = Post.find(params[:id])
  @boost = Boost.find_or_initialize_by(post: @post, user: @user)

  if @boost.new_record?
    @boost.save!
    boost_status = "boosted"
    status = :ok
  else
    boost_status = "already boosted"
    status = :conflict
  end

  post_json = @post.as_json(
    methods: [:upvotes_count, :downvotes_count, :comments_count],
    except: [:magazine_id, :user_id]
  ).merge(
    is_upvoted: @post.is_upvoted(@user),
    is_downvoted: @post.is_downvoted(@user),
    is_boosted: @post.is_boosted(@user)
  )

  post_json[:magazine] = @post.magazine.as_json(only: [:id, :title, :description]) if @post.magazine.present?
  post_json[:user] = @post.user.as_json(only: [:id, :full_name, :email]) if @post.user.present?

  respond_to do |format|
    format.html { redirect_back(fallback_location: root_path) }
    format.json { render json: { post: post_json, boost_status: boost_status }, status: status }
  end
end


def unboost
  @post = Post.find(params[:id])
  @boost = Boost.find_by(post: @post, user: @user)

  if @boost.present?
    @boost.destroy!
    boost_status = "unboosted"
    status = :ok
  else
    boost_status = "not boosted"
    status = :conflict
  end

  post_json = @post.as_json(
    methods: [:upvotes_count, :downvotes_count, :comments_count],
    except: [:magazine_id, :user_id]
  ).merge(
    is_upvoted: @post.is_upvoted(@user),
    is_downvoted: @post.is_downvoted(@user),
    is_boosted: @post.is_boosted(@user)
  )

  post_json[:magazine] = @post.magazine.as_json(only: [:id, :title, :description]) if @post.magazine.present?
  post_json[:user] = @post.user.as_json(only: [:id, :full_name, :email]) if @post.user.present?

  respond_to do |format|
    format.html { redirect_back(fallback_location: root_path) }
    format.json { render json: { post: post_json, boost_status: boost_status }, status: status }
  end
end


  def like
    @post.likes += 1
    @post.save

    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { head :no_content }
    end
  end

def upvote
  @post = Post.find(params[:id])
  message = ''
  ActiveRecord::Base.transaction do
    @vote = @post.votes.find_or_initialize_by(user: @user)

    if @vote.new_record? && request.method == "POST"
      @vote.vote_type = 'upvote'
      @vote.save!
      status = :ok
      message = "Vote successfully added."
    elsif @vote.new_record? && request.method == "DELETE"
      status = :conflict
      message = "No vote found to delete."
    elsif @vote.vote_type == 'downvote'
      @vote.destroy!
      @post.votes.create!(user: @user, vote_type: 'upvote')
      status = :ok
      message = "Vote successfully changed to upvote."
    elsif @vote.vote_type == 'upvote' && request.method == "POST"
      status = :conflict
      message = "Already upvoted."
    elsif @vote.vote_type == 'upvote' && request.method == "DELETE"
      @vote.destroy!
      status = :ok
      message = "Vote successfully removed."
    end
  end

  post_json = @post.as_json(
    methods: [:upvotes_count, :downvotes_count, :comments_count],
    except: [:magazine_id, :user_id]
  ).merge(
    is_upvoted: @post.is_upvoted(@user),
    is_downvoted: @post.is_downvoted(@user),
    is_boosted: @post.is_boosted(@user)
  )

  post_json[:magazine] = @post.magazine.as_json(only: [:id, :title, :description]) if @post.magazine.present?
  post_json[:user] = @post.user.as_json(only: [:id, :full_name, :email]) if @post.user.present?

  respond_to do |format|
    format.html { redirect_back(fallback_location: root_path) }
    format.json { render json: { post: post_json, status: status, message: message }, status: status }
  end
end



 def downvote
  @post = Post.find(params[:id])
  message = ''
  ActiveRecord::Base.transaction do
    @vote = @post.votes.find_or_initialize_by(user: @user)

    if @vote.new_record? && request.method == "POST"
      @vote.vote_type = 'downvote'
      @vote.save!
      status = :ok
      message = "Vote successfully added."
    elsif @vote.new_record? && request.method == "DELETE"
      status = :conflict
      message = "No vote found to delete."
    elsif @vote.vote_type == 'downvote' && request.method == "DELETE"
      @vote.destroy!
      status = :ok
      message = "Vote successfully removed."
    elsif @vote.vote_type == 'upvote' && request.method == "DELETE"
      status = :conflict
      message = "No downvote found to delete."
    elsif @vote.vote_type == 'upvote'
      @vote.destroy!
      @post.votes.create!(user: @user, vote_type: 'downvote')
      status = :ok
      message = "Vote successfully changed to downvote."
    elsif @vote.vote_type == 'downvote' && request.method == "POST"
      status = :conflict
      message = "Already downvoted."
    end
  end

  post_json = @post.as_json(
    methods: [:upvotes_count, :downvotes_count, :comments_count],
    except: [:magazine_id, :user_id]
  ).merge(
    is_upvoted: @post.is_upvoted(@user),
    is_downvoted: @post.is_downvoted(@user),
    is_boosted: @post.is_boosted(@user)
  )

  post_json[:magazine] = @post.magazine.as_json(only: [:id, :title, :description]) if @post.magazine.present?
  post_json[:user] = @post.user.as_json(only: [:id, :full_name, :email]) if @post.user.present?

  respond_to do |format|
    format.html { redirect_back(fallback_location: root_path) }
    format.json { render json: { post: post_json, status: status, message: message }, status: status }
  end
end



  def sort
    @posts = Post.order_by(params[:sort_by])
    render :index
  end

  def search
    @query = params[:query]
    @posts = Post.where("title LIKE :query OR body LIKE :query", query: "%#{@query}%")

     respond_to do |format|
      format.html
      format.json do
        if @posts.present?
          @posts = @posts.map do |post|
        post_json = post.as_json(methods: [:upvotes_count, :downvotes_count, :comments_count], except: [:magazine_id, :user_id]).merge(
          is_upvoted: post.is_upvoted(@user),
          is_downvoted: post.is_downvoted(@user),
          is_boosted: post.is_boosted(@user)
        )

        if post.magazine.present?
          post_json[:magazine] = post.magazine.as_json(only: [:id, :title, :description])
        end

        if post.user.present?
          post_json[:user] = post.user.as_json(only: [:id, :full_name, :email])
        end

        post_json
      end
        render json: { posts: @posts }
        else
          render json: { error: "There are no posts that match the query" }, status: :not_found
        end
      end
    end
  end

 def index
 @posts = Post.all

      # Aplicar filtro si está presente
      case params[:filter]
      when "links"
        @posts = @posts.where(link: true)
      when "threads"
        @posts = @posts.where(link: false)
      end

      # Aplicar ordenación si está presente
      if params[:sort_by]
        @posts = @posts.order_by(params[:sort_by])
      else
        @posts = @posts.order_by(created_at: :desc)
      end

  respond_to do |format|
    format.html
    format.json do
      @posts = @posts.map do |post|
        post_json = post.as_json(methods: [:upvotes_count, :downvotes_count, :comments_count], except: [:magazine_id, :user_id]).merge(
          is_upvoted: post.is_upvoted(@user),
          is_downvoted: post.is_downvoted(@user),
          is_boosted: post.is_boosted(@user)
        )

        if post.magazine.present?
          post_json[:magazine] = post.magazine.as_json(only: [:id, :title, :description])
        end

        if post.user.present?
          post_json[:user] = post.user.as_json(only: [:id, :full_name, :email])
        end

        post_json
      end
      render json: { posts: @posts }
    end
  end
end


 def show
  @post = Post.find(params[:id])

  respond_to do |format|
    format.html do
      if request.headers[:Accept] != "application/json"
        @comment = @post.comments.build
      end
      @comments = @post.comments.includes(:replies)
    end

    format.json do
      post_json = @post.as_json(
        methods: [:upvotes_count, :downvotes_count, :comments_count],
        except: [:magazine_id, :user_id]
      ).merge(
        is_upvoted: @post.is_upvoted(@user),
        is_downvoted: @post.is_downvoted(@user),
        is_boosted: @post.is_boosted(@user)
      )

      if @post.magazine.present?
        post_json[:magazine] = @post.magazine.as_json(only: [:id, :title, :description])
      end

      if @post.user.present?
        post_json[:user] = @post.user.as_json(only: [:id, :full_name, :email])
      end

      render json: { post: post_json, comments: { include: :replies } }
    end
  end
end


  def new
    @post = Post.new(link: params[:link] == 'true')
    @magazines = Magazine.all.order(:name)
  end

  def new_link
    @post = Post.new(link: true)
    @magazines = Magazine.all.order(:name)  # Asumiendo que cada revista tiene un atributo 'name'
  end

  def new_thread
    @post = Post.new(link: false)
    @magazines = Magazine.all.order(:name)  # Asumiendo que cada revista tiene un atributo 'name'
  end

  def edit
    @magazines = Magazine.all
  end


 def create

    @post = Post.new(post_params)
    @post.link = post_params[:url].present?
    @post.user_id = @user.id
    @magazines = Magazine.all # o cualquier otra lógica para obtener las revistas disponibles

      respond_to do |format|
    if @post.save
      format.html do
        redirect_to_previous_page
      end
      format.json { render json: @post }
    else
      format.json { render json: @post.errors, status: :unprocessable_entity }
    end
  end
end


def update
  if @post.user != @user
    render :json => { "status" => "403", "error" => "Only the creator can complete this action." }, status: :forbidden and return
  end
  @magazines = Magazine.all # o cualquier otra lógica para obtener las revistas disponibles

  respond_to do |format|
    if @post.update(post_params)
      if request.headers[:Accept] != "application/json"
        format.html { redirect_to post_url(@post), notice: "Post was successfully updated." }
      end
      format.json { render json: @post }
    else
      flash.now[:alert] = 'URL cannot be blank for a link post.' if @post.errors[:url].include?("can't be blank")
      if request.headers[:Accept] != "application/json"
        format.html { render :edit, status: :unprocessable_entity }
      end
      format.json { render json: @post.errors, status: :unprocessable_entity }
    end
  end
end


  def destroy
    if @post.user != @user
      render :json => { "status" => "403", "error" => "Only the creator can complete this action." }, status: :forbidden and return
    end
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_url, notice: "Post was successfully destroyed." }
      format.json { render json: { "status" => "200", "message" => "Post successfully destroyed." }, status: :ok }
    end
  end


  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :url, :body, :link, :magazine_id)
  end

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


  def redirect_to_previous_page
  if request.referrer.present? && request.referrer != request.original_url
    redirect_back(fallback_location: root_path)
  else
    redirect_to root_path # Si no hay una página anterior, redirige a la página de inicio
  end
end

end
