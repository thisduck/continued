class Build
  include MongoMapper::Document

  key :state, String
  key :output, String
  key :last_sha, String
  key :sha, String
  key :started_at, Time
  key :ended_at, Time
  key :logs, Array
  key :diff, String
  timestamps!

  belongs_to :project

  def self.for project, options = {}
    last_sha = project.last_sha
    project.pull_hard!

    return if !options[:force] && last_sha == project.last_sha

    build = self.new({
      :project => project,
      :sha => project.last_sha,
      :last_sha => last_sha,
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

    collect_diff_info
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

  def collect_diff_info
    return if success? || last_sha.blank?
    self.logs = project.repository.log.between(last_sa, sha).collect(&:to_hash)
    self.diff = project.repository.diff(last_sha, sha).patch
  end

  def collect_diff_info!
    collect_diff_info
    save!
  end
end
