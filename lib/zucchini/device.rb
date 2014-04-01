# FIXME: This needs to be refactored into a class (@vaskas).

module Zucchini
  module Device

    private

    def device_params(device)
      if is_simulator?(device)
        set_simulator_device(device)
        "-w \"#{device[:simulator]}\""
      else
        "-w #{device[:udid]}"
      end
    end

    def set_simulator_device(device)
      return unless device[:simulator].is_a?(String)

      current_simulated_device = `defaults read com.apple.iphonesimulator "SimulateDevice"`.chomp
      if current_simulated_device != device[:simulator]
        simulator_pid = `ps ax|awk '/[i]Phone Simulator.app\\/Contents\\/MacOS\\/iPhone Simulator/{print $1}'`.chomp
        Process.kill('INT', simulator_pid.to_i) unless simulator_pid.empty?
        `defaults write com.apple.iphonesimulator "SimulateDevice" '"#{device[:simulator]}"'`
      end
    end

    def is_simulator?(device)
      device[:name] == 'iOS Simulator' || device[:simulator]
    end
  end
end
