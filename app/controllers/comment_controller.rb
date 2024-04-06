class CommentController < ApplicationController
    def new
        @comment = Comment.new
    end

    def create
        @comment = Comment.create comment_params
        if @comment.persisted?
            redirect_to comments_path, notice: "El comment ha sido creado de forma exitosa"
        else
            render :new, status: :unprocessable_entity
        end
    end

    def destroy
        @comment = Comment.find(params[:id])
        @comment.destroy
    end

    private

        def comment_params
            params.require(:comment).permit(:body)
        end**

end
