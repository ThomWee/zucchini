# FIXME: This needs to be refactored into a class (@vaskas).

module Zucchini
  module Device

    def install_sim(os_ver, device_type)
      simctl = `xcode-select -print-path`.gsub(/\n/, '') + "/usr/bin/simctl"
      if File.exists?(simctl)
        puts "--- install Zucchini simulator ---"
        Zucchini::Config.sim_guid = `#{simctl} list | grep Zucchini_Simulator | sed "s/[^(]*(\\([^)]*\\)).*/\\1/"`.split(/\r?\n/).last
        
        if !Zucchini::Config.sim_guid.nil?
          puts "- delete earlier created simulator (#{Zucchini::Config.sim_guid})"
          uninstall_sim
        end
        
        Zucchini::Config.sim_guid = `#{simctl} create Zucchini_Simulator #{device_type} #{os_ver}`.chomp
        puts "- created #{Zucchini::Config.sim_guid}"
      end
    end

    def uninstall_sim
      stop_active_simulator()
      sleep(1)
      simctl = `xcode-select -print-path`.gsub(/\n/, '') + "/usr/bin/simctl"
      if File.exists?(simctl)
        puts "--- remove Zucchini simulator ---"
        begin
          puts Timeout::timeout(30) {
            `#{simctl} delete #{Zucchini::Config.sim_guid}`
          }
        
        rescue Timeout::Error
          puts "- timed out to delete simulator #{Zucchini::Config.sim_guid}"
        end
      end
    end

    def install_app(app_src)
      simctl = `xcode-select -print-path`.gsub(/\n/, '') + "/usr/bin/simctl"
      if File.exists?(simctl)
        stop_active_simulator()
        puts "- intall app into simulator #{Zucchini::Config.sim_guid}"
        `#{simctl} boot #{Zucchini::Config.sim_guid}`
        `#{simctl} install #{Zucchini::Config.sim_guid} "#{app_src}"`
        `#{simctl} shutdown #{Zucchini::Config.sim_guid}`
      end
    end
    
    private

    def device_params(device)
      if is_simulator?(device)
        "-w #{Zucchini::Config.sim_guid}"
      else
        "-w #{device[:udid]}"
      end
    end

    def simulator_pid
      `ps ax|awk '/iOS Simulator.app\\/Contents\\/MacOS\\/iOS Simulator/{print $1}'`.chomp
    end

    def start_simulator(device)
      puts "-- set startup if for simulator"
      dev_id = Zucchini::Config.sim_guid
      `defaults write com.apple.iphonesimulator CurrentDeviceUDID #{dev_id}`
      sim = `xcode-select -print-path`.gsub(/\n/, '') + "/Applications/iOS\\ Simulator.app"
      puts "-- start simulator"
      `open #{sim}`
      sleep(5)
    end

    def stop_active_simulator()
      unless simulator_pid().empty?
        puts "- stop simulator"
        Process.kill('INT', simulator_pid().to_i) 
        begin
          sleep(0.5)
        end while simulator_pid().nil?
      end
    end

    def is_simulator?(device)
      device[:name] == 'iOS Simulator' || defined? Zucchini::Config.sim_guid
    end
  end
end
