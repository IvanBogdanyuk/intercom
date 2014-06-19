require 'faker'
require 'spreadsheet'

namespace :redmine do
  namespace :intercom do

    def createUser(firstName = nil, lastName = nil)      
      user = User.new
      user.login = Faker::Bitcoin.address
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

    task :load_users => :environment do
      User.destroy_all(:identity_url => "http://demo/")
      filePath = File.expand_path('../../../data/person.xls', __FILE__)
      if File.exists?(filePath)                
        file = Spreadsheet.open(filePath)
        sheet = file.worksheet(0)
        sheet.rows.each_with_index do |t,i|            
          if (i != 0) # skip header
            if (t[0]) # has first name
              createUser(t[0], t[1])
            else 
              fio = t[3].split(' ')
              firstname = fio[1]
              lastname = fio[0]
              createUser(firstname, lastname)
            end
          end
        end
      end
    end  

    task :load_profiles => :environment do
      UserProfile.destroy_all(conditions = nil)            
      filePath = File.expand_path('../../../data/person.xls', __FILE__)
      if File.exists?(filePath)         
        file = Spreadsheet.open(filePath)
        sheet = file.worksheet(0)
        sheet.rows.each_with_index do |t,i|  
          if (i != 0) # skip header
            if (t[0]) # has first last
              firstN = t[0]
              lastN = t[1]
            else 
              fio = t[3].split(' ')
              firstN = fio[1]
              lastN = fio[0]
            end
          end          
          imageName = "#{lastN} #{firstN}.png"
          user = User.find(:first, :conditions => ["firstname =? and lastname =?",firstN, lastN])
          if user.nil?      
            puts "User not found: "+ imageName
          else
            person = UserProfile.new
            person.user_id    = user.id      
            data = { 'skills' => t[9], 'position' => t[4],
            'summary' => t[8], 'birthday' => 'TBD', 'project' => t[7],
            'project_extra' => t[11], 'room_number' => t[10]}
            person.data = data.to_json

            imagePath = File.expand_path("../../../data/#{imageName}", __FILE__)
            if File.exists?(imagePath)
              file = File.open(imagePath)
              person.avatar = file
              file.close
            end
            person.save! 
            print "."           
          end
        end
      else
        puts "File not exist"
      end
      puts ""        
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
