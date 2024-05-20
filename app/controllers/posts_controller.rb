class PostsController < ApplicationController
  before_action :set_user, except: [:index, :show, :search]
  before_action :set_votes_hash
  before_action :set_post, only: [:show, :edit, :update, :destroy, :upvote, :downvote, :boost], except: [:search]

  def set_votes_hash
    if user_signed_in?
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
      response = { post: @post, boost_status: boost_status }
    else
      boost_status = "already boosted"
      status = :conflict
      response = { boost_status: boost_status }
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { render json: response, status: status }
    end
  end

  def unboost
    @post = Post.find(params[:id])
    @boost = Boost.find_by(post: @post, user: @user)

    if @boost.present?
      @boost.destroy!
      boost_status = "unboosted"
      status = :ok
      response = { boost_status: boost_status }
    else
      boost_status = "not boosted"
      status = :conflict
      response = { boost_status: boost_status }
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { render json: response, status: status }
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

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { render json: { "status" => status, "message" => message }, status: status }
    end
  end

  def downvote
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

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { render json: { "status" => status, "message" => message }, status: status }
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
          render json: @posts
        else
          render json: { error: "There are no posts that match the query" }, status: :not_found
        end
      end
    end
  end

 def index
  case params[:filter]
  when "links"
    @posts = Post.where(link: true).order_by(params[:sort_by] ? params[:sort_by] : [:created_at, :desc])
  when "threads"
    @posts = Post.where(link: false).order_by(params[:sort_by] ? params[:sort_by] : [:created_at, :desc])
  else
    @posts = Post.order(created_at: :desc)
  end
  @posts = @posts.as_json(methods: [:upvotes_count, :downvotes_count, :comments_count])

  respond_to do |format|
    format.html
    format.json { render json: @posts }
  end
end

  def show
    @post = Post.find(params[:id])
    if request.headers[:Accept] != "application/json"
      @comment = @post.comments.build
    end
    @comments = @post.comments.includes(:replies)
    @post = @post.as_json(methods: [:upvotes_count, :downvotes_count, :comments_count])

    respond_to do |format|
      format.html # Renderizará el HTML por defecto
      format.json { render json: @post, include: { comments: { include: :replies} } } # Renderizará los posts en formato JSON
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
