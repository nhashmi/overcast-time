require 'rubygems'
require 'mechanize'
require 'figaro'
require 'nokogiri'
require 'io/console'

class OvercastTime

  def initialize
    puts "Please enter your Overcast.fm username (your email address)."
    email = gets.chomp
    print "Please enter your Overcast.fm password: "
    password = STDIN.noecho(&:gets).chomp
    fname = "lib/application.yml"
    secrets = File.open(fname, "w")
    secrets.puts("overcast_user_name: " + email)
    secrets.puts("overcast_password: " + password)
    secrets.close
    Figaro.application = Figaro::Application.new(environment: "production", path: "lib/application.yml")
    Figaro.load

    agent = Mechanize.new

    page = agent.get("http://overcast.fm")

    login_page = agent.page.link_with(:text => 'Log In').click

    login_form = login_page.forms[0]

    puts ENV['overcast_user_name']

    login_form.email = ENV['overcast_user_name']
    login_form.password = ENV['overcast_password']

    podcasts = agent.submit(login_form, login_form.buttons[2])

    times = podcasts.search('div.caption2')

    total_seconds = 0

    times.each do |time|
      timestamp = time.text.match(/([0-9]+:)([0-9]+:)([0-9]+)/)
      if timestamp
        hours = timestamp[1][0...-1].to_i
        total_seconds += hours * 3600
        minutes = timestamp[2][0...-1].to_i
        total_seconds += minutes * 60
        seconds = timestamp[3].to_i
        total_seconds += seconds
      end
    end

    mm, ss = total_seconds.divmod(60)
    hh, mm = mm.divmod(60)

    puts "You have %d hours, %d minutes, and %d seconds of unheard podcasts remaining." % [hh, mm, ss]

    File.delete("lib/application.yml")

    return total_seconds

  end
end
