class SlackController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    parameter = params[:text].split
    user = User.where(slack_name: params[:user_name])[0]
    regatta = Regatta.where(name: params[:channel_name].capitalize)[0]

    valid_request = request_validation
		if regatta.blank?
			render :plain => "The #{params[:channel_name].capitalize} regatta can't be found in the Tintoapp. Please create #{params[:channel_name].capitalize} regatta in Tintoapp."
    elsif valid_request == true
      if regatta.balance[:closed] == true
        render :plain => "Die Abrechnung für die #{regatta[:name]} Regatta" \
                         "wurde bereits am #{regatta.balance[:closing_date]}" \
                         " geschlossen. Rechnung wurde nicht eingereicht."
      elsif regatta.balance[:closed] == false
        Invoice.create(regatta_id: regatta[:id], user_id: user[:id],
                       name: parameter.first, price: parameter.second)

        render :plain => "Die Rechnung von #{parameter.first} bei der" \
                         " #{regatta[:name]} Regatta über #{parameter.second}€" \
                         " wurde erstellt."
      end
    else
      render :plain => "Request nicht gültig."
    end
  end

	def indexregatta
   	regattas = Regatta.where('extract(year  from startdate) = ?', Time.current.year).order(startdate: :asc)
    valid_request = request_validation

    if valid_request == true
                       string = "Alle Regatten #{Time.current.year}:\n"
                       regattas.each do |regatta|
                               string = string + "#{regatta.name} | #{regatta.startdate} - #{regatta.enddate} | #{regatta.users.all.map(&:name).flatten.join(',')}\n\n"
                       end
      render :plain => string
    else
      render :plain => "Request nicht gültig."
    end
  end

	def create_deposit
		amount = params[:text]
		user = User.where(slack_name: params[:user_name])[0]
		date = Date.today

		valid_request = request_validation

		if valid_request == true
				Deposit.create(amount: amount, user_id: user[:id])

				render :plain => "Die Einzahlung von #{amount} wurde erstellt."
		else
			render :plain => "Request nicht gültig."
		end
	end

	def help
		valid_request = request_validation
		if valid_request == true
			render :plain => '/i [name] [price] - Creates new invoice in regatta channel | /r - Shows regattas | /d [amount] - Create deposit'
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
