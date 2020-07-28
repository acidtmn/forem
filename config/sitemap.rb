# @forem/systems Only currently configured properly for Heroku target

if Rails.env.production?
  region = ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"]
  if ENV["HEROKU_APP_ID"].present?
    SitemapGenerator::Sitemap.adapter = SitemapGenerator::S3Adapter.new(
      fog_provider: "AWS",
      aws_access_key_id: ApplicationConfig["AWS_ID"],
      aws_secret_access_key: ApplicationConfig["AWS_SECRET"],
      fog_directory: ApplicationConfig["AWS_BUCKET_NAME"],
      fog_region: region,
    )
    SitemapGenerator::Sitemap.sitemaps_host = "https://#{ApplicationConfig['AWS_BUCKET_NAME']}.s3.amazonaws.com/"
  else
    SitemapGenerator::Sitemap.adapter = SitemapGenerator::S3Adapter.new(
      fog_provider: "AWS",
      aws_access_key_id: "placeholder", # @forem/systems - Obviously this is temporary to get things working :)
      aws_secret_access_key: "placeholder",
      use_iam_profile: true,
      fog_directory: "forem-12345-uploads",
      fog_region: region,
    )
    SitemapGenerator::Sitemap.sitemaps_host = "https://forem-12345-uploads.s3.amazonaws.com/"
  end
  SitemapGenerator::Sitemap.public_path = "tmp/"
  SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"
end

SitemapGenerator::Sitemap.default_host = "#{ApplicationConfig['APP_PROTOCOL']}#{ApplicationConfig['APP_DOMAIN']}"

SitemapGenerator::Sitemap.create do
  Article.published.where("score > ? OR featured = ?", 12, true)
    .limit(38_000).find_each do |article|
    add article.path, lastmod: article.last_comment_at, changefreq: "daily"
  end

  User.order(comments_count: :desc).where("updated_at > ?", 5.days.ago).limit(8000).find_each do |user|
    add "/#{user.username}", changefreq: "daily"
  end

  Tag.order(hotness_score: :desc).limit(250).find_each do |tag|
    add "/t/#{tag.name}", changefreq: "daily"
  end
end
