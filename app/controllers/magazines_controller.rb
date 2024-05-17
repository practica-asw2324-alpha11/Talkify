class MagazinesController < ApplicationController
    before_action :set_user
    before_action :set_votes_hash
    before_action :set_magazine, only: %i[show update]

    def subscribe
      @magazine = Magazine.find(params[:id])
      if @user.magazines.include?(@magazine)
        respond_to do |format|
          format.html { redirect_to @magazine, notice: "You are already subscribed." }
          format.json { render json: { "status" => "409", "message" => "Already subscribed." }, status: :conflict }
        end
      else
        @user.magazines << @magazine
        respond_to do |format|
          format.html { redirect_to @magazine }
          format.json { render json: { "status" => "200", "message" => "Successfully subscribed." }, status: :ok }
        end
      end
    end

    def unsubscribe
      @magazine = Magazine.find(params[:id])
      if @user.magazines.include?(@magazine)
        @user.magazines.delete(@magazine)
        respond_to do |format|
          format.html { redirect_to magazines_path }
          format.json { render json: { "status" => "200", "message" => "Successfully unsubscribed." }, status: :ok }
        end
      else
        respond_to do |format|
          format.html { redirect_to @magazine, notice: "You are not subscribed." }
          format.json { render json: { "status" => "409", "message" => "Not subscribed." }, status: :conflict }
        end
      end
    end

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

    # GET /magazines or /magazines.json
    def index
      sort_by = params[:sort_by]
      case sort_by
      when "threads"
        @magazines = Magazine.left_joins(:posts).group(:id).order('COUNT(posts.id) DESC')
      when "comments"
        @magazines = Magazine.left_joins(:comments).group(:id).order('COUNT(comments.id) DESC')
      when "subscribers"
        @magazines = Magazine.left_joins(:users).group(:id).order('COUNT(users.id) DESC')
      else
        @magazines = Magazine.order(created_at: :desc)
      end

      respond_to do |format|
        format.html
        format.json {render json: magazines_with_info}
      end
    end

    # GET /magazines/1 or /magazines/1.json
    def show
      sort_by = params[:sort_by]
      case sort_by
      when "top"
        @posts = @magazine.posts.left_joins(:votes).where(votes: { vote_type: 'upvote' }).group('posts.id').order('COUNT(votes.id) DESC, posts.created_at DESC')
      when "commented"
        @posts = @magazine.posts.left_joins(:comments).group('posts.id').order('COUNT(comments.id) DESC, posts.created_at DESC')
      else
        @posts = @magazine.posts.order(created_at: :desc)
      end

      respond_to do |format|
        format.html
        format.json {render json: @magazine.as_json.merge({threads: @magazine.posts.count, comments: @magazine.posts.left_joins(:comments).count, subscribers: @magazine.users.count})}
      end

    end

    def posts
      @magazine = Magazine.find(params[:id])
      @posts = @magazine.posts
      sort_by = params[:sort_by]
      case sort_by
      when "top"
        @posts = @magazine.posts.left_joins(:votes).where(votes: { vote_type: 'upvote' }).group('posts.id').order('COUNT(votes.id) DESC, posts.created_at DESC')
      when "commented"
        @posts = @magazine.posts.left_joins(:comments).group('posts.id').order('COUNT(comments.id) DESC, posts.created_at DESC')
      else
        @posts = @magazine.posts.order(created_at: :desc)
      end
      respond_to do |format|
        format.json { render json: @posts }
      end
    end

    # GET /magazines/new
    def new
      @magazine = Magazine.new
    end

    # magazine /magazines or /magazines.json
    def create
      @magazine = Magazine.new(magazine_params)

      respond_to do |format|
        if @magazine.save
          format.html { redirect_to magazines_url, notice: "Magazine was successfully created." }
          format.json { render json: @magazine }
        else
          format.html { redirect_to magazines_url, notice: @magazine.errors.full_messages.join(", ") }
          format.json { render json: @magazine.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /magazines/1 or /magazines/1.json
    def update
      respond_to do |format|
        if @magazine.update(magazine_params)
          format.html { redirect_to magazine_url(@magazine), notice: "Magazine was successfully updated." }
          format.json { render :show, status: :ok, location: @magazine }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @magazine.errors, status: :unprocessable_entity }
        end
      end
    end



    private
      # Use callbacks to share common setup or constraints between actions.
      def set_magazine
        @magazine = Magazine.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def magazine_params
        params.require(:magazine).permit(:name, :title, :description, :rules)
      end

      def magazines_with_info
        @magazines.map do |magazine|
          magazine.as_json.merge({threads: magazine.posts.count, comments: magazine.posts.left_joins(:comments).count, subscribers: magazine.users.count})
        end
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
end
