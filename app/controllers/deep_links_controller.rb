class DeepLinksController < ApplicationController
  def mobile; end

  # Apple Application Site Association
  def aasa
    supported_apps = ["R9SWHSQNV8.com.forem.app"]
    supported_apps << "R9SWHSQNV8.to.dev.ios" if SiteConfig.dev_to?
    render json: {
      applinks: {
        apps: supported_apps,
        details: supported_apps.map { |app_id| { appID: app_id, paths: ["/*"] } }
      },
      activitycontinuation: {
        apps: supported_apps
      },
      webcredentials: {
        apps: supported_apps
      }
    }
  end
end
