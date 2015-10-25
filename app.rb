class App < Sinatra::Base
  get '/' do
    haml :index
  end

  get '/protected' do
    authenticate_user!
    @user = nil
    haml :protected
  end


  private
  def authenticate_user!
    unless logged_in?
      if service_ticket?
        validate
      else
        login
      end
    end
  end

  def service_ticket?
    params[:ticket]
  end

  def login
    redirect "http://localhost:7890/login?service=#{URI.encode("http://localhost:4567")}"
  end

  def validate
    hash = {
      service: URI.encode("http://localhost:4567"),
      ticket: params[:ticket]
    }

    xml_response = HTTParty.get("http://localhost:7890/p3/serviceValidate?#{parameterize(hash)}").body
    xml = Nokogiri::XML xml_response

    if xml.xpath("//cas:authenticationSuccess")
      session[:user] = { email: xml.xpath("//cas:user").text }
      redirect "/"
    else
      @error = xml.xpath("//cas:authenticationFailure").text
    end
  end

  def parameterize hash
    hash.map { |k, v| "#{k.to_s}=#{v}" }.join "&"
  end
end
