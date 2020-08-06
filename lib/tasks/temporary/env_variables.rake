# Create a .env file from your application.yml file
task create_dot_env_file: :environment do
  env_file = File.open(".env", "w")

  File.open("config/application.yml", 'r') do |file|
    file.each_line do |line|
      new_line = line.gsub(": ", "=")
      unless new_line.blank? || new_line.starts_with?("#")
        new_line.prepend("export ")
      end
      env_file.write(new_line)
    end
  end

  env_file.close
  File.delete("config/application.yml")
end
