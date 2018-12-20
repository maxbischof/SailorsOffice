class SlackController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    parameter = params[:text].split
    user = User.where(slack_name: params[:user_name])[0][:id]
    regatta = Regatta.where(name: params[:channel_name])[0]

    valid_request = request_validation

    if valid_request == true
      if regatta.balances.first.closed == true
        render :plain => "Die Abrechnung für die #{regatta[:name]} Regatta wurde bereits am #{regatta.balances.first.closing_date} geschlossen. Rechnung wurde nicht eingereicht."
      elsif regatta.balances.first.closed == false
        Invoice.create(regatta_id: regatta[:id], user_id: user, name: parameter.first, price: parameter.second)
        render :plain => "Die Rechnung von #{parameter.first} bei der #{regatta[:name]} Regatta über #{parameter.second}€ wurde erstellt."
      end
    else
      render :plain => "Request nicht gültig."
    end
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

    return valid_request
  end
end
