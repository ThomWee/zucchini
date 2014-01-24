require 'yaml'

module Zucchini
  class Config

    def self.base_path
      @@base_path
    end

    def self.base_path=(base_path)
      @@base_path = base_path
      @@config    = YAML::load(ERB::new(File::read("#{base_path}/support/config.yml")).result)
      @@default_device_name = nil
      devices.each do |device_name, device|
        if device['default']
          raise "Default device already provided" if @@default_device_name
          @@default_device_name = device_name
        end
      end
    end

    def self.app
      device_name  = ENV['ZUCCHINI_DEVICE'] || @@default_device_name
      device       = devices[device_name]
      app_path     = File.absolute_path(device['app'] || @@config['app'] || ENV['ZUCCHINI_APP'])

      if (device_name == 'iOS Simulator' || device['simulator']) && !File.exists?(app_path)
        raise "Can't find application at path #{app_path}"
      end
      app_path
    end

    def self.app_args
      @@config['app_args']
    end

    def self.resolution_name(dimension)
      @@config['resolutions'][dimension.to_i]
    end

    def self.devices
      @@config['devices']
    end

    def self.default_device_name
      @@default_device_name
    end

    def self.device(device_name = nil)
      device_name ||= @@default_device_name
      raise "Neither default device nor ZUCCHINI_DEVICE environment variable was set" unless device_name
      raise "Device '#{device_name}' not listed in config.yml" unless (device = devices[device_name])
      {
        :name        => device_name,
        :udid        => device['UDID'],
        :screen      => device['screen'],
        :simulator   => device['simulator'],
        :orientation => device['orientation'] || 'portrait'
      }
    end

    def self.template
      locations = [
        `xcode-select -print-path`.gsub(/\n/, '') + "/Platforms/iPhoneOS.platform/Developer/Library/Instruments",
         "/Applications/Xcode.app/Contents/Applications/Instruments.app/Contents" # Xcode 4.5
      ].map do |start_path|
        "#{start_path}/PlugIns/AutomationInstrument.bundle/Contents/Resources/Automation.tracetemplate"
      end

      locations.each { |path| return path if File.exists?(path) }
      raise "Can't find Instruments template (tried #{locations.join(', ')})"
    end
  end
end
