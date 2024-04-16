class CommentsController < ApplicationController
  before_action :authenticate_admin!, only: [:create]
  before_action :set_comment, except: [:sort, :new, :create]
  before_action :set_post, only: [:sort, :edit]


  def edit
    @comment = Comment.find(params[:id])
  end

  def sort
    @post = Post.find(params[:id])
    @comments = @post.comments.order_by(params[:sort_by])
    @comment = @post.comments.build
    @sort = params[:sort_by]
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

  def show
    @post = Post.find(params[:post_id])
    @coment = Comment.find(params[:id])
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
    @comment.admin_id = current_admin.id


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


  def comment_params
    params.require(:comment).permit(:parent_comment_id, :body)
  end

end
