module Mayatideway
  class EncryptsPosts
    attr_reader :post

    def self.encrypt(post)
      new(post).encrypt
    end

    def initialize(post)
      @post = post
    end

    def encrypt
      if done?
        puts "skipping #{File.basename(post.fn)} - no change"
        return
      end

      File.open(target_fn(post.fn), "w") do |file|
        file.puts fill_template(post.front_matter, encrypted)
      end
    end

    def encrypted
      @encrypted ||= hmac + encoded
    end

    def hmac
      @hmac ||= OpenSSL::HMAC.hexdigest(
        "SHA256",
        Digest::SHA256.hexdigest(PASSPHRASE),
        encoded
      )
    end

    def encoded
      @encoded = Base64.strict_encode64(salted)
    end

    def salted
      @salted ||=
        begin
          cipher = OpenSSL::Cipher.new("AES-256-CBC").tap { |c| c.encrypt }
          cipher.pkcs5_keyivgen(PASSPHRASE, salt, 1)
          "Salted__#{salt}#{cipher.update(post.html) + cipher.final}"
        end
    end

    def salt
      @salt ||= OpenSSL::Random.random_bytes(8)
    end

    def done?
      return false unless File.exist?(target_fn)
      encrypted_post = EncryptedPost.load(target_fn)
      post.html == encrypted_post.html &&
        post.front_matter == encrypted_post.front_matter.reject { |k,_| k == "encrypted" }
    end

    def target_fn
      File.join("_posts", File.basename(post.fn))
    end

    def fill_template(front_matter, encrypted)
      front_matter.merge(encrypted: encrypted).to_yaml + "\n---"
    end
  end
end
