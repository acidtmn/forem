module ApplicationHelper
  def user_logged_in_status
    user_signed_in? ? "logged-in" : "logged-out"
  end

  def current_page
    "#{controller_name}-#{controller.action_name}"
  end

  def view_class
    if @story_show # custom due to edge cases
      "stories stories-show"
    else
      "#{controller_name} #{controller_name}-#{controller.action_name}"
    end
  end

  def core_pages?
    %w[
      articles
      podcast_episodes
      events
      tags
      registrations
      users
      pages
      chat_channels
      dashboards
      moderations
      videos
      badges
      stories
      comments
      notifications
      reading_list_items
      html_variants
      classified_listings
      credits
      partnerships
      pro_accounts
    ].include?(controller_name)
  end

  def render_js?
    article_pages = controller_name == "articles" && %(index show).include?(controller.action_name)
    pulses_pages = controller_name == "pulses"
    !(article_pages || pulses_pages)
  end

  def title(page_title)
    derived_title = if page_title.include?(ApplicationConfig["COMMUNITY_NAME"])
                      page_title
                    else
                      page_title + " - #{ApplicationConfig['COMMUNITY_NAME']} Community 👩‍💻👨‍💻"
                    end
    content_for(:title) { derived_title }
    derived_title
  end

  def title_with_timeframe(page_title:, timeframe:, content_for: false)
    if timeframe.blank?
      return content_for ? title(page_title) : page_title
    end

    sub_titles = {
      "week" => "Top posts this week",
      "month" => "Top posts this month",
      "year" => "Top posts this year",
      "infinity" => "All posts",
      "latest" => "Latest posts"
    }

    title_text = "#{page_title} - #{sub_titles.fetch(timeframe)}"
    content_for ? title(title_text) : title_text
  end

  def icon(name, pixels = "20")
    image_tag(icon_url(name), alt: name, class: "icon-img", height: pixels, width: pixels)
  end

  def icon_url(name)
    postfix = {
      "twitter" => "v1456342401/twitter-logo-silhouette_1_letrqc.png",
      "github" => "v1456342401/github-logo_m841aq.png",
      "link" => "v1456342401/link-symbol_apfbll.png",
      "volume" => "v1461589297/technology_1_aefet2.png",
      "volume-mute" => "v1461589297/technology_jiugwb.png"
    }.fetch(name, "v1456342953/star-in-black-of-five-points-shape_sor40l.png")

    "https://res.cloudinary.com/practicaldev/image/upload/#{postfix}"
  end

  def cloudinary(url, width = nil, _quality = 80, _format = "jpg")
    return url if Rails.env.development? && (url.blank? || url.exclude?("http"))

    service_path = "https://res.cloudinary.com/practicaldev/image/fetch"

    if url&.size&.positive?
      if width
        "#{service_path}/c_scale,fl_progressive,q_auto,w_#{width}/f_auto/#{url}"
      else
        "#{service_path}/c_scale,fl_progressive,q_auto/f_auto/#{url}"
      end
    else
      "#{service_path}/c_scale,fl_progressive,q_1/f_auto/https://pbs.twimg.com/profile_images/481625927911092224/iAVNQXjn_normal.jpeg"
    end
  end

  def cloud_cover_url(url)
    return if url.blank?
    return asset_path("triple-unicorn") if Rails.env.test?
    return url if Rails.env.development?

    width = 1000
    height = 420
    quality = "auto"

    cl_image_path(url,
                  type: "fetch",
                  width: width,
                  height: height,
                  crop: "imagga_scale",
                  quality: quality,
                  flags: "progressive",
                  fetch_format: "auto",
                  sign_url: true)
  end

  def tag_colors(tag)
    Rails.cache.fetch("view-helper-#{tag}/tag_colors", expires_in: 5.hours) do
      if (found_tag = Tag.select(%i[bg_color_hex text_color_hex]).find_by(name: tag))
        { background: found_tag.bg_color_hex, color: found_tag.text_color_hex }
      else
        { background: "#d6d9e0", color: "#606570" }
      end
    end
  end

  def beautified_url(url)
    url.sub(/^((http[s]?|ftp):\/)?\//, "").sub(/\?.*/, "").chomp("/")
  rescue StandardError
    url
  end

  def org_bg_or_white(org)
    org&.bg_color_hex ? org.bg_color_hex : "#ffffff"
  end

  def sanitize_rendered_markdown(processed_html)
    ActionController::Base.helpers.sanitize processed_html.html_safe,
                                            scrubber: RenderedMarkdownScrubber.new
  end

  def sanitized_sidebar(text)
    ActionController::Base.helpers.sanitize simple_format(text),
                                            tags: %w[p b i em strike strong u br]
  end

  def follow_button(followable, style = "full")
    tag :button, # Yikes
        class: "cta follow-action-button",
        data: {
          info: { id: followable.id, className: followable.class.name, style: style }.to_json,
          "follow-action-button" => true
        }
  end

  def user_colors_style(user)
    "border: 2px solid #{user.decorate.darker_color}; \
    box-shadow: 5px 6px 0px #{user.decorate.darker_color}"
  end

  def user_colors(user)
    user.decorate.enriched_colors
  end

  def timeframe_check(given_timeframe)
    params[:timeframe] == given_timeframe
  end

  def list_path
    return "" if params[:tag].blank?

    "/t/#{params[:tag]}"
  end

  def logo_svg
    if ApplicationConfig["LOGO_SVG"].present?
      ApplicationConfig["LOGO_SVG"].html_safe
    else
      inline_svg("devplain.svg", class: "logo", size: "20% * 20%", aria: true, title: "App logo")
    end
  end

  def community_qualified_name
    "The #{ApplicationConfig['COMMUNITY_NAME']} Community"
  end

  def truncate_html(html, length)
    html_without_tags = strip_tags(html)
    tags_length = html.length - html_without_tags.length
    return html if html_without_tags.length <= length

    Nokogiri::HTML::DocumentFragement.parse(html.truncate(length + tags_length)).to_xml
  end

  def sponsorship_credits_price(level)
    if level == "bronze"
      50
    elsif level == "silver"
      300
    elsif level == "gold"
      4000
    elsif level == "tag"
      500
    elsif level == "media"
      25
    elsif level == "editorial"
      500
    end
  end
end
