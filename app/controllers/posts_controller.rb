class PostsController < ApplicationController
before_action :set_post, only: [:show, :edit, :update, :destroy, :upvote, :downvote]
before_action :set_post, only: [:show, :edit, :update, :destroy,  :upvote, :downvote], except: [:search]

    def like
      @post.likes += 1
      @post.save

      respond_to do |format|
        format.html { redirect_to root_path }
        format.json { head :no_content }
      end
    end

def upvote
  @post.votes.create(user: current_user, vote_type: 'upvote')
  redirect_to @post, notice: 'Upvoted!'
end

def downvote
  @post.votes.create(user: current_user, vote_type: 'downvote')
  redirect_to @post, notice: 'Downvoted!'
end




 def sort
  @posts = Post.order_by(params[:sort_by])
  render 'index'
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
  end

    def new_link
      @post = Post.new(link: true)
    end

    def new_thread
      @post = Post.new(link: false)
    end
    def edit

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
        params.require(:post).permit(:title, :url, :body, :link)
      end
  end
