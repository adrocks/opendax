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
      def save(tgz_basename, args)
        set_bucket
        Dir.chdir('..') do
          sh "tar cvzf #{tgz_basename}.tgz #{args}"
          sh "openssl aes-256-cbc -e -pbkdf2 "+
              "-in #{tgz_basename}.tgz "+
              "-out #{tgz_basename}.tgz.enc "+
              "-pass pass:#{@password}"
          sh "rm -f #{tgz_basename}.tgz"
        end
        begin
          google_storage = Fog::Storage::Google.new(
            :google_storage_access_key_id => @bucket['accessKey'],
            :google_storage_secret_access_key =>  @bucket['secretKey']
          )
          content = File.read("../#{tgz_basename}.tgz.enc")
          google_storage.put_object(
            @bucket['name'], "#{tgz_basename}.tgz.enc", content)
        rescue
          puts "Cannot access to GCP."
          puts "Maybe because of incorrect config/confpack.json. Erase it and retry."
        ensure
          sh "rm -f ../#{tgz_basename}.tgz.enc"
        end
      end
      def load(tgz_basename)
        set_bucket
        begin
          google_storage = Fog::Storage::Google.new(
            :google_storage_access_key_id => @bucket['accessKey'],
            :google_storage_secret_access_key =>  @bucket['secretKey']
          )
          content = google_storage.get_object(
            @bucket['name'], "#{tgz_basename}.tgz.enc")
          File.write("../#{tgz_basename}.tgz.enc", content.body)
        rescue
          puts "Cannot access to GCP."
          puts "Maybe because of incorrect config/confpack.json. Erase it and retry."
          return
        end
        Dir.chdir('..') do
          sh "openssl aes-256-cbc -d -pbkdf2 "+
              "-in #{tgz_basename}.tgz.enc "+
              "-out #{tgz_basename}.tgz "+
              "-pass pass:#{@password}"
          sh "rm -f #{tgz_basename}.tgz.enc"
          sh "tar xvzf #{tgz_basename}.tgz"
          sh "rm -f #{tgz_basename}.tgz"
        end
      end
    end
  } 

  desc 'Save credentials ~/opendax_credentials into GCP storage bucket.'
  task :save_credentials do
    unless (Dir.exist?('../opendax_credentials')) then
      puts ('Not found ~/opendax_credentials')
      next
    end
    save("#{@credentials_basename}", "opendax_credentials")
  end

  desc 'Load credentials ~/opendax_credentials from GCP storage bucket.'
  task :load_credentials do
    load("#{@credentials_basename}")
  end

  desc 'Save all opendax conf into GCP storage bucket.'
  task :save do
    args = "--exclude sample.app.yml "+
      "opendax/config/secrets/*.key* "+
      "opendax/config/app.yml.d/*.yml "+
      "opendax/config/deploy.yml "+
      "opendax/config/utils.yml"
    save("#{@basename}", args)
  end

  desc 'Load all opendax conf from GCP storage bucket.'
  task :load do
    load("#{@basename}")
  end

end