class SlackController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    parameter = params[:text].split
    user = User.where(slack_name: params[:user_name])[0][:id]
    regatta = Regatta.where(name: params[:channel_name])[0]

    request_validation

    if valid_request == true
      if regatta.take.balances.first.closed == true
        render :plain => "Die Abrechnung für die #{regatta_name} Regatta wurde bereits am #{Regatta.where(name: regatta_name).take.balances.first.closing_date} geschlossen. Rechnung wurde nicht eingereicht."
      elsif Regatta.where(name: regatta_name).take.balances.first.closed == false
        Invoice.create(regatta_id: regattaid, user_id: user, name: parameter.first, price: parameter.second)
        render :plain => "Die Rechnung von #{parameter.first} bei der #{regatta_name} Regatta über #{parameter.second}€ wurde erstellt."
      end
    else
      render :plain => "Request nicht gültig."
    end

    private

    def request_validation
      timestamp = request.headers["X-Slack-Request-Timestamp"]
      signature = request.headers["X-Slack-Signature"]
      signing_secret = ENV["SLACK_SECRET"]

      basestring = "v0:#{timestamp}:#{request.body.read}"
      my_signature = "v0=#{OpenSSL::HMAC.hexdigest("SHA256", signing_secret, basestring)}"

      valid_request = ActiveSupport::SecurityUtils.secure_compare(my_signature, signature)

      if Time.at(timestamp.to_i) < 5.minutes.ago
        valid_request = false
      end
    end
  end
end
