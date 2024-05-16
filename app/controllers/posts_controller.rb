class PostsController < ApplicationController
  before_action :set_user
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
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { render json: { post: @post, boost_status: boost_status } }
    end
  end

  def unboost
    @post = Post.find(params[:id])
    @boost = Boost.find_by(post: @post, user: @user)

    if @boost.present?
      @boost.destroy!
      boost_status = "unboosted"
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { render json: { post: @post, boost_status: boost_status } }
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
  ActiveRecord::Base.transaction do
    @vote = @post.votes.find_or_initialize_by(user: @user)

    if @vote.new_record?
      @vote.vote_type = 'upvote'
      @vote.save!
    elsif @vote.vote_type == 'downvote'
      @vote.destroy!
      @post.votes.create!(user: @user, vote_type: 'upvote')
    elsif @vote.vote_type == 'upvote'
      @vote.destroy!
    end
  end

  respond_to do |format|
    format.html { redirect_back(fallback_location: root_path) }
    format.json { render json: { "status" => "200", "message" => "Vote successfully added." }, status: :ok }
  end
end

  def downvote
    ActiveRecord::Base.transaction do
      @vote = @post.votes.find_or_initialize_by(user: @user)

      if @vote.new_record?
        @vote.vote_type = 'downvote'
        @vote.save!
      elsif @vote.vote_type == 'upvote'
        @vote.destroy!
        @post.votes.create!(user: @user, vote_type: 'downvote')
      elsif @vote.vote_type == 'downvote'
        @vote.destroy!
      end
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { render json: { "status" => "200", "message" => "Vote successfully added." }, status: :ok }
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
    @posts = Post.where(link: true).order(created_at: :desc)
  when "threads"
    @posts = Post.where(link: false).order(created_at: :desc)
  else
    @posts = Post.order(created_at: :desc)
  end

  if params[:sort_by].present?
    @posts = Post.order_by(params[:sort_by])
  end

  respond_to do |format|
    format.html # Renderizará el HTML por defecto
    format.json { render json: @posts, include: { comments: { include: :replies} } } # Renderizará los posts en formato JSON
  end
end

  def show
    @post = Post.find(params[:id])
    @comment = @post.comments.build
    @comments = @post.comments.includes(:replies)

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
    render :json => { "status" => "405", "error" => "Only the creator can complete this action." }, status: :unauthorized and return
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
      render :json => { "status" => "405", "error" => "Only the creator can complete this action." }, status: :unauthorized and return
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
