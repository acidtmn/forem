module Admin
  class DataUpdateScriptsController < Admin::ApplicationController
    layout "admin"

    def index
      @data_update_scripts = DataUpdateScript.order(run_at: :desc)
    end

    def show
      response = DataUpdateScript.find(params[:id])
      render json: { response: response }
    end

    def force_run
      script = DataUpdateScript.find(params[:id])
      DataUpdateWorker.perform_async(script)
    end
  end
end
