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

  def self.running
    where(:state => "running")
  end

  def self.for project, options = {}
    if Build.running.any?
      Build.delay(:run_at => 5.minutes.from_now).for project, options
      return
    end

    if project.is_a?(String) || project.is_a?(BSON::ObjectId)
      project = Project.find project
    end

    #BuildMailer.build_trying(project).deliver

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
    #BuildMailer.build_started(self).deliver
    self.started_at = Time.now

    begin
      results = project.run_build

      outputs = []
      results.each do |result|
        outputs << "COMMAND: #{result.command}"
        outputs << result.output
        outputs << "\n"
      end

      self.output = outputs.join "\n"
      self.state = results.collect(&:success?).all? ? "pass" : "fail"

      self.ended_at = Time.now
      collect_diff_info
    rescue Exception => e
      self.output = "#{e.message}\n\n#{e.backtrace}"
      self.state = "crashed"
    end

    BuildMailer.build_finished(self).deliver if send_finished_email?
  end

  def run!
    run
    save!
  end

  def time_taken
    ended_at - started_at
  end

  def success?
    state == "pass"
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

  def html_output
    file_name = "/tmp/output_#{id}"
    File.open(file_name, "wb") {|f| f.write output }
    result = `cat #{file_name} | aha `
    result =~ /<pre>(.*)<\/pre>/m
    $1
  end

  def send_finished_email?
    !self.success? || !self.project.builds.where(:id.ne => self.id).sort(:created_at).last.try(:success?)
  end
end
