module Mayatideway
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
      aes.pkcs5_keyivgen(Mayatideway.fetch_passphrase, salt, 1)
      aes.update(data) + aes.final
    end
  end
end
