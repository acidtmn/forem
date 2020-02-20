class DataUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high_priority, retry: 5

  def perform
    DataUpdateScript.scripts_to_run.each do |script|
      script.mark_as_run!

      run_script(script)
    end
  end

  private

  def run_script(script)
    require script.file_path

    Rails.logger.info("Data update script: #{script.file_name}: running")
    script.file_class.new.run

    script.mark_as_finished!
    Rails.logger.info("Data update script: #{script.file_name}: finished")
  rescue StandardError => e
    script.mark_as_failed!
    Rails.logger.error("Data update script: #{script.file_name}: failed")

    Honeybadger.notify(e, context: { script_id: script.id })
  end
end
