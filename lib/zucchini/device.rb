# FIXME: This needs to be refactored into a class (@vaskas).

module Zucchini
  module Device

    private

    def device_params(device)
      if is_simulator?(device)
        "-w \"#{device[:simulator]}\""
      else
        "-w #{device[:udid]}"
      end
    end

    def install_app(device_id, app_path)
      "xcrun simctl install #{device_id} #{app_path}".tap do |cmd|
        raise "failed to install app: #{cmd}" unless system(cmd)
      end
    end

    def uninstall_app(device_id, bundle_id)
      "xcrun simctl uninstall #{device_id} #{bundle_id}".tap do |cmd|
        p "failed to uninstall app: #{cmd}" unless system(cmd)
      end
    end

    def simulator_pid
      `ps ax|awk '/iOS Simulator.app\\/Contents\\/MacOS\\/iOS Simulator/{print $1}'`.chomp
    end

    def start_simulator(device_id)
      if "xcrun simctl list | grep \"#{device_id}.*Booted\"".empty?
        puts "-- set startup if for simulator"
        `defaults write com.apple.iphonesimulator CurrentDeviceUDID #{device_id}`
        sim = `xcode-select -print-path`.gsub(/\n/, '') + "/Applications/iOS\\ Simulator.app"
        puts "-- start simulator"
        `open #{sim}`
        sleep(5)
      end
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
      device[:name] == 'iOS Simulator' || device[:simulator]
    end
  end
end
