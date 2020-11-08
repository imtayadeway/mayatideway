require "bundler/setup"
require "base64"
require "kramdown"
require "openssl"
require "mayatideway/encrypts_posts"
require "mayatideway/post"
require "mayatideway/encrypted_post"

module Mayatideway
  PASSPHRASE = "password".freeze # LOL, pls change me

  def self.encrypt
    Post.protected.each do |post|
      EncryptsPosts.encrypt(post)
    end
  end
end
