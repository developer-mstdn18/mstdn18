# frozen_string_literal: true

class User < ApplicationRecord
  include Settings::Extend

  devise :registerable, :recoverable,
         :rememberable, :trackable, :validatable, :confirmable,
         :two_factor_authenticatable, :two_factor_backupable,
         :omniauthable,:database_authenticatable,
         otp_secret_encryption_key: ENV['OTP_SECRET'],
         otp_number_of_backup_codes: 10 ,
    	 omniauth_providers: [:facebook, :twitter, :line,]

    belongs_to :account, inverse_of: :user, required: true
    accepts_nested_attributes_for :account

    validates :locale, inclusion: I18n.available_locales.map(&:to_s), unless: 'locale.nil?'
    validates :email, email: true

    scope :recent,    -> { order('id desc') }
    scope :admins,    -> { where(admin: true) }
    scope :confirmed, -> { where.not(confirmed_at: nil) }

    def self.find_or_create_by_oauth_authorization(uid:, type:, name:, email:, display_name:)
        user = nil
        ga = OAuthAuthorization.find_by(uid: uid, type: type)
        return ga.user if ga
        transaction do
            user = create!(
                confirmed_at: Time.current,
                email: email,
                password: SecureRandom.hex(24),
                account_attributes: {
                    username: name.tr('-', '_').slice(0, 30),
                    display_name: display_name,
                    }
                )
            OAuthAuthorization.find_or_create_by!(uid: uid, type: type, name: name, account_id: user.account_id)
        end
        user
    end

    def confirmed?
        confirmed_at.present?
    end

    def email_required?
        (authenticatable_salt.empty? || !email.blank?) && super
    end
    
    def send_devise_notification(notification, *args)
        devise_mailer.send(notification, self, *args).deliver_later if email.present?
    end

    def setting_default_privacy
        settings.default_privacy || (account.locked? ? 'private' : 'public')
    end

    def setting_boost_modal
        settings.boost_modal
    end

    def setting_auto_play_gif
        settings.auto_play_gif
    end
end