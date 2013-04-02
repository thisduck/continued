class Project
  include MongoMapper::Document

  key :name, String
  key :repository_url, String
  key :branch, String
  key :last_sha, String
  timestamps!

  has_many :builds

  def self.build_all
    Project.all.each do |project|
      next if project.builds.running.any?
      Build.delay.for project.id
    end
  end

  def setup!
    clone_repository
    update_sha
    save!
  end

  def repository_path
    File.join CONTINUE_CONFIG['repositories_path'], name.parameterize, branch
  end

  def clone_repository
    FileUtils.mkdir_p repository_path

    repo = begin
      repository
    rescue ArgumentError
      Git.clone(repository_url, "#{name.parameterize}/#{branch}", :path => CONTINUE_CONFIG['repositories_path'])
    end

    repo.branch(branch).checkout
    repo
  end

  def repository_or_clone
    clone_repository
  end

  def repository
    return @repository if @repository

    repo = Git.open(repository_path)
    repo.branch(branch).checkout
    @repository = repo
  end

  def update_sha
    self.last_sha = repository.log.first.sha
  end

  def update_sha!
    update_sha
    save!
  end

  def pull_hard!
    repository.reset_hard
    clean
    repository.branch(branch).checkout
    repository.fetch
    repository.reset_hard("origin/#{branch}")
    repository.pull(repository.repo, repository.branch(branch))

    update_sha!
  end

  def clean
    repository.chdir do
      repository.status.untracked.each do |file|
        File.unlink file.first
      end
    end
  end

  def run_build
    runner = Runner.new
    user = `whoami`.strip
    repository.chdir do
      runner.run "sudo su #{user} -c 'cd #{repository_path}; ./bin/build.sh'"
    end

    runner
  end
end
