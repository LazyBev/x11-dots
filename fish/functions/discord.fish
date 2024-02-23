function discord --wraps='flatpak run com.discordapp.Discord' --description 'alias discord=flatpak run com.discordapp.Discord'
  flatpak run com.discordapp.Discord $argv; 
end
