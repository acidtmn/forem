class SpotifyTag < LiquidTagBase
  URI_REGEXP = /spotify:(track|user|artist|album).+(?<=:)\w{22}/
  URL_REGEXP = /https:\/\/open.spotify.com\/(track|user|artist|album)\/.*(?<=\/)\w{22}/
  TYPE_LIST = {
    track: 116,
    user: 116,
    artist: 116,
    album: 116
  }.freeze

  def initialize(tag_name, link)
    super
    @link_type, @parsed_link = parse_link(link)
    @height = TYPE_LIST[@match_data[1]]
  end

  def render(_context)
    html = <<-HTML
      <iframe
        width="100%"
        height="#{@height}"
        scrolling="no"
        frameborder="0"
        allowtransparency="true"
        allow="encrypted-media"
        src="#{embed_url(@link_type, @parsed_link)}">
      </iframe>
    HTML
    finalize_html(html)
  end

  private

  def parse_link(link)
    case
    when URI_REGEXP.match(link)
      'uri', URI_REGEXP.match(link).string
    when URL_REGEXP.match(link)
      'url', URL_REGEXP.match(link).string
    else
      raise_error
    end
  end

  def embed_url(link_type, parsed_link)
    case link_type
    when 'uri'
      parsed_link.split(':')[1..-1].unshift('https://open.spotify.com/embed').join('/')
    when 'url'
      parsed_link.gsub('https://open.spotify.com', 'https://open.spotify.com/embed')
    end
  end

  def raise_error
    raise StandardError, "Invalid Spotify Link - Be sure You're linking to a specific track / album / artist / playlist"
  end
end

Liquid::Template.register_tag("spotify", SpotifyTag)
