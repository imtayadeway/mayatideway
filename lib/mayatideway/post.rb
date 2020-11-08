module Mayatideway
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
end
