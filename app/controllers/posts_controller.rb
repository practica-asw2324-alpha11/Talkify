class PostsController < ApplicationController
before_action :set_votes_hash
before_action :set_post, only: [:show, :edit, :update, :destroy,  :upvote, :downvote, :boost], except: [:search]


   def set_votes_hash
    if admin_signed_in?
      @comment_votes_hash = current_admin.comment_votes.index_by(&:comment_id).transform_values(&:vote_type)
      @votes_hash = current_admin.votes.index_by(&:post_id).transform_values(&:vote_type)
      @boosted_posts = current_admin.boosts.pluck(:post_id)

    else
      @votes_hash = {}
      @comment_votes_hash = {}
      @boosted_posts = {}

    end
  end



def boost
    @post = Post.find(params[:id])
    @boost = Boost.find_or_initialize_by(post: @post, admin: current_admin)

    if @boost.new_record?
      @boost.save!
    else
      @boost.destroy!
    end
    respond_to do |format|
    format.html { redirect_back(fallback_location: root_path) }
    format.json { head :no_content }
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
  if admin_signed_in?
    ActiveRecord::Base.transaction do
      @vote = @post.votes.find_or_initialize_by(admin: current_admin)

      if @vote.new_record?
        @vote.vote_type = 'upvote'
        @vote.save!
      elsif @vote.vote_type == 'downvote'
        @vote.destroy!
        @post.votes.create!(admin: current_admin, vote_type: 'upvote')
      elsif @vote.vote_type == 'upvote'
        @vote.destroy!
      end
    end
  end

  respond_to do |format|
    format.html { redirect_back(fallback_location: root_path) }
    format.json { head :no_content }
  end
end



def downvote
  if admin_signed_in?
    ActiveRecord::Base.transaction do
    @vote = @post.votes.find_or_initialize_by(admin: current_admin)

      if @vote.new_record?
        @vote.vote_type = 'downvote'
        @vote.save!
      elsif @vote.vote_type == 'upvote'
        @vote.destroy!
        @post.votes.create!(admin: current_admin, vote_type: 'downvote')
      elsif @vote.vote_type == 'downvote'
        @vote.destroy!
      end
    end
  end

 respond_to do |format|
    format.html { redirect_back(fallback_location: root_path) }
    format.json { head :no_content }
  end
  end



def sort
  @posts = Post.order_by(params[:sort_by])
  render :index
end

def search
  @query = params[:query]
  @posts = Post.where("title LIKE :query OR body LIKE :query", query: "%#{@query}%")
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

end

    # GET /posts/1 or /posts/1.json
    def show
      @post = Post.find(params[:id])
      @comment = @post.comments.build
      @comments = @post.comments.includes(:replies)
    end


  def new
    @post = Post.new(link: params[:link] == 'true')
    @magazines = Magazine.all.order(:name)  # Asumiendo que cada revista tiene un atributo 'name'

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

    # POST /posts or /posts.json
    def create
      @post = Post.new(post_params)
      @post.admin_id = current_admin.id

      respond_to do |format|
        if @post.save
          format.html { redirect_to root_path, notice: "Post was successfully created." }
          format.json { render :index, status: :created, location: @post }
        else
          format.html { redirect_to root_path, notice: @post.errors.full_messages.join(", ") }
          format.json { render json: @post.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /posts/1 or /posts/1.json
    def update
      respond_to do |format|
        if @post.update(post_params)
          format.html { redirect_to post_url(@post), notice: "Post was successfully updated." }
          format.json { render :show, status: :ok, location: @post }
        else
          flash.now[:alert] = 'URL cannot be blank for a link post.' if @post.errors[:url].include?("can't be blank")
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @post.errors, status: :unprocessable_entity }

        end
      end
    end

    # DELETE /posts/1 or /posts/1.json
    def destroy
      @post.destroy
      respond_to do |format|
        format.html { redirect_to posts_url, notice: "Post was successfully destroyed." }
        format.json { head :no_content }
      end
    end

    private
     def set_post
       @post = Post.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def post_params
        params.require(:post).permit(:title, :url, :body, :link, :magazine_id)

      end
  end
