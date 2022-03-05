
#
#
# no_solo_padel
#
#
Organising padel matches

#version
to modify version edit pubspec.yaml

# development to production
execute:
    dart run utilities\development.dart
    git push origin master


# production to development
execute:
    git pull origin master
    dart run utilities\production.dart



