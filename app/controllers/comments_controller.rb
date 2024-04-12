class CommentsController < ApplicationController
  before_action :set_comment, except: [:sort, :new, :create]
  before_action :set_post, only: [:sort, :edit, :destroy]

  def edit
    @comment = Comment.find(params[:id])
  end

  def sort
    @post = Post.find(params[:id])
    @comments = @post.comments.order_by(params[:sort_by])
    @comment = @post.comments.build
    render 'posts/show'
  end

  def upvote

    @comment.upvote +=1
    @comment.save

    respond_to do |format|
      format.html { redirect_to post_path(@post)}
      format.json { head :no_content }
    end
  end

  def downvote

    @comment.downvote +=1
    @comment.save

    respond_to do |format|
      format.html { redirect_to post_path(@post)}
      format.json { head :no_content }
    end
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
    @comment.user_id = 1

    if @comment.save
      redirect_to post_path(@post)
    else
      render 'new'
    end
  end

  def destroy
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


  def comment_params
    params.require(:comment).permit(:body)
  end
end
