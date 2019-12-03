class ProxyController < ApplicationController

  @@cache = PStore.new("cookies.pstore")

=begin
  @@agent = Mechanize.new


  def redirect_response(uri_str, limit = 10)

    uri = URI(uri_str)
    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPSuccess then
      response
    when Net::HTTPRedirection then
      warn "redirected to #{response['location']}"
      redirect_response(response['location'],limit-1)
    else
      response
    end

  end

  def get_resource uri_str = 'https://agenda.registraduria.gov.co/agenda/'

    response = redirect_response(uri_str)
    @@cache.transaction do
      @@cache[:cookies] = response['Set-Cookie']
    end
    render plain: response.body
  end

  def resend_params url_string = 'https://agenda.registraduria.gov.co/agenda/'
    @@page = @@agent.get(url_string)

    form = @@page.form_with(:id => 'form')

    form.field_with(:name => 'g-recaptcha-response').value = '11'
    form.field_with(:name => 'tipo_id').value = params[:tipo_id]
    form.field_with(:name => 'nuip').value = params[:nuip]
    form.field_with(:name => 'token').value = params[:token]
    page_result = form.click_button

    inputs = form.search('input')
    puts "params #{inputs}"
    #form.field_with(:name => "g-recaptcha-response").value = params[:g_recaptcha_response]
    page_result=@@agent.post(params[:url], {
        "g-recaptcha-response" => "11",
        "tipo_id" => params[:tipo_id],
        "nuip" => params[:nuip],*
        "token" => inputs.field_with(:name => 'token').value,
        "enviar" => params[:enviar]
    })
    form.g_recaptcha_response = response[:g_recaptcha_response]
    form.tipo_id = params[:tipo_id]
    form.nuip = params[:nuip]
    form.token = params[:token]
    page = @@agent.submit(form,form.buttons.first)
    pp page_result
    render plain: page_result.body
  end
=end


  def redirect_response(uri_str, limit = 10)

    raise ArgumentError, 'too many HTTP redirects' if limit == 0

    uri = URI(uri_str)
    #http = Net::HTTP.new(uri.hostname)

    request = Net::HTTP::Get.new(uri)

    request['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36'

    #request.add_field('user-agent', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36')


    @@cache.transaction do
      request['Cookie'] = @@cache[:cookies]
    end


    #response = Net::HTTP.get_response(uri)

    #response = http.get(uri.request_uri, { #
    #         'Cookie' => $cookie
    #    }
    #)
    puts "_______________REQUEST HEADER_________________"
    request.each_header do |header_name, header_value|
      puts "#{header_name}: #{header_value}"
    end

    response = Net::HTTP.start(uri.hostname, uri.port,
                    :use_ssl => uri.scheme == 'https') do |http|
      http.request(request)
    end
    #response = Net::HTTP.start(uri.hostname) do |http|
    #  http.request(request)
    #end

    @@cache.transaction do
      #@@cache[:cookies] = response['Set-Cookie']
      @@cache[:cookies] = response.get_fields('Set-Cookie')
    end

    #Handler redirections
    puts "Start redirections"
    case response
    when Net::HTTPSuccess then

      puts "_______________RESPONSE HEADER_________________"
      response.each_header do |header_name, header_value|
        puts "#{header_name} : #{header_value}"
      end
      puts "End redirections"
      response

    when Net::HTTPRedirection then
      location = response['location']

      puts "Redirection # #{10-limit+1}"
      puts "_______________RESPONSE HEADER_________________"
      response.each_header do |header_name, header_value|
        puts "#{header_name} : #{header_value}"
      end

      warn "redirected to #{location}"
      redirect_response(location,limit-1)
    else
      response
    end
  end

  def get_resource(uri_str = 'https://agenda.registraduria.gov.co/agenda/')
    #response = Net::HTTP.get_response('www.example.com','/index.html')
    #response = Net::HTTP.get_response('agenda.registraduria.gov.co','/agenda/')
    response = redirect_response(uri_str)


    render plain: response.body

  end


  def resend_params
    uri = URI(params[:url])
    puts params
    request = Net::HTTP::Post.new(uri)
    #request.set_form_data('firstname'=>"jorge",'lastname'=>"zapata",'color'=>"Blue",
    #    'myHiddenField1'=>"HiddenValue1",'myHiddenField2'=>"HiddenValue2")
    request['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36'

    @@cache.transaction do
      request['Cookie'] = @@cache[:cookies]
    end

    request.set_form_data('g-recaptcha-response'=>'11',
                          'tipo_id'=>params[:tipo_id],'nuip'=>params[:nuip],
                          'token'=>params[:token],'enviar'=>params[:enviar])

    puts "_______________REQUEST HEADER_________________"
    request.each_header do |header_name, header_value|
      puts "#{header_name} : #{header_value}"
    end

    response = Net::HTTP.start(uri.hostname, uri.port,
                              :use_ssl => uri.scheme == 'https') do |http|
      http.request(request)
    end

    puts "_______________RESPONSE HEADER_________________"
    response.each_header do |header_name, header_value|
      puts "#{header_name} : #{header_value}"
    end

      case response

    when Net::HTTPSuccess
      render plain: response.body
    when Net::HTTPRedirection
      response = redirect_response(response['location'])
      render plain: response.body
    else
      response.value
    end
  end
end

