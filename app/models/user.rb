class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:google_oauth2]
  has_many :comments, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :comment_votes, dependent: :destroy
  has_and_belongs_to_many :magazines
  has_many :boosts, dependent: :destroy
  has_one_attached :avatar
  has_one_attached :background
  before_create :set_api_key

  def comments_num
    comments.count
  end

  def posts_num
    posts.count
  end

  def boosts_num
    boosts.count
  end

  def self.from_google(email:, full_name:, uid:, avatar_url:)
    create_with(uid: uid, full_name: full_name, avatar_url: avatar_url).find_or_create_by!(email: email)
  end

  def generate_api_key
    self.api_key = SecureRandom.base58(24)
  end

  def set_api_key
    generate_api_key if api_key.blank?
  end

  def save_image_to_s3(image, image_type)
    name = File.basename(image.path)
    s3 = Aws::S3::Resource.new(
      region: 'us-east-1',
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      session_token: ENV['AWS_SESSION_TOKEN']
    )
    bucket = s3.bucket('talkify-bucket')
    obj = bucket.object("#{image_type}/#{name}")
    obj.upload_file(image.path)
  end
end