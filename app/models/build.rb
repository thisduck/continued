class Build
  include MongoMapper::Document

  key :state, String
  key :output, String
  key :sha, String
  key :started_at, Time
  key :ended_at, Time
  timestamps!

  belongs_to :project

  def self.for project, options = {}
    last_sha = project.last_sha
    project.pull_hard!

    return if !options[:force] && last_sha == project.last_sha

    build = self.new({
      :project => project,
      :sha => project.last_sha,
      :state => "running",
    })

    build.save!
    build.run!

    build
  end

  def run
    self.started_at = Time.now

    result = project.run_build
    self.output = result.output
    self.state = result.success?? "success" : "fail"

    self.ended_at = Time.now
  end

  def run!
    run
    save!
  end

  def time_taken
    ended_at - started_at
  end

  def success?
    state == "success"
  end
end
