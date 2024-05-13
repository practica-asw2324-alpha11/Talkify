class CommentsController < ApplicationController
  before_action :set_votes_hash
  before_action :authenticate_user!, only: [:create]
  before_action :set_user
  before_action :set_comment, except: [:sort, :new, :create]
  before_action :set_post, only: [:sort, :edit]

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

def upvote
  if user_signed_in?
    ActiveRecord::Base.transaction do
      @comment_vote = @comment.comment_votes.find_or_initialize_by(user: current_user)

      if @comment_vote.new_record?
        @comment_vote.vote_type = 'upvote'
        @comment_vote.save!
      elsif @comment_vote.vote_type == 'downvote'
        @comment_vote.destroy!
        @comment.comment_votes.create!(user: current_user, vote_type: 'upvote')
      elsif @comment_vote.vote_type == 'upvote'
        @comment_vote.destroy!
      end
    end
    else
      redirect_to new_user_session_path
      return
    end


  respond_to do |format|
    format.html { redirect_back(fallback_location: root_path) }
    format.json { head :no_content }
  end
end

def downvote
  if user_signed_in?
    ActiveRecord::Base.transaction do
      @comment_vote = @comment.comment_votes.find_or_initialize_by(user: current_user)

      if @comment_vote.new_record?
        @comment_vote.vote_type = 'downvote'
        @comment_vote.save!
      elsif @comment_vote.vote_type == 'upvote'
        @comment_vote.destroy!
        @comment.comment_votes.create!(user: current_user, vote_type: 'downvote')
      elsif @comment_vote.vote_type == 'downvote'
        @comment_vote.destroy!
      end
    end
  else
    redirect_to new_user_session_path
    return
  end


    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { head :no_content }
    end
  end

  def edit
    @comment = Comment.find(params[:id])
  end

  def sort
    @post = Post.find(params[:id])

    if params[:sort_by] == "top"
      @comments = @post.comments
                  .left_joins(:comment_votes)
                  .select('comments.*, SUM(CASE WHEN comment_votes.vote_type = "upvote" THEN 1 WHEN comment_votes.vote_type = "downvote" THEN -1 ELSE 0 END) AS votes_difference')
                  .group('comments.id')
                  .order('votes_difference DESC')
    else
      @comments = @post.comments.order_by(params[:sort_by])
    end
    @comment = @post.comments.build
    @sort = params[:sort_by]
    render 'posts/show'
  end

  def show
    @post = Post.find(params[:post_id])
    @coment = Comment.find(params[:id])
  end

  def update
    @post = Post.find(params[:post_id])
    @comment = Comment.find(params[:id])

    if @comment.update(comment_params)
      redirect_to post_path(@post), notice: "Comentario actualizado correctamente."
    else
      render :edit
    end
  end

  def new

  end

  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.build(comment_params)
    @comment.user_id = current_user.id


    if @comment.save
      redirect_to post_path(@post)
    else
      render 'new'
    end
  end

  def create_reply
    @parent_comment = Comment.find(params[:comment_id])
    @reply = @parent_comment.replies.build(reply_params)

    if @reply.save
      redirect_to post_path(@parent_comment.post), notice: 'Respuesta creada correctamente.'
    else
      render 'posts/show'
    end
  end

  def destroy
    @post = Post.find(params[:post_id])
    @comment.destroy
    redirect_to post_path(@post), notice: 'Comentario eliminado correctamente.'
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def set_post
    @post = Post.find(params[:id])
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


  def comment_params
    params.require(:comment).permit(:parent_comment_id, :body)
  end

end
