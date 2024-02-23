function nf --wraps='neofetch | lolcat' --description 'alias nf=neofetch | lolcat'
  neofetch | lolcat $argv; 
end
