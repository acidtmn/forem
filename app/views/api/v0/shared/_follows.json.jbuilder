json.name          user.name
json.path          "/#{user.path.delete_prefix('/')}"
json.username      user.try(:username) || user.name
json.profile_image Images::Avatar.call(user.profile_image_url, length: 60)
