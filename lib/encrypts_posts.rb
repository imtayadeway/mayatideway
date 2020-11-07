require "bundler/setup"
require "base64"
require "kramdown"
require "openssl"

class Post
  attr_reader :fn

  def initialize(fn)
    @fn = fn
  end

  %i[front_matter markdown html].each do |meth|
    class_eval(<<~EOS)
      def #{meth}
        parse unless defined?(@#{meth})
        @#{meth}
      end
    EOS
  end

  private

  def parse
    File.open(fn) do |file|
      _, yaml, @markdown = file.read.split("---", 3).map(&:strip)
      @front_matter = YAML.load(yaml)
      @html = Kramdown::Document.new(@markdown, input: "markdown").to_html
    end
  end
end

class EncryptsPosts
  PASSPHRASE = "password".freeze # LOL, pls change me

  def self.encrypt
    new.encrypt
  end

  def encrypt
    protected_files.each do |fn|
      encrypt_file(fn)
    end
  end

  def protected_files
    Dir.glob("_protected/*")
  end

  def encrypt_file(fn)
    post = Post.new(fn)
    encrypted = encrypt_body(post.html)

    yaml = YAML.load_file(target_fn(fn))
    body = decrypt_body(yaml["encrypted"])
    if yaml.reject { |k,_| k == "encrypted" } == post.front_matter && body == post.html
      puts "skipping #{File.basename(fn)} - no change"
      return
    end

    File.open(target_fn(fn), "w") do |file|
      file.puts fill_template(front_matter, encrypted)
    end
  end

  def decrypt_body(encrypted)
    data = Base64.strict_decode64(encrypted[64..-1])
    salt = data[8..15]
    data = data[16..-1]
    aes = OpenSSL::Cipher.new("AES-256-CBC")
    aes.decrypt
    aes.pkcs5_keyivgen(PASSPHRASE, salt, 1)
    aes.update(data) + aes.final
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
