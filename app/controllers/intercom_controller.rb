class IntercomController < ApplicationController
  def index
  	@userWelcome = User.current#Текущий пользователь
  	@usersAll = User.all#Все пользователи. Таблица Users_terc пока не используется
	
	@skillsAll = SkillsTerc.all#Все скилы
	@skillsCurrent = UskillsTerc.where(id_users: User.current.id)#Скилы текущего пользователя
  end
end
