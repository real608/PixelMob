class Video
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Token
    include Mongoid::Elasticsearch
    field :id, type:              String
    field :name, type:            String
    field :description, type:     String
    field :processing, type:      Boolean, default: true
    field :is1080p, type:         Boolean
    field :is720p, type:          Boolean
    field :finished720p, type:    Boolean
    field :finished360p, type:    Boolean
    field :finished1080, type:    Boolean
    field :is_video, type:        Boolean
    field :viewsMetadata, type:   Array
    field :progress360p, type:    Integer, default: 0
    field :progress1080p, type:   Integer, default: 0
    field :progress720p, type:    Integer, default: 0
    field :tempProgress, type:    Float, default: 0
    field :progress, type:        Float, default: 0
    field :file_tmp, type:        String
    field :vast, type:            String
    field :view_count, type:      Integer
    field :downVotedUsers, type:  Array, default: []
    field :rank, type:            Float
    has_and_belongs_to_many :viewsUsers, :class_name => 'User', :inverse_of => :viewedVideos
    has_many :video_views
    has_many :annotations
    has_and_belongs_to_many :downVotedUsers, :class_name => 'User', :inverse_of => :downVotedVideos
    has_and_belongs_to_many :upVotedUsers, :class_name => 'User', :inverse_of => :upVotedVideos
    has_and_belongs_to_many :tags
    has_many :comments
    belongs_to :channel
    belongs_to :game
    elasticsearch!
    token
    mount_uploader :file,VideoUploader
    store_in_background :file
    attr_accessor :is_video
    attr_readonly :upVotes, :upVoted, :downVotes, :downVoted, :owned, :smallName, :votes, :views
    def upVotes
    self.upVotedUsers.length
    end
    def progressCallback(progress)
        if(progress == 1) then
            self.progress =+ self.tempProgress
        end
        progressMultipler = 1
        if(self.is1080p)
            progressMultipler = 0.33
        elsif (self.is720p)
            progressMultipler = 0.5
        end
        self.tempProgress = progress * 100 * progressMultipler
        EM.run {
            client = Faye::Client.new("http://localhost:8008/faye")
            publication = client.publish('/videoProgress/' + self.id, :progress => self.progress + self.tempProgress)
            publication.callback    do
                EM.stop
            end
            publication.errback do
                EM.stop
            end
        }
        if self.tempProgress.round == 100
            self.processing = false
        end
    end
    def encodeCallback720p(format, opts)
        self.finished720p = true
    end
    def encodeCallback360p(format, opts)
        self.finished360p = true
    end
    def encodeCallback1080p(format, opts)
        self.finished1080p = true
    end
    def slug
        if(self.name)
            return self.name.gsub ' ', '_'
        else
            return ""
        end
    end
    def downVotes
            self.downVotedUsers.length
    end
    def upVoted
        if(User.current)
                    self.upVotedUsers.include?(User.current)
        else
                false
        end
    end
    def downVoted
        if(User.current)
            self.downVotedUsers.include?(User.current)
        else
                false
        end
    end
    def smallName
            if(self.name) then
                    if(self.name.length > 13)
                        words = self.name[0..13].split(" ")
                        words.delete(words.last)
                        return words.join(" ")
                end
            end
    end
    def votes
            return self.upVotes - self.downVotes
    end
    def to_indexed_json
        self.to_json
    end
    def owned
        if self.channel then
            if User.current then
                self.channel.users.include?(User.current)
            end
        end
    end
    def file_changed?
        return self.processing
    end

    def is1080p
        if(self.is_processed)    then
            m = FFMPEG::Movie.new(self.file.path)
            m.width >= 1920 && m.height >= 1080
        elsif(File.exist?(Rails.root.to_s + "/public/tmp" + self.file_tmp))
            m = FFMPEG::Movie.new(Rails.root.to_s + "/public/tmp" + self.file_tmp)
            m.width >= 1920 && m.height >= 1080

        else
            false
        end
    end
    def views
            self.video_views.length
    end
    def is_video
      self.name && self.channel_id && !self.processing
    end
    def is_processed
        if(self.file.path != nil)
            self.file.path.split('/').last != "_old_"
        else
            false
        end
    end
    def isProcessing
        (self.tempProgress != 0)
    end
    def is720p
        if(self.is_processed)    then
            m = FFMPEG::Movie.new(self.file.path)
            m.width >= 1280 && m.height >= 720
        elsif(File.exist?(Rails.root.to_s + "/public/tmp" + self.file_tmp))
            m = FFMPEG::Movie.new(Rails.root.to_s + "/public/tmp" + self.file_tmp)
            m.width >= 1280 && m.height >= 720
        else
            false
        end
    end
end
