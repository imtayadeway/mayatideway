require "bundler/setup"
require "base64"
require "kramdown"
require "openssl"

class Post
  def self.protected
    Dir.glob("_protected/*").map { |fn| load(fn) }
  end

  def self.load(fn)
    File.open(fn) do |file|
      new(file.read, fn)
    end
  end

  attr_reader :content, :fn

  def initialize(content, fn = "")
    @content = content
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
    _, yaml, @markdown = content.split("---", 3).map(&:strip)
    @front_matter = YAML.load(yaml)
    @html = Kramdown::Document.new(@markdown, input: "markdown").to_html
  end
end

class EncryptedPost
  def self.load(fn)
    File.open(fn) do |file|
      new(file.read, fn)
    end
  end

  attr_reader :content, :fn

  def initialize(content, fn = "")
    @content = content
    @fn = fn
  end

  def front_matter
    @front_matter ||= YAML.load(content.split("---", 3).map(&:strip)[1])
  end

  def html
    @html ||= decrypt
  end

  private

  def decrypt
    data = Base64.strict_decode64(front_matter["encrypted"][64..-1])
    salt = data[8..15]
    data = data[16..-1]
    aes = OpenSSL::Cipher.new("AES-256-CBC")
    aes.decrypt
    aes.pkcs5_keyivgen("password", salt, 1)
    aes.update(data) + aes.final
  end
end

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
