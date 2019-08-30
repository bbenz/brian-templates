mongo tailwind --eval "db.dropUser('twtadmin')"
mongo tailwind --eval "db.createUser({user:'twtadmin',pwd:'BULt%b(+}d8]#g2d+M%Q`2E3*u',roles:[{role:'dbAdmin',db:'tailwind'}]})"
