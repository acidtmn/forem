module Admin
  class OverviewController < Admin::ApplicationController
    layout "admin"
    def index
      @length = (params[:period] || 7).to_i
      @labels = (0..@length - 1).map { |n| n.days.ago.strftime("%b %d") }.reverse
      @analytics = Admin::ChartsData.new(@length).call
      @data_counts = Admin::DataCounts.call
    end
  end
end
