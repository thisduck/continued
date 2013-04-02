class BuildMailer < ActionMailer::Base
  default from: CONTINUE_CONFIG['from_email']

  def build_trying(project)
    mail to: CONTINUE_CONFIG['emails'],
      subject: "Build trying for #{project_name project} [#{Time.now}]"
  end

  def build_started(build)
    @build = build
    mail to: CONTINUE_CONFIG['emails'],
      subject: "Build started for #{project_name build.project} [#{build.id}]"
  end

  def build_finished(build)
    @build = build
    mail to: CONTINUE_CONFIG['emails'],
      subject: "Build finished for #{project_name build.project} [#{build.id}]"
  end

  protected

  def project_name(project)
    "#{project.name}:#{project.branch}"
  end
end
