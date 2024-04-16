class Admin < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:google_oauth2]
  has_many :comments, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_and_belongs_to_many :magazines
  has_many :boosts, dependent: :destroy


   def self.from_google(email:, full_name:, uid:, avatar_url:)
    return nil unless email =~ /@estudiantat.upc.edu\z/
    create_with(uid: uid, full_name: full_name, avatar_url: avatar_url).find_or_create_by!(email: email)
  end
end
