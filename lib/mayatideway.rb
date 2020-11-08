require "bundler/setup"
require "base64"
require "kramdown"
require "openssl"
require "mayatideway/encrypts_posts"
require "mayatideway/post"
require "mayatideway/encrypted_post"

module Mayatideway
  PASSPHRASE_NAME = "MDRPASSPHRASE".freeze

  def self.encrypt
    Post.protected.each do |post|
      EncryptsPosts.encrypt(post)
    end
  end

  def self.fetch_passphrase
    ENV.fetch(PASSPHRASE_NAME)
  end
end
