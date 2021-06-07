class RegistrationPolicy
  def initialize(user, record)
    @user = user
    @record = record
  end

  def create?
    email_registrable?
  end

  private

  def email_registrable?
    if Settings::General.waiting_on_first_user
      if ENV["FOREM_OWNER_SECRET"].present?
        ENV["FOREM_OWNER_SECRET"] == params[:user][:forem_owner_secret]
      else
        true
      end
    elsif Settings::Authentication.allow_email_password_registration
      true
    end
  end
end
