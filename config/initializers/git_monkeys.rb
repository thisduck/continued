module Git
  class Object
    class Commit
      def to_hash
        {
          :sha => sha,
          :author => "#{author.name} <#{author.email}>",
          :date => author_date,
          :parents => parents.collect(&:to_s),
          :message => message,
        }
      end
    end
  end
end

