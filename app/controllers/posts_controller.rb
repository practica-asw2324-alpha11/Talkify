class PostsController < ApplicationController
    def new
        @post = Post.new
    end

    def create
        @post = Post.new(post_params)
        if @post.save
            redirect_to @post, notice: 'Post was successfully created.'
        else
            render 'new'
        end
    end

    def show
        @post = Post.find(params[:id])
    end
    
    private
    
    def post_params
        params.require(:post).permit(:title, :url, :body)
    end
end
