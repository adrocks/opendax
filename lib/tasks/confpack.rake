require 'fog/google'

namespace :confpack do

  @basename = 'opendax_confpack'
  @credentials_basename = "#{@basename}_credentials"
  @password = File.read('config/master.key')
  @bucket = {}

  top_level = self

  using Module.new {
    refine(top_level.singleton_class) do
      def set_bucket
        Dir.chdir('config') do
          unless (File.exist?("confpack.json")) then
            puts "Not found config/confpack.json."
            puts "At first, you have to input 3 values to use (only once)."
            print "Bucket name: "
            @bucket['name'] = STDIN.gets.chomp
            print "Access key: "
            @bucket['accessKey'] = STDIN.gets.chomp
            print "Secret key: "
            @bucket['secretKey'] = STDIN.gets.chomp
            File.write('confpack.json', @bucket.to_json)
          end
          @bucket = JSON.parse(File.read('confpack.json'))
        end
      end
    end
  } 

  desc 'Backup ~/opendax_credentials into GCP storage bucket.'
  task :cbackup do
    unless (Dir.exist?('../opendax_credentials')) then
      puts ('Not found ~/opendax_credentials')
      next
    end
    set_bucket
    Dir.chdir('..') do
      sh "tar cvzf #{@credentials_basename}.tgz opendax_credentials"
      sh "openssl aes-256-cbc -e -pbkdf2 "+
          "-in #{@credentials_basename}.tgz "+
          "-out #{@credentials_basename}.tgz.enc "+
          "-pass pass:#{@password}"
      sh "rm -f #{@credentials_basename}.tgz"
      # Also can be done by gsutil but
      # another proper credentials needed by gcloud auth login
      #sh "gsutil cp #{@credentials_basename}.tgz.enc gs://#{@bucket}/"
    end
    begin
      google_storage = Fog::Storage::Google.new(
        :google_storage_access_key_id => @bucket['accessKey'],
        :google_storage_secret_access_key =>  @bucket['secretKey']
      )
      content = File.read("../#{@credentials_basename}.tgz.enc")
      google_storage.put_object(
        @bucket['name'], "#{@credentials_basename}.tgz.enc", content)
    rescue
      puts "Cannot access to GCP."
      puts "Maybe incorrect config/confpack.json. Erase it and retry."
    ensure
      sh "rm -f ../#{@credentials_basename}.tgz.enc"
    end
  end

  desc 'Restore ~/opendax_credentials from GCP storage bucket.'
  task :crestore do
  end

  desc 'Backup all opendax conf into GCP storage bucket.'
  task :backup do
  end

  desc 'Restore all opendax conf from GCP storage bucket.'
  task :restore do
  end


end