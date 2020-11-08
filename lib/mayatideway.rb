require "bundler/setup"
require "base64"
require "kramdown"
require "openssl"
require "encrypts_posts"
require "post"
require "encrypted_post"

module Mayatideway
  PASSPHRASE = "password".freeze # LOL, pls change me

  def self.encrypt
    Post.protected.each do |post|
      EncryptsPosts.encrypt(post)
    end
  end
end
