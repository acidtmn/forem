# Checks if a Feedjira item represents a Medium reply or not
module Feeds
  class CheckItemMediumReply
    MEDIUM_DOMAIN = "medium.com".freeze

    def self.call(item)
      new(item).call
    end

    def initialize(item)
      @item = item
    end

    def call
      get_host_without_www(item.url.strip) == MEDIUM_DOMAIN &&
        !item[:categories] &&
        content_is_not_the_title?(item)
    end

    private

    attr_reader :item

    def get_host_without_www(url)
      url = "http://#{url}" if URI.parse(url).scheme.nil?
      host = URI.parse(url).host.downcase
      host.start_with?("www.") ? host[4..] : host
    end

    def content_is_not_the_title?(item)
      # [[:space:]] removes all whitespace, including unicode ones.
      content = item.content.gsub(/[[:space:]]/, " ")
      title = item.title.delete("…")
      content.include?(title)
    end
  end
end
