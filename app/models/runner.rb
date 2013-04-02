class Runner
  CommandError = Class.new(Exception)

  def run(command)
    result = %x(#{command}).strip
    @return_code = $?

    result
  end

  def return_code
    @return_code
  end

  def success?
    return_code == 0
  end

  def run!(command)
    run(command).tap do |result|
      raise CommandError.new($?) if $? != 0
    end
  end
end
