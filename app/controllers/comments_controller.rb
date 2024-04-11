class CommentsController < ApplicationController
  before_action :set_comment, only: [:edit, :update, :destroy]

  def edit
    # Acción para mostrar el formulario de edición de comentario
  end

  def update
    if @comment.update(comment_params)
      redirect_to @comment.post, notice: 'Comentario actualizado correctamente.'
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
    @post = @comment.post
    @comment.destroy
    redirect_to @post, notice: 'Comentario eliminado correctamente.'
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
