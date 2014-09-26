# FIXME: This needs to be refactored into a class (@vaskas).

module Zucchini
  module Device

    def install_sim(os_ver, device_type)
      simctl = `xcode-select -print-path`.gsub(/\n/, '') + "/usr/bin/simctl"
      if File.exists?(simctl)
        puts "--- install Zucchini simulator ---"
        Zucchini::Config.sim_guid = `#{simctl} list | grep Zucchini_Simulator | sed "s/[^(]*(\\([^)]*\\)).*/\\1/"`.split(/\r?\n/).last
        
        if Zucchini::Config.sim_guid.nil?
          Zucchini::Config.sim_guid = `#{simctl} create Zucchini_Simulator #{device_type} #{os_ver}`.chomp
          puts "- created #{Zucchini::Config.sim_guid}"
        else
          puts "- reuse earlier created simulator (#{Zucchini::Config.sim_guid})"
          stop_active_simulator()
          sleep(1)
          `#{simctl} erase #{Zucchini::Config.sim_guid}`
        end
      end
    end

    def uninstall_sim
      stop_active_simulator()
      simctl = `xcode-select -print-path`.gsub(/\n/, '') + "/usr/bin/simctl"
      if File.exists?(simctl)
        puts "--- remove Zucchini simulator ---"
        puts Timeout::timeout(10) {
          `#{simctl} delete #{Zucchini::Config.sim_guid}`
        }
      end
    end

    def install_app(app_src)
      simctl = `xcode-select -print-path`.gsub(/\n/, '') + "/usr/bin/simctl"
      if File.exists?(simctl)
        puts "- intall app into simulator"
        `#{simctl} boot #{Zucchini::Config.sim_guid}`
        `#{simctl} install #{Zucchini::Config.sim_guid} "#{app_src}"`
        `#{simctl} shutdown #{Zucchini::Config.sim_guid}`
      end
    end
    
    private

    def device_params(device)
      if is_simulator?(device)
        if defined? Zucchini::Config.sim_guid
          "-w \"#{device[:simulator]}\""
        else
          "-w #{Zucchini::Config.sim_guid}"
        end
      else
        "-w #{device[:udid]}"
      end
    end

    def simulator_pid
      `ps ax|awk '/iOS Simulator.app\\/Contents\\/MacOS\\/iOS Simulator/{print $1}'`.chomp
    end

    def start_simulator(device)
      if simulator_pid.nil?
        dev_id = device[:simulator] || Zucchini::Config.sim_guid
        puts "-- set startup if for simulator"
        `defaults write com.apple.iphonesimulator CurrentDeviceUDID #{dev_id}`
        sim = `xcode-select -print-path`.gsub(/\n/, '') + "/Applications/iOS\\ Simulator.app"
        puts "-- start simulator"
        `open #{sim}`
        sleep(5)
      end
    end

    def stop_active_simulator()
      Process.kill('INT', simulator_pid.to_i) unless simulator_pid.empty?
    end

    def is_simulator?(device)
      device[:name] == 'iOS Simulator' || device[:simulator] || defined? Zucchini::Config.sim_guid
    end
  end
end
