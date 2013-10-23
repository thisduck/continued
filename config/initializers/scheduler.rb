if !defined?(Rails::Console)
  scheduler = Rufus::Scheduler.start_new

 #scheduler.in("1s") do
 #  Project.build_all
 #end

  scheduler.every("5m") do
    Project.build_all
  end
end
