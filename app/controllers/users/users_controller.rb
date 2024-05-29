# app/controllers/users/users_controller.rb
class Users::UsersController < ApplicationController
  before_action :set_votes_hash
  before_action :set_user
  before_action :set_target_user, only: [:show, :user_comments, :user_posts, :user_boosts, :update]

  def index
    @users = User.all
    render json: @users.as_json(except: [:uid, :api_key])
  end

  def show
    params[:view] ||= 'threads'
    @posts = @user_target.posts.order(created_at: :desc)
    @comments = @user_target.comments.order(created_at: :desc)

    # Calculate the counts
    comments_count = @user_target.comments.count
    posts_count = @user_target.posts.count

    # Only calculate boosts_count if the user is the same as @user
    boosts_count = @user == @user_target ? Boost.where(user: @user_target).count : nil

    @user = User.find(params[:id])


    set_votes_hash
    respond_to do |format|
      format.html
      format.json do
        user_json = @user_target.as_json(except: [:uid, :api_key]).merge({
          comments_count: comments_count,
          posts_count: posts_count,
          avatar: @user_target.avatar.attached? ? url_for(@user_target.avatar) : nil,
          background: @user_target.background.attached? ? url_for(@user_target.background) : nil

        })

        user_json[:boosts_count] = boosts_count unless boosts_count.nil?

        render json: user_json
      end
    end
  end

  def set_votes_hash
    if user_signed_in?
      @votes_hash = current_user.votes.index_by(&:post_id).transform_values(&:vote_type)
      @boosted_posts_ids = current_user.boosts.pluck(:post_id)
      @boosted_posts = Post.where(id: @boosted_posts_ids)
      @comment_votes_hash = current_user.comment_votes.index_by(&:comment_id).transform_values(&:vote_type)

    else
      @votes_hash = {}
      @boosted_posts = {}
      @comment_votes_hash = {}

    end
  end


  def boosted_posts
    @boosted_posts = Boost.where(user: current_user).includes(:post).map(&:post)
  end


  def sort
    @posts = Post.order_by(params[:sort_by])

    case params[:from]
    when "user_show"
      # Asegúrate de definir todas las variables necesarias para esta vista.
      @user = User.find(params[:user_id]) # Asegúrate de pasar el user_id de alguna manera.
      @comments = @user.comments.includes(:post).order(created_at: :desc)
      render 'users/users/show'
    else
      render 'index'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    user_params = params[:user].present? ? params[:user] : params

    puts @user.inspect

    respond_to do |format|
      if @user != @user_target
        format.json { render json: { error: "You can only edit your profile", errors: @user.errors }, status: :forbidden }
      else
        if user_params[:avatar].present?
          avatar = user_params[:avatar].is_a?(String) ? parse_image_data(user_params[:avatar]) : user_params[:avatar]
          @user.avatar.attach(avatar)
          @user.save_image_to_s3(avatar, 'avatar') if @user.avatar.attached?
        end
        if user_params[:background].present?
          background_image = user_params[:background].is_a?(String) ? parse_image_data(user_params[:background]) : user_params[:background]
          @user.background.attach(background_image)
          @user.save_image_to_s3(background_image, 'background') if @user.background.attached?
        end
        if user_params[:full_name].present?
          @user.full_name = user_params[:full_name]
        end
        if user_params[:description].present?
          @user.description = user_params[:description]
        end

        if @user.save
          user_hash = @user.attributes.except('updated_at', 'url', 'encrypted_password', 'reset_password_token', 'reset_password_sent_at', 'remember_created_at', 'provider', 'uid').merge({
                   posts_count: @user.posts.count,
                   comments_count: @user.comments.count,
                   boosts_count: @user.boosts.count,
                   avatar: @user.avatar.attached? ? url_for(@user.avatar) : nil,
                   background: @user.background.attached? ? url_for(@user.background) : nil
                 })

          format.html { redirect_to @user, notice: "User was successfully updated." }
          format.json { render json: user_hash }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: { error: "There was an error updating the user.", errors: @user.errors }, status: :unprocessable_entity }
        end
      end
    end
end



  def user_comments
    @user = User.find(params[:id])

    case params[:sort_by]
    when "top"
      @comments = @user.comments
                               .select('comments.*, (comments.upvote - comments.downvote) AS votes_difference')
                               .order('votes_difference DESC')
    when "newest"
      @comments = @user.comments.order(created_at: :desc)
    else
      @comments = @user.comments.order(created_at: :asc)
    end

    respond_to do |format|
      format.html { render 'user/show' }
      format.json { render json: json_with_replies(@comments), status: :ok }
    end
  end

  def user_params
    params.require(:user).permit(:email, :full_name, :description, :uid)
  end

def user_posts
  @user = User.find(params[:id])
  @posts = @user.posts.order_by(params[:sort_by])

  respond_to do |format|
    format.html { render 'user/show' }
    format.json do
      if @posts.present?
        @posts = @posts.map do |post|
          post_json = post.as_json(methods: [:upvotes_count, :downvotes_count, :comments_count], except: [:magazine_id, :user_id]).merge(
            is_upvoted: post.is_upvoted(@user),
            is_downvoted: post.is_downvoted(@user),
            is_boosted: post.is_boosted(@user)
          )

          if post.magazine.present?
            post_json[:magazine] = post.magazine.as_json(only: [:id, :title, :description])
          end

          if post.user.present?
            post_json[:user] = post.user.as_json(only: [:id, :full_name, :email])
          end

          post_json
        end
        render json: { posts: @posts }
      else
        render json: { error: "No posts found" }, status: :not_found
      end
    end
  end
end

def user_boosts
  @user = User.find(params[:id])
  @user_target = @user

  if @user == @user_target
    @boosted_posts = Boost.where(user: @user).includes(:post).map(&:post)
    @boosted_posts = @boosted_posts.map do |post|
      post_json = post.as_json(methods: [:upvotes_count, :downvotes_count, :comments_count], except: [:magazine_id, :user_id]).merge(
        is_upvoted: post.is_upvoted(@user),
        is_downvoted: post.is_downvoted(@user),
        is_boosted: post.is_boosted(@user)
      )

      if post.magazine.present?
        post_json[:magazine] = post.magazine.as_json(only: [:id, :title, :description])
      end
      if post.user.present?
        post_json[:user] = post.user.as_json(only: [:id, :full_name, :email])
      end

      post_json
    end

    response = { "boosted_posts" => @boosted_posts }
    status = :ok
  else
    response = { "error" => "You can only see the boosts of your own user." }
    status = :forbidden
  end

  respond_to do |format|
    format.html { render 'user/show' }
    format.json { render json: response, status: status }
  end
end

  private

  def json_with_replies(comments)
    result = Array(comments).map do |comment|
      comment.as_json(except: [:post_id, :user_id]).merge(
        user: comment.user.as_json(only: [:id, :full_name, :email]),
        post: comment.post.as_json(only: [:id, :title]),
        is_upvoted: comment.is_upvoted(@user),
        is_downvoted: comment.is_downvoted(@user),
        is_author: comment.user == @user,
        replies: Array.wrap(json_with_replies(comment.replies)),
      )
    end

    result.length == 1 ? result.first : result
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

  def set_target_user
    @user_target = User.find_by(id: params[:id])
    if @user_target.nil?
      render json: { "error" => "User not found" }, status: :not_found and return
    end
  end

  def parse_image_data(base64_image)
    filename = "upload-image"
    in_content_type, encoding, string = base64_image.split(/[:;,]/)[1..3]

    @tempfile = Tempfile.new(filename)
    @tempfile.binmode
    @tempfile.write Base64.decode64(string)
    @tempfile.rewind

    # for security we want the actual content type, not just what was passed in
    content_type = MIME::Types[in_content_type].first.content_type

    # we will also add the extension ourselves based on the above
    # if it's not gif/jpeg/png, it will fail the validation in the upload model
    extension = MIME::Types[content_type].first.extensions.first
    filename += ".#{extension}" if extension

    ActionDispatch::Http::UploadedFile.new({
                                             tempfile: @tempfile,
                                             content_type: content_type,
                                             filename: filename
                                           })

  end

end
