require "bundler/setup"
require "minitest/autorun"
require "encrypts_posts"
require "open3"

class EncryptsPostsTest < Minitest::Test
  def test_encryption
    skip("this ain't working yet")
    encrypted = EncryptsPosts.new.encrypt_body("<p>boop</p>")

    actual, _ = Open3.capture2(%q(openssl enc -aes-256-cbc -pass pass:"password" -d -base64 -A), stdin_data: encrypted[64..-1])

    assert_equal("<p>boop</p>", actual)
  end

  def test_decryption
    skip("this ain't working yet either")
    encrypted, _ = Open3.capture2(%q(echo "<p>boop</p>" | openssl enc -aes-256-cbc -pass pass:"password" -e -base64 -A))

    hmac = OpenSSL::HMAC.hexdigest(
      "SHA256",
      Digest::SHA256.hexdigest("password"),
      encrypted
    )
    actual = EncryptsPosts.new.decrypt_body(hmac + encrypted)
    assert_equal("", actual)
  end

  def test_symmetry
    encrypted = EncryptsPosts.new.encrypt_body("<p>boop</p>")
    decrypted = EncryptsPosts.new.decrypt_body(encrypted)
    assert_equal("<p>boop</p>", decrypted)
  end
end
