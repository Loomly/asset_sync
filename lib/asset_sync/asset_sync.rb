require "logger"

module AssetSync

  class << self

    def config=(data)
      @config = data
    end

    def config
      @config ||= Config.new
      @config
    end

    def reset_config!
      remove_instance_variable :@config if defined?(@config)
    end

    def configure(&proc)
      @config ||= Config.new
      yield @config
    end

    def storage
      @storage ||= Storage.new(self.config)
    end

    def sync
      with_config do
        self.storage.sync
      end
    end

    def clean
      with_config do
        self.storage.delete_extra_remote_files
      end
    end

    def with_config(&block)
      return unless AssetSync.enabled?

      errors = config.valid? ? "" : config.errors.full_messages.join(', ')

      if !(config && config.valid?)
        if config.fail_silently?
          self.warn(errors)
        else
          raise Config::Invalid.new(errors)
        end
      else
        block.call
      end
    end

    def warn(msg)
      stderr.puts msg
    end

    def log(msg)
      unless config.log_silently?
        stdout.puts msg
        file_logger.info msg if config.file_logger_path
      end
    end

    def file_logger
      return nil unless config.file_logger_path
      @file_logger ||= Logger.new(config.file_logger_path)
    end

    def enabled?
      config.enabled?
    end

    # easier to stub
    def stderr ; STDERR ; end
    def stdout ; STDOUT ; end

  end

end
