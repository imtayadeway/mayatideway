require "bundler/setup"
require "base64"
require "kramdown"
require "openssl"
require "post"
require "encrypted_post"

class EncryptsPosts
  PASSPHRASE = "password".freeze # LOL, pls change me

  def self.encrypt
    new.encrypt
  end

  def encrypt
    Post.protected.each do |file|
      encrypt_file(file)
    end
  end

  def encrypt_file(post)
    encrypted = encrypt_body(post.html)

    if File.exist?(target_fn(post.fn))
      encrypted_post = EncryptedPost.load(target_fn(post.fn))

      if post.html == encrypted_post.html && post.front_matter == encrypted_post.front_matter.reject { |k,_| k == "encrypted" }
        puts "skipping #{File.basename(post.fn)} - no change"
        return
      end
    end

    File.open(target_fn(post.fn), "w") do |file|
      file.puts fill_template(post.front_matter, encrypted)
    end
  end

  def encrypt_body(html)
    aes = OpenSSL::Cipher.new("AES-256-CBC")
    aes.encrypt
    salt = OpenSSL::Random.random_bytes(8)
    aes.pkcs5_keyivgen(PASSPHRASE, salt, 1)
    binary = "Salted__#{salt}#{aes.update(html) + aes.final}"
    encrypted_body = Base64.strict_encode64(binary)

    hmac = OpenSSL::HMAC.hexdigest(
      "SHA256",
      Digest::SHA256.hexdigest(PASSPHRASE),
      encrypted_body
    )
    hmac + encrypted_body
  end

  def target_fn(fn)
    File.join("_posts", File.basename(fn))
  end

  def fill_template(front_matter, encrypted)
    <<~EOF
    #{front_matter.to_yaml}
    encrypted: #{encrypted}
    ---
  EOF
  end
end
