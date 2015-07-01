require 'json'
require 'net/ssh'
require "thread"

raw_agents_payload=`curl -u #{ENV["GO_USERNAME"]}:#{ENV["GO_PASSWORD"]} -f0 #{ENV["GO_AGENTS_API"]}`

agents_payload = JSON.parse(raw_agents_payload);

agents_payload.each do |agent|
  Thread.new do
    if agent["status"] == "Building (Cancelled)"
      go_agent_name = agent["sandbox"].split("/").last

      Net::SSH.start(agent["agent_name"], ENV["GO_SSH_USERNAME"], :password => ENV["GO_SSH_PASSWORD"]) do |ssh|
        ssh.open_channel do |channel|

          channel.exec("service #{go_agent_name} restart") do |channel, success|
            if success
              channel.on_data do |channel, data|
                puts "Restarting #{agent["agent_name"]} agent: output -> #{data.inspect}"
              end
            else
              puts "FAILED to restart agent: #{agent["agent_name"]}"
            end
          end

          puts "waiting..."
          channel.wait
          puts "JOB DONE! SUCCESS!!!"

        end
      end
    end
  end
end

Thread.list.each do |thread|
  thread.join unless Thread.main === thread
end
