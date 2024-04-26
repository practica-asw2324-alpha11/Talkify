class MagazinesController < ApplicationController
    before_action :set_votes_hash
    before_action :set_magazine, only: %i[ show edit update destroy]

    def subscribe
      if user_signed_in?
        @magazine = Magazine.find(params[:id])
        current_user.magazines << @magazine unless current_user.magazines.include?(@magazine)
        redirect_to @magazine
      end
    end

    def unsubscribe
      if user_signed_in?
        @magazine = Magazine.find(params[:id])
        current_user.magazines.delete(@magazine)
        redirect_to magazines_path
      end
    end

    def set_votes_hash
      if user_signed_in?
        @votes_hash = current_user.votes.index_by(&:post_id).transform_values(&:vote_type)
        @boosted_posts = current_user.boosts.pluck(:post_id)
      else
        @votes_hash = {}
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
    end

    # GET /magazines/new
    def new
      @magazine = Magazine.new
    end

    # GET /magazines/1/edit
    def edit
    end

    # magazine /magazines or /magazines.json
    def create
      @magazine = Magazine.new(magazine_params)

      respond_to do |format|
        if @magazine.save
          format.html { redirect_to magazines_url, notice: "Magazine was successfully created." }
          format.json { render :index, status: :created, location: @magazine }
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

    # DELETE /magazines/1 or /magazines/1.json
    def destroy
      @magazine.destroy
      respond_to do |format|
        format.html { redirect_to magazines_url, notice: "Magazine was successfully destroyed." }
        format.json { head :no_content }
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
  end
