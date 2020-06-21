[user]
  email = mmadumanasseh@gmail.com
  name = Mmadu Manasseh

[core]
  excludesfile = /home/manasseh/.gitignore

[includeIf "gitdir:/home/manasseh/Codes/github/"]
  path = /home/manasseh/.gitprofiles/mmadumanasseh@gmail.com

