require 'faker'
require 'spreadsheet'

namespace :redmine do
  namespace :intercom do

    def createUser(firstName = nil, lastName = nil)      
      user = User.new
      user.login = Faker::Bitcoin.address
      # user.login = lastName
      user.mail = Faker::Internet.email
      if firstName.nil?
        user.firstname = Faker::Name.name
      else
        user.firstname = firstName
      end

      if lastName.nil?
        user.lastname = Faker::Name.name
      else
        user.lastname = lastName
      end      
      user.password = 'password'
      user.password_confirmation = 'password'
      user.identity_url = 'demo'
      user.save!
    end

    task :generate_fake_users => :environment do
      User.destroy_all(:identity_url => "http://demo/")
      # 11.times do |t|
      #   createUser()
      # end      
      filePath = File.expand_path('../../../data/person.xls', __FILE__)
      if File.exists?(filePath)                
        file = Spreadsheet.open(filePath)
        sheet = file.worksheet(0)

        sheet.rows.each do |t|            
          if (t[0] != "STUB")
            if (t[0]) # has first last
              createUser(t[0], t[1])
            else 
              fio = t[3].split(' ')
              # puts fio[0], fio[1]
              createUser(fio[0], fio[1])
            end
          end
        end
      end
    end  

    task :load_profiles => :environment do
      UserProfile.destroy_all(conditions = nil)            
      # filePath = File.expand_path('../../../data/person.csv', __FILE__)            
      filePath = File.expand_path('../../../data/person.xls', __FILE__)
      if File.exists?(filePath)        
        # file = File.open(filePath)        
        file = Spreadsheet.open(filePath)
        sheet = file.worksheet(0)
        # file.readline
        sheet.rows.each do |t|  
          if (t[0] != "STUB")
            if (t[0]) # has first last
              firstN = t[0]
              lastN = t[1]
            else 
              fio = t[3].split(' ')
              firstN = fio[0]
              lastN = fio[1]
            end
          end          
          imageName = "#{firstN} #{lastN}.png"
          user = User.find(:first, :conditions => ["firstname =? and lastname =?",firstN, lastN])
          if user.nil?      
            puts "User not found: "+ imageName
          else
            person = UserProfile.new
            person.user_id    = user.id   
            puts t[9]         
            data = { 'skills' => t[9], 'position' => t[4],
             'summary' => t[8], 'birthday' => 'TBD', 'project' => t[7]}
            person.data = data.to_json

            imagePath = File.expand_path("../../../data/#{imageName}", __FILE__)
            if File.exists?(imagePath)
              file = File.open(imagePath)
              puts "here", t[0], t[1]
              person.avatar = file
              file.close
            end
            person.save! 
            puts "."           
          end
        end

        # file.each do |t|          
        #   items = t.split(",")
        #   firstN  = items[0].strip()
        #   lastN  = items[1].strip()
        #   imageName = "#{firstN} #{lastN}.png"
        #   user = User.find(:first, :conditions => ["firstname =? and lastname =?",firstN, lastN])
        #   if user.nil?      
        #     puts "User not found: "+ imageName                  
        #   else
        #     person = UserProfile.new
        #     person.user_id    = user.id            
        #     data = { 'skills' => items[4], 'position' => items[2],
        #      'summary' => items[3], 'birthday' => items[5], 'project' => items[6]}
        #     person.data = data.to_json

        #     imagePath = File.expand_path("../../../data/#{imageName}", __FILE__)
        #     if File.exists?(imagePath)
        #       file = File.open(imagePath)
        #       person.avatar = file
        #       file.close
        #     end
        #     person.save! 
        #     puts "."           
        #   end
        # end
      else
        puts "File not exist"
      end      
    end

    task :check_profiles => :environment do
      puts "start...."
      @users = User.select("users.id, users.login, users.mail, users.firstname, users.lastname, user_profile_t.skills, user_profile_t.avatar_file_name avatar")
      .joins("LEFT JOIN #{UserProfile.table_name} ON #{User.table_name}.id = #{UserProfile.table_name}.user_id")  

      ids = @users.all.map { |x| x.id }
      @profiles = UserProfile.where(:user_id => ids)
      
      for i in @users        
        if profile = @profiles.find_by_user_id(i)          
          i.avatar = profile.avatar_url
        end        
      end

      for i in @users
        puts i.avatar
      end
    end
  end
end
