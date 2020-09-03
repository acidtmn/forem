module ApplicationHelper
  # rubocop:disable Performance/OpenStruct
  DELETED_USER = OpenStruct.new(
    id: nil,
    darker_color: HexComparer.new(bg: "#19063A", text: "#dce9f3").brightness,
    username: "[deleted user]",
    name: "[Deleted User]",
    summary: nil,
    twitter_username: nil,
    github_username: nil,
  )
  # rubocop:enable Performance/OpenStruct

  def user_logged_in_status
    user_signed_in? ? "logged-in" : "logged-out"
  end

  def current_page
    "#{controller_name}-#{controller.action_name}"
  end

  # rubocop:disable Rails/HelperInstanceVariable
  def view_class
    if @podcast_episode_show # custom due to edge cases
      "stories stories-show podcast_episodes-show"
    elsif @story_show
      "stories stories-show"
    else
      "#{controller_name} #{controller_name}-#{controller.action_name}"
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable

  def title(page_title)
    derived_title = if page_title.include?(community_name)
                      page_title
                    elsif user_signed_in?
                      "#{page_title} - #{community_qualified_name} 👩‍💻👨‍💻"
                    else
                      "#{page_title} - #{community_name}"
                    end
    content_for(:title) { derived_title }
    derived_title
  end

  def title_with_timeframe(page_title:, timeframe:, content_for: false)
    sub_titles = {
      "week" => "Top posts this week",
      "month" => "Top posts this month",
      "year" => "Top posts this year",
      "infinity" => "All posts",
      "latest" => "Latest posts"
    }

    if timeframe.blank? || sub_titles[timeframe].blank?
      return content_for ? title(page_title) : page_title
    end

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

    "https://res.cloudinary.com/#{ApplicationConfig['CLOUDINARY_CLOUD_NAME']}/image/upload/#{postfix}"
  end

  def optimized_image_url(url, width: 500, quality: 80, fetch_format: "auto")
    image_url = url.presence || asset_path("#{rand(1..40)}.png")

    Images::Optimizer.call(SimpleIDN.to_ascii(image_url), width: width, quality: quality, fetch_format: fetch_format)
  end

  def optimized_image_tag(image_url, optimizer_options: {}, image_options: {})
    image_options[:width] ||= optimizer_options[:width]
    image_options[:height] ||= optimizer_options[:height]
    updated_image_url = Images::Optimizer.call(image_url, optimizer_options)

    image_tag(updated_image_url, image_options)
  end

  def cloud_cover_url(url)
    CloudCoverUrl.new(url).call
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

  def any_selfserve_auth?
    authentication_enabled_providers.any?
  end

  def beautified_url(url)
    url.sub(%r{\A((https?|ftp):/)?/}, "").sub(/\?.*/, "").chomp("/")
  rescue StandardError
    url
  end

  def org_bg_or_white(org)
    org&.bg_color_hex ? org.bg_color_hex : "#ffffff"
  end

  def sanitize_rendered_markdown(processed_html)
    ActionController::Base.helpers.sanitize processed_html,
                                            scrubber: RenderedMarkdownScrubber.new
  end

  def sanitized_sidebar(text)
    ActionController::Base.helpers.sanitize simple_format(text),
                                            tags: %w[p b i em strike strong u br]
  end

  def follow_button(followable, style = "full", classes = "")
    return if followable == DELETED_USER

    tag :button, # Yikes
        class: "crayons-btn follow-action-button #{classes}",
        data: {
          :info => { id: followable.id, className: followable.class.name, style: style }.to_json,
          "follow-action-button" => true
        }
  end

  def user_colors_style(user)
    "border: 2px solid #{user.decorate.darker_color}; \
    box-shadow: 5px 6px 0px #{user.decorate.darker_color}"
  end

  def user_colors(user)
    return { bg: "#19063A", text: "#dce9f3" } if user == DELETED_USER

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
    if SiteConfig.logo_svg.present?
      SiteConfig.logo_svg.html_safe # rubocop:disable Rails/OutputSafety
    else
      inline_svg_tag("devplain.svg", class: "logo", size: "20% * 20%", aria: true, title: "App logo")
    end
  end

  def safe_logo_url(logo)
    logo.presence || SiteConfig.logo_png
  end

  def community_name
    @community_name ||= SiteConfig.community_name # rubocop:disable Rails/HelperInstanceVariable
  end

  def community_qualified_name
    "#{community_name} Community"
  end

  def release_adjusted_cache_key(path)
    release_footprint = ApplicationConfig["RELEASE_FOOTPRINT"]
    return path if release_footprint.blank?

    "#{path}-#{params[:locale]}-#{release_footprint}"
  end

  def copyright_notice
    start_year = SiteConfig.community_copyright_start_year.to_s
    current_year = Time.current.year.to_s
    return start_year if current_year == start_year
    return current_year if start_year.strip.length < 4 # 978 is not a valid year!

    "#{start_year} - #{current_year}"
  end

  def collection_link(collection, **kwargs)
    size_string = "#{collection.articles.published.size} Part Series"
    body = collection.slug.present? ? "#{collection.slug} (#{size_string})" : size_string

    link_to body, collection.path, **kwargs
  end

  def email_link(type = :default, text: nil, additional_info: nil)
    # The allowed types for type is :default, :business, :privacy, and members.
    # These options can be found in field :email_addresses of models/site_config.rb
    email = SiteConfig.email_addresses[type] || SiteConfig.email_addresses[:default]
    mail_to email, text || email, additional_info
  end

  def community_members_label
    SiteConfig.community_member_label.pluralize
  end

  def app_url(uri = nil)
    URL.url(uri)
  end

  def article_url(article)
    URL.article(article)
  end

  def comment_url(comment)
    URL.comment(comment)
  end

  def reaction_url(reaction)
    URL.reaction(reaction)
  end

  def tag_url(tag, page = 1)
    URL.tag(tag, page)
  end

  def user_url(user)
    URL.user(user)
  end

  def organization_url(organization)
    URL.organization(organization)
  end

  def sanitized_referer(referer)
    URL.sanitized_referer(referer)
  end

  def sanitize_and_decode(str)
    # using to_str instead of to_s to prevent removal of html entity code
    HTMLEntities.new.decode(sanitize(str).to_str)
  end

  # rubocop:disable Rails/OutputSafety
  def admin_config_label(method, content = nil)
    content ||= raw("<span>#{method.to_s.humanize}</span>")
    if method.to_sym.in?(VerifySetupCompleted::MANDATORY_CONFIGS)
      content = safe_join([content, raw("<span class='site-config__required'>Required</span>")])
    end

    tag.label(content, class: "site-config__label", for: "site_config_#{method}")
  end
  # rubocop:enable Rails/OutputSafety
end
