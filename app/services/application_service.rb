# frozen_string_literal: true

class ApplicationService
  def self.call(...)
    new(...).call
  end

  Result = Struct.new(:success?, :data, :error, keyword_init: true) do
    def failure?
      !success?
    end
  end

  private

  def success(data = {})
    Result.new(success?: true, data: data)
  end

  def failure(error)
    Result.new(success?: false, error: error)
  end
end
