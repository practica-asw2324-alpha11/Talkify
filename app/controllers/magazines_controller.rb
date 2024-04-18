class MagazinesController < ApplicationController
    before_action :set_votes_hash
    before_action :set_magazine, only: %i[ show edit update destroy]

    def subscribe
      if admin_signed_in?
        @magazine = Magazine.find(params[:id])
        current_admin.magazines << @magazine unless current_admin.magazines.include?(@magazine)
        redirect_to @magazine
      end
    end

    def unsubscribe
      if admin_signed_in?
        @magazine = Magazine.find(params[:id])
        current_admin.magazines.delete(@magazine)
        redirect_to magazines_path
      end
    end

    def set_votes_hash
      if admin_signed_in?
        @votes_hash = current_admin.votes.index_by(&:post_id).transform_values(&:vote_type)
        @boosted_posts = current_admin.boosts.pluck(:post_id)
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
        @magazines = Magazine.left_joins(:admins).group(:id).order('COUNT(admins.id) DESC')
      else
        @magazines = Magazine.order(:desc)
      end
    end

    # GET /magazines/1 or /magazines/1.json
    def show

      @posts = @magazine.posts

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
